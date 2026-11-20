import 'dart:convert';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:build/build.dart';
import 'package:glob/glob.dart';

/// A parameter of the unnamed constructor of a hand-written screen.
class ChildScreenParam {
  const ChildScreenParam(this.name, this.type,
      {required this.named, required this.required});

  final String name;

  /// The declared type as written, or `null` when it cannot be read from the
  /// syntax (`super.x`).
  final String? type;
  final bool named;
  final bool required;

  Map<String, Object?> toJson() =>
      {'name': name, 'type': type, 'named': named, 'required': required};

  static ChildScreenParam fromJson(Map<String, dynamic> json) =>
      ChildScreenParam(json['name'] as String, json['type'] as String?,
          named: json['named'] as bool, required: json['required'] as bool);
}

/// One `@EntityScreen` declaration: a hand-written widget class below an
/// entity's detail route. Read from the syntax tree of the declaring file, so
/// it does not depend on generated code.
class ChildScreen {
  const ChildScreen({
    required this.entity,
    required this.path,
    required this.title,
    required this.className,
    required this.libraryUri,
    required this.params,
  });

  /// Class name of the entity, e.g. `Site`.
  final String entity;
  final String path;
  final String title;
  final String className;

  /// Library generated code imports to reach [className].
  final String libraryUri;
  final List<ChildScreenParam> params;

  Map<String, Object?> toJson() => {
        'entity': entity,
        'path': path,
        'title': title,
        'className': className,
        'uri': libraryUri,
        'params': [for (final p in params) p.toJson()],
      };

  static ChildScreen fromJson(Map<String, dynamic> json) => ChildScreen(
        entity: json['entity'] as String,
        path: json['path'] as String,
        title: json['title'] as String,
        className: json['className'] as String,
        libraryUri: json['uri'] as String,
        params: [
          for (final p in json['params'] as List)
            ChildScreenParam.fromJson(p as Map<String, dynamic>),
        ],
      );
}

/// `study-session` -> `Study session`.
String defaultScreenTitle(String path) {
  final words = path.replaceAll(RegExp(r'[-_]+'), ' ').trim();
  return words.isEmpty ? path : words[0].toUpperCase() + words.substring(1);
}

/// Thrown by the scanner for a declaration it cannot read.
class ChildScreenException implements Exception {
  ChildScreenException(this.message);
  final String message;
  @override
  String toString() => message;
}

String _annotationName(Annotation a) {
  final name = a.name;
  return name is PrefixedIdentifier ? name.identifier.name : name.name;
}

/// The `@EntityScreen` declarations of [source] (a file at [uri]); accepts
/// `@EntityScreen(...)` and `@prefix.EntityScreen(...)`.
List<ChildScreen> scanChildScreens(String source, String uri) {
  final unit = parseString(content: source, throwIfDiagnostics: false).unit;
  final result = <ChildScreen>[];
  for (final declaration in unit.declarations) {
    if (declaration is! ClassDeclaration) continue;
    final className = declaration.name.lexeme;
    for (final a in declaration.metadata) {
      if (_annotationName(a) != 'EntityScreen' || a.constructorName != null) {
        continue;
      }
      final args = a.arguments?.arguments ?? const <Expression>[];
      final positional = args.where((e) => e is! NamedExpression).toList();
      if (positional.length != 1) {
        throw ChildScreenException(
            '@EntityScreen on $className ($uri) needs the entity class as its '
            'first argument.');
      }
      final entity = positional.single;
      final entityName = entity is PrefixedIdentifier
          ? entity.identifier.name
          : entity is SimpleIdentifier
              ? entity.name
              : throw ChildScreenException(
                  '@EntityScreen on $className ($uri): the entity must be a '
                  'class name.');
      String? named(String name) {
        for (final e in args.whereType<NamedExpression>()) {
          if (e.name.label.name != name) continue;
          final value = e.expression;
          if (value is StringLiteral && value.stringValue != null) {
            return value.stringValue;
          }
          throw ChildScreenException('@EntityScreen on $className ($uri): '
              '`$name` must be a string literal.');
        }
        return null;
      }

      final path = named('path');
      if (path == null) {
        throw ChildScreenException(
            '@EntityScreen on $className ($uri) needs a `path`.');
      }
      result.add(ChildScreen(
        entity: entityName,
        path: path,
        title: named('title') ?? defaultScreenTitle(path),
        className: className,
        libraryUri: uri,
        params: _constructorParams(declaration),
      ));
    }
  }
  return result;
}

List<ChildScreenParam> _constructorParams(ClassDeclaration declaration) {
  final constructor = declaration.members
      .whereType<ConstructorDeclaration>()
      .where((c) => c.name == null && c.factoryKeyword == null)
      .firstOrNull;
  if (constructor == null) return const [];
  final fieldTypes = <String, String?>{
    for (final f in declaration.members.whereType<FieldDeclaration>())
      for (final v in f.fields.variables) v.name.lexeme: f.fields.type?.toSource(),
  };
  final params = <ChildScreenParam>[];
  for (var p in constructor.parameters.parameters) {
    if (p is DefaultFormalParameter) p = p.parameter;
    final name = p.name?.lexeme;
    if (name == null) continue;
    final String? type;
    if (p is SimpleFormalParameter) {
      type = p.type?.toSource();
    } else if (p is FieldFormalParameter) {
      type = p.type?.toSource() ?? fieldTypes[name];
    } else {
      type = null;
    }
    params.add(ChildScreenParam(name, type,
        named: p.isNamed, required: p.isRequired));
  }
  return params;
}

/// Names of the classes annotated with `@View` in [source].
List<String> scanViewNames(String source) {
  final unit = parseString(content: source, throwIfDiagnostics: false).unit;
  return [
    for (final d in unit.declarations)
      if (d is ClassDeclaration && d.metadata.any((a) => _annotationName(a) == 'View'))
        d.name.lexeme,
  ];
}

const childScreensExtension = '.prefab_screens.json';

/// Writes `<file>.prefab_screens.json` for every file with `@EntityScreen`
/// declarations; other files get no output.
class ChildScreensBuilder implements Builder {
  @override
  Map<String, List<String>> get buildExtensions => const {
        '.dart': [childScreensExtension],
      };

  @override
  Future<void> build(BuildStep buildStep) async {
    final id = buildStep.inputId;
    if (id.path.endsWith('.prefab.dart') || id.path.endsWith('.g.dart')) {
      return;
    }
    final source = await buildStep.readAsString(id);
    if (!source.contains('EntityScreen')) return;
    final screens = scanChildScreens(source, id.uri.toString());
    if (screens.isEmpty) return;
    await buildStep.writeAsString(
      id.changeExtension(childScreensExtension),
      jsonEncode([for (final s in screens) s.toJson()]),
    );
  }
}

/// Reads the summaries of all `@EntityScreen` declarations of the package,
/// ordered by library and class name.
Future<List<ChildScreen>> readChildScreens(BuildStep buildStep) async {
  final result = <ChildScreen>[];
  final ids = await buildStep
      .findAssets(Glob('lib/**$childScreensExtension'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));
  for (final id in ids) {
    for (final entry in jsonDecode(await buildStep.readAsString(id)) as List) {
      result.add(ChildScreen.fromJson(entry as Map<String, dynamic>));
    }
  }
  return result;
}

/// The names of the `@View` classes in the other libraries of the package.
Future<Set<String>> readOtherViewNames(BuildStep buildStep) async {
  final names = <String>{};
  final ids = await buildStep.findAssets(Glob('lib/**.dart')).toList();
  for (final id in ids) {
    if (id == buildStep.inputId ||
        id.path.endsWith('.prefab.dart') ||
        id.path.endsWith('.g.dart')) {
      continue;
    }
    final source = await buildStep.readAsString(id);
    if (source.contains('View')) names.addAll(scanViewNames(source));
  }
  return names;
}
