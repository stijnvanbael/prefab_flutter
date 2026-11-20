import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:prefab_flutter/prefab_flutter.dart';
import 'package:source_gen/source_gen.dart';

import '../../manifest/entity_manifest.dart';
import '../../manifest/field_manifest.dart';

final _updateChecker = TypeChecker.typeNamed(Update, inPackage: 'prefab_flutter');

/// Method names of the generated classes that an operation must not shadow.
const _reservedNames = {
  'create', 'update', 'updateEntity', 'delete', 'list', 'getById', 'build',
  'state', 'ref', 'future', 'listen', 'dispose', 'toString', 'hashCode',
  'runtimeType', 'noSuchMethod',
};

/// One named operation of an entity: `@Update(path: ...)` (PF-54).
class OperationManifest {
  const OperationManifest({
    required this.path,
    required this.label,
    required this.icon,
    required this.places,
    required this.confirm,
    required this.order,
    this.parameters,
  });

  /// The URL segment after the id (`mark-paid`).
  final String path;

  /// Text of the button.
  final String label;

  /// Name of a member of `Icons`, or `null` for the default.
  final String? icon;

  /// `'detail'` and/or `'item'`.
  final Set<String> places;

  /// The question of the confirmation dialog, or `null` to run at once.
  final String? confirm;

  final int order;

  /// The parameters of the operation, or `null` for an operation without.
  final OperationParameters? parameters;

  /// The Dart name of the API client and notifier methods (`markPaid`).
  String get methodName {
    final words = path.split(RegExp('[-_]+')).where((w) => w.isNotEmpty);
    return [
      for (final (i, w) in words.indexed)
        i == 0 ? w : w[0].toUpperCase() + w.substring(1),
    ].join();
  }

  /// `MarkPaid`, for the name of the screen.
  String get pascalName =>
      methodName[0].toUpperCase() + methodName.substring(1);

  bool get hasParameters => parameters != null;

  /// The named operations of [entity], in declaration order. Throws an
  /// [InvalidGenerationSourceError] for one that cannot be generated.
  static List<OperationManifest> readAll(ClassElement entity) {
    final result = <OperationManifest>[];
    for (final annotation in _updateChecker.annotationsOf(entity)) {
      final path = annotation.getField('path');
      if (path == null || path.isNull) {
        final extras = [
          for (final n in const ['label', 'icon', 'confirm', 'parameters'])
            if (!(annotation.getField(n)?.isNull ?? true)) n,
        ];
        if (extras.isNotEmpty) {
          throw InvalidGenerationSourceError(
            '@Update on "${entity.name}" sets ${extras.join(', ')} without a '
            'path. Add path: to declare a named operation, or remove them to '
            'mark the entity as editable.',
            element: entity,
          );
        }
        continue;
      }
      result.add(_read(entity, annotation, path.toStringValue()!));
    }
    final seen = <String>{};
    for (final o in result) {
      if (!seen.add(o.methodName)) {
        throw InvalidGenerationSourceError(
          'Entity "${entity.name}" declares the operation "${o.path}" twice '
          '(or two paths that give the method name "${o.methodName}").',
          element: entity,
        );
      }
    }
    return result;
  }

  static OperationManifest _read(
      ClassElement entity, DartObject annotation, String path) {
    String problem(String what) =>
        '@Update(path: \'$path\') on "${entity.name}": $what';
    if (!RegExp(r'^[a-z][a-zA-Z0-9]*([-_][a-zA-Z0-9]+)*$').hasMatch(path)) {
      throw InvalidGenerationSourceError(
        problem('the path must be one URL segment of letters and digits, '
            'optionally separated by - or _ (for example "mark-paid").'),
        element: entity,
      );
    }
    final reserved = path == 'edit' || path == 'create';
    final name = OperationManifest(
      path: path,
      label: '',
      icon: null,
      places: const {},
      confirm: null,
      order: 0,
    ).methodName;
    if (reserved || _reservedNames.contains(name)) {
      throw InvalidGenerationSourceError(
        problem('"$path" is taken by the generated code. Pick another path.'),
        element: entity,
      );
    }

    final places = <String>{};
    for (final DartObject o in annotation.getField('on')!.toSetValue() ?? <DartObject>{}) {
      final place = o.variable?.name;
      if (place == null || (place != Place.detail.name && place != Place.item.name)) {
        throw InvalidGenerationSourceError(
          problem('on: can only contain Place.detail and Place.item.'),
          element: entity,
        );
      }
      places.add(place);
    }

    final parametersType = annotation.getField('parameters')?.toTypeValue();
    OperationParameters? parameters;
    if (parametersType != null) {
      final element = parametersType.element;
      if (element is! ClassElement) {
        throw InvalidGenerationSourceError(
          problem('parameters: must be a class.'),
          element: entity,
        );
      }
      parameters = OperationParameters.read(element, entity, path);
    }

    final label = annotation.getField('label')?.toStringValue() ??
        _labelFromPath(path);
    return OperationManifest(
      path: path,
      label: label,
      icon: annotation.getField('icon')?.toStringValue(),
      places: places,
      confirm: annotation.getField('confirm')?.toStringValue(),
      order: annotation.getField('order')?.toIntValue() ?? 0,
      parameters: parameters,
    );
  }

  static String _labelFromPath(String path) {
    final words = path
        .replaceAllMapped(RegExp('(?<=[a-z0-9])([A-Z])'), (m) => ' ${m[1]}')
        .split(RegExp('[-_ ]+'))
        .map((w) => w.toLowerCase())
        .toList();
    final text = words.join(' ');
    return text[0].toUpperCase() + text.substring(1);
  }
}

/// The class that holds the parameters of an operation: its form fields and
/// the constructor the form calls.
class OperationParameters {
  const OperationParameters({
    required this.className,
    required this.libraryUri,
    required this.fields,
    required this.constructor,
  });

  final String className;

  /// The library to import, or `null` when it is the entity's own.
  final String? libraryUri;

  final List<FieldManifest> fields;
  final List<ConstructorParam> constructor;

  static OperationParameters read(
      ClassElement element, ClassElement entity, String path) {
    String problem(String what) =>
        '@Update(path: \'$path\') on "${entity.name}": ${element.name} $what';
    final fields = [
      for (final f in EntityManifest.readParameterFields(element))
        if (f.inForm(FormMode.create)) f,
    ];
    if (fields.isEmpty) {
      throw InvalidGenerationSourceError(
        problem('has no @Field to show in the form.'),
        element: entity,
      );
    }
    final constructor = EntityManifest.readConstructorParams(element);
    if (constructor == null) {
      throw InvalidGenerationSourceError(
        problem('needs an unnamed constructor so the form can create it.'),
        element: entity,
      );
    }
    if (element.getMethod('toJson') == null) {
      throw InvalidGenerationSourceError(
        problem('needs a toJson() method (the request body).'),
        element: entity,
      );
    }
    final byName = {for (final f in fields) f.name};
    for (final p in constructor) {
      if (!byName.contains(p.name) && p.isRequired && !p.isNullable) {
        throw InvalidGenerationSourceError(
          problem('has a required constructor parameter "${p.name}" that is '
              'not a @Field. Make it a @Field, nullable or give it a '
              'default value.'),
          element: entity,
        );
      }
    }
    final uri = element.library.uri.toString();
    return OperationParameters(
      className: element.name!,
      libraryUri: uri == entity.library.uri.toString() ? null : uri,
      fields: fields,
      constructor: constructor,
    );
  }

  /// The arguments of the constructor call, from the form state.
  List<String> arguments(String Function(FieldManifest field) value) {
    final byName = {for (final f in fields) f.name: f};
    return [
      for (final p in constructor)
        if (byName[p.name] case final f?)
          p.isNamed ? '${p.name}: ${value(f)}' : value(f)
        else if (!p.isNamed)
          'null',
    ];
  }
}
