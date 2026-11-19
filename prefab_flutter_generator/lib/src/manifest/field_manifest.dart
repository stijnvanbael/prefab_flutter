import 'package:prefab_flutter/prefab_flutter.dart';

/// Describes a single field on an entity class as understood by the generators.
class FieldManifest {
  /// Dart field name (e.g. `'firstName'`).
  final String name;

  /// Human-readable label (from [@Field.label] or derived from [name]).
  final String label;

  /// When `true` the field is excluded from form and detail screens.
  final bool hidden;

  /// When `true` the field references a parent entity (annotated with [@Parent]).
  final bool isParent;

  /// Dart type display string (e.g. `'String'`, `'int'`, `'bool'`).
  final String dartType;

  /// Validation rules applied to this field in the form screen.
  final List<Validator> validators;

  /// Widget hint from the [@Field.form] annotation.
  final FieldWidget fieldWidget;

  /// When `true` the Dart type of the field is an enum.
  final bool isEnum;

  /// When `true` the Dart type of the field is nullable (e.g. `String?`).
  final bool isNullable;

  const FieldManifest({
    required this.name,
    required this.label,
    required this.hidden,
    required this.isParent,
    required this.dartType,
    this.validators = const [],
    this.fieldWidget = FieldWidget.auto,
    this.isEnum = false,
    this.isNullable = false,
  });

  /// Whether the form must reject an empty value: non-nullable fields are
  /// required by default, nullable fields only with [Validator.required].
  bool get isRequired =>
      !isNullable || validators.any((v) => v is RequiredValidator);
}
