import 'package:prefab_flutter/prefab_flutter.dart';

/// Describes a single field on an entity class as understood by the generators.
class FieldManifest {
  /// Dart field name (e.g. `'firstName'`).
  final String name;

  /// Human-readable label (from [@FormField.label] or derived from [name]).
  final String label;

  /// When `true` the field is excluded from form and detail screens.
  final bool hidden;

  /// When `true` the field references a parent entity (annotated with [@Parent]).
  final bool isParent;

  /// Dart type display string (e.g. `'String'`, `'int'`, `'bool'`).
  final String dartType;

  /// Validation rules applied to this field in the form screen.
  final List<Validator> validators;

  /// Widget hint from the [@FormField.widget] annotation.
  final FieldWidget fieldWidget;

  /// When `true` the Dart type of the field is an enum.
  final bool isEnum;

  /// When `true` a search bar is included in the generated list screen that
  /// filters items by this field's value.
  final bool searchable;

  /// When `true` a sort control is included in the generated list screen that
  /// allows sorting items by this field.
  final bool sortable;

  const FieldManifest({
    required this.name,
    required this.label,
    required this.hidden,
    required this.isParent,
    required this.dartType,
    this.validators = const [],
    this.fieldWidget = FieldWidget.auto,
    this.isEnum = false,
    this.searchable = false,
    this.sortable = false,
  });
}
