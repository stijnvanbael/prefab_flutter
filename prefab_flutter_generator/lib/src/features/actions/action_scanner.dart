import 'dart:convert';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:build/build.dart';
import 'package:glob/glob.dart';
import 'package:source_gen/source_gen.dart';

/// The places an action can appear in: the values of `Place` of
/// `prefab_flutter` except `form`.
const actionPlaces = ['detail', 'list', 'item'];

/// A hand-written function annotated with `@EntityAction`, as summarised by
/// the `prefab_actions` builder.
class ActionDeclaration {
  const ActionDeclaration({
    required this.name,
    required this.uri,
    required this.entity,
    required this.label,
    required this.icon,
    required this.places,
    required this.order,
  });

  factory ActionDeclaration.fromJson(Map<String, dynamic> json) =>
      ActionDeclaration(
        name: json['name'] as String,
        uri: json['uri'] as String,
        entity: json['entity'] as String,
        label: json['label'] as String,
        icon: json['icon'] as String?,
        places: [for (final p in json['places'] as List) p as String],
        order: json['order'] as int,
      );

  /// Name of the function.
  final String name;

  /// Library generated code imports to reach it.
  final String uri;
  final String entity;
  final String label;
  final String? icon;
  final List<String> places;
  final int order;

  Map<String, dynamic> toJson() => {
        'name': name,
        'uri': uri,
        'entity': entity,
        'label': label,
        'icon': icon,
        'places': places,
        'order': order,
      };

  /// The same declaration with the import dropped, for an action declared in
  /// the library that is being generated.
  ActionDeclaration inSameLibrary() => ActionDeclaration(
      name: name,
      uri: '',
      entity: entity,
      label: label,
      icon: icon,
      places: places,
      order: order);
}

/// Thrown for an `@EntityAction` that cannot be used; the message names the
/// function and says what is wrong.
class ActionException implements Exception {
  const ActionException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// The `@EntityAction` declarations of [source], read from the unresolved
/// syntax tree (so the scan does not depend on generated code). [uri] is the
/// library the functions are imported from. Throws an [ActionException] for a
/// declaration that is not usable.
List<ActionDeclaration> scanActions(String source, String uri) {
  final unit = parseString(content: source, throwIfDiagnostics: false).unit;
  final result = <ActionDeclaration>[];
  for (final declaration in unit.declarations) {
    for (final annotation in declaration.metadata.where(_isEntityAction)) {
      result.add(_read(declaration, annotation, uri));
    }
  }
  return result;
}

bool _isEntityAction(Annotation a) {
  final name = a.name;
  final id = name is PrefixedIdentifier ? name.identifier.name : name.name;
  return id == 'EntityAction' && a.constructorName == null;
}

ActionDeclaration _read(
    Declaration declaration, Annotation annotation, String uri) {
  if (declaration is! FunctionDeclaration ||
      declaration.isGetter ||
      declaration.isSetter) {
    throw ActionException('@EntityAction can only be applied to a top-level '
        'function ($uri).');
  }
  final name = declaration.name.lexeme;
  String problem(String what) => '@EntityAction on $name ($uri): $what';
  if (name.startsWith('_')) {
    throw ActionException(
        problem('the function is private; generated code cannot call it'));
  }

  final arguments = annotation.arguments?.arguments ?? <Expression>[];
  Expression? entityArg;
  final named = <String, Expression>{};
  for (final a in arguments) {
    if (a is NamedExpression) {
      named[a.name.label.name] = a.expression;
    } else {
      entityArg ??= a;
    }
  }

  final String entity;
  if (entityArg is SimpleIdentifier) {
    entity = entityArg.name;
  } else if (entityArg is PrefixedIdentifier) {
    entity = entityArg.identifier.name;
  } else {
    throw ActionException(
        problem('the first argument must be the entity class, e.g. Product'));
  }

  final label = _string(named['label']);
  if (label == null || label.isEmpty) {
    throw ActionException(problem('label must be a non-empty string literal'));
  }

  String? icon;
  if (named.containsKey('icon')) {
    final expression = named['icon']!;
    if (expression is! NullLiteral) {
      icon = _string(expression);
      if (icon == null || !RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(icon)) {
        throw ActionException(problem(
            "icon must be the name of a member of Icons as a string, e.g. 'copy'"));
      }
    }
  }

  var places = ['detail'];
  if (named.containsKey('on')) {
    places = _places(named['on']!) ??
        (throw ActionException(problem(
            'on must be a set literal of Place values, e.g. '
            '{Place.detail, Place.item}')));
    if (places.contains('form')) {
      throw ActionException(problem(
          'Place.form is for fields; an action can be on Place.detail, '
          'Place.list or Place.item'));
    }
    if (places.isEmpty) {
      throw ActionException(problem('on must name at least one place'));
    }
  }
  final withEntity = places.where((p) => p != 'list').isNotEmpty;
  if (withEntity && places.contains('list')) {
    throw ActionException(problem(
        'Place.list takes no entity, Place.detail and '
        'Place.item do; declare two functions'));
  }

  var order = 0;
  if (named.containsKey('order')) {
    final expression = named['order']!;
    final value = _int(expression);
    if (value == null) {
      throw ActionException(problem('order must be an integer literal'));
    }
    order = value;
  }

  _checkSignature(declaration, entity, withEntity, problem);

  return ActionDeclaration(
    name: name,
    uri: uri,
    entity: entity,
    label: label,
    icon: icon,
    places: places,
    order: order,
  );
}

void _checkSignature(FunctionDeclaration declaration, String entity,
    bool withEntity, String Function(String) problem) {
  final expected = [
    'BuildContext',
    'WidgetRef',
    if (withEntity) entity,
  ];
  final parameters = declaration.functionExpression.parameters?.parameters;
  final found = [
    for (final p in parameters ?? const <FormalParameter>[]) _parameterType(p),
  ];
  final positional = parameters != null &&
      parameters.every((p) => p.isRequiredPositional);
  if (!positional ||
      found.length != expected.length ||
      !_sameList(found, expected)) {
    throw ActionException(problem(
        'expected the parameters (${expected.join(', ')}) but found '
        '(${found.map((t) => t ?? 'untyped').join(', ')})'
        '${positional ? '' : '; all parameters must be required positional'}'));
  }
}

String? _parameterType(FormalParameter p) {
  final normal = p is DefaultFormalParameter ? p.parameter : p;
  final type = normal is SimpleFormalParameter
      ? normal.type
      : normal is FieldFormalParameter
          ? normal.type
          : null;
  if (type is NamedType) {
    final n = type.name.lexeme;
    return type.question == null ? n : '$n?';
  }
  return null;
}

bool _sameList(List<String?> a, List<String> b) {
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

String? _string(Expression? e) =>
    e is SimpleStringLiteral ? e.value : null;

int? _int(Expression e) {
  if (e is IntegerLiteral) return e.value;
  if (e is PrefixExpression &&
      e.operator.lexeme == '-' &&
      e.operand is IntegerLiteral) {
    final v = (e.operand as IntegerLiteral).value;
    return v == null ? null : -v;
  }
  return null;
}

List<String>? _places(Expression e) {
  if (e is! SetOrMapLiteral) return null;
  final places = <String>[];
  for (final element in e.elements) {
    String? place;
    if (element is PrefixedIdentifier &&
        element.prefix.name == 'Place') {
      place = element.identifier.name;
    } else if (element is PropertyAccess &&
        element.target is PrefixedIdentifier) {
      // prefix.Place.detail
      place = element.propertyName.name;
    }
    if (place == null || !(actionPlaces.contains(place) || place == 'form')) {
      return null;
    }
    if (!places.contains(place)) places.add(place);
  }
  return places;
}

const actionsExtension = '.prefab_actions.json';

/// Writes `<file>.prefab_actions.json` for every file with `@EntityAction`
/// functions; files without any get no output, so editing them changes no
/// summary.
class ActionsBuilder implements Builder {
  @override
  Map<String, List<String>> get buildExtensions => const {
        '.dart': [actionsExtension],
      };

  @override
  Future<void> build(BuildStep buildStep) async {
    final id = buildStep.inputId;
    if (id.path.endsWith('.prefab.dart') || id.path.endsWith('.g.dart')) {
      return;
    }
    final source = await buildStep.readAsString(id);
    if (!source.contains('EntityAction')) return;
    final List<ActionDeclaration> actions;
    try {
      actions = scanActions(source, id.uri.toString());
    } on ActionException catch (e) {
      throw InvalidGenerationSourceError(e.message);
    }
    if (actions.isEmpty) return;
    await buildStep.writeAsString(
      id.changeExtension(actionsExtension),
      jsonEncode([for (final a in actions) a.toJson()]),
    );
  }
}

/// Reads the summaries of all `@EntityAction` functions of the package, in
/// file path order, then declaration order.
Future<List<ActionDeclaration>> readActions(BuildStep buildStep) async {
  final result = <ActionDeclaration>[];
  final ids = await buildStep
      .findAssets(Glob('lib/**$actionsExtension'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));
  for (final id in ids) {
    final json = jsonDecode(await buildStep.readAsString(id)) as List;
    for (final entry in json) {
      result.add(ActionDeclaration.fromJson(entry as Map<String, dynamic>));
    }
  }
  return result;
}
