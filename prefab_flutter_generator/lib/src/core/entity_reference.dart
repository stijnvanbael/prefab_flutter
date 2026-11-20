import 'package:analyzer/dart/ast/ast.dart';
import 'package:build/build.dart';
import 'package:glob/glob.dart';
import 'package:source_gen/source_gen.dart';

/// One import of the library that declares an `@EntityAction` or
/// `@EntityScreen`, as far as the syntax tree shows it.
class ImportScope {
  const ImportScope(this.uri,
      {this.prefix, this.show = const [], this.hide = const []});

  factory ImportScope.fromJson(Map<String, dynamic> json) => ImportScope(
        json['uri'] as String,
        prefix: json['prefix'] as String?,
        show: [for (final s in json['show'] as List) s as String],
        hide: [for (final s in json['hide'] as List) s as String],
      );

  /// Absolute URI of the imported library.
  final String uri;
  final String? prefix;
  final List<String> show;
  final List<String> hide;

  Map<String, Object?> toJson() =>
      {'uri': uri, 'prefix': prefix, 'show': show, 'hide': hide};

  bool exposes(String name) =>
      (show.isEmpty || show.contains(name)) && !hide.contains(name);
}

/// How a declaration names its entity: the class name, the import prefix it
/// was written with and the imports of the declaring library. Together they
/// say which library the entity comes from, without resolving the code (the
/// scan reads the unresolved syntax tree, so it cannot depend on generated
/// code).
class EntityReference {
  const EntityReference({
    this.declaredIn,
    this.prefix,
    this.imports = const [],
  });

  factory EntityReference.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const EntityReference();
    return EntityReference(
      declaredIn: json['declaredIn'] as String?,
      prefix: json['prefix'] as String?,
      imports: [
        for (final i in json['imports'] as List)
          ImportScope.fromJson(i as Map<String, dynamic>),
      ],
    );
  }

  /// Reads the imports of [unit], the library at [uri]. [prefix] is the import
  /// prefix of the entity identifier (`p.Site`), if it has one.
  factory EntityReference.of(CompilationUnit unit, String uri,
      {String? prefix}) {
    final base = Uri.parse(uri);
    final imports = <ImportScope>[];
    for (final d in unit.directives.whereType<ImportDirective>()) {
      final target = d.uri.stringValue;
      if (target == null) continue;
      imports.add(ImportScope(
        base.resolve(target).toString(),
        prefix: d.prefix?.name,
        show: [
          for (final c in d.combinators.whereType<ShowCombinator>())
            for (final n in c.shownNames) n.name,
        ],
        hide: [
          for (final c in d.combinators.whereType<HideCombinator>())
            for (final n in c.hiddenNames) n.name,
        ],
      ));
    }
    return EntityReference(declaredIn: uri, prefix: prefix, imports: imports);
  }

  /// The library the declaration is in; `null` for a summary written before
  /// this was recorded, which then matches by class name only.
  final String? declaredIn;
  final String? prefix;
  final List<ImportScope> imports;

  Map<String, Object?> toJson() => {
        'declaredIn': declaredIn,
        'prefix': prefix,
        'imports': [for (final i in imports) i.toJson()],
      };

  /// The imported libraries [name] can come from.
  Set<String> importedFrom(String name) => {
        for (final i in imports)
          if (i.prefix == prefix && i.exposes(name)) i.uri,
      };
}

/// Whether a declaration with [reference] targets the entity [name] of the
/// library [libraryUri].
///
/// The entity is the one of the declaring library itself or of an import that
/// exposes the name. When it is imported through another library (a barrel
/// that exports it), the name alone has to be unambiguous in the package, or
/// the build fails naming the libraries. [entityLibraries] is only called when
/// it is needed: it maps an entity class name to the libraries of the package
/// that declare it.
Future<bool> targetsEntity({
  required String name,
  required String libraryUri,
  required EntityReference reference,
  required Future<Map<String, Set<String>>> Function() entityLibraries,
  required String describe,
}) async {
  final declaredIn = reference.declaredIn;
  if (declaredIn == null) return true;
  if (reference.prefix == null && declaredIn == libraryUri) return true;
  final imported = reference.importedFrom(name);
  if (imported.contains(libraryUri)) return true;

  final candidates = (await entityLibraries())[name] ?? const <String>{};
  if (!candidates.contains(libraryUri)) return false;
  if (reference.prefix == null && candidates.contains(declaredIn)) {
    return false;
  }
  if (imported.any(candidates.contains)) return false;
  if (candidates.length == 1) return true;
  final libraries = candidates.toList()..sort();
  throw InvalidGenerationSourceError(
      '$describe names $name, which is an @Entity class in '
      '${libraries.join(' and ')}, and does not import either directly. '
      'Import the library of the entity you mean.');
}

/// The `@Entity` class names of every library of the package, with the
/// libraries that declare them.
Future<Map<String, Set<String>>> readEntityLibraries(
    BuildStep buildStep, List<String> Function(String source) scan) async {
  final result = <String, Set<String>>{};
  final ids = await buildStep.findAssets(Glob('lib/**.dart')).toList();
  for (final id in ids) {
    if (id.path.endsWith('.prefab.dart') || id.path.endsWith('.g.dart')) {
      continue;
    }
    final source = await buildStep.readAsString(id);
    if (!source.contains('Entity')) continue;
    for (final name in scan(source)) {
      result.putIfAbsent(name, () => {}).add(id.uri.toString());
    }
  }
  return result;
}
