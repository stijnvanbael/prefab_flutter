import 'package:prefab_flutter/prefab_flutter.dart';

/// A hand-written widget a field names in its annotation (PF-65): the
/// constructor tear-off or function behind `FormOptions.builder` or
/// `Field.displayBuilder`.
class CustomWidgetRef {
  const CustomWidgetRef({
    required this.invocation,
    this.libraryUri,
    this.parameters = const {},
  });

  /// What generated code calls: `ColorField`, `ColorField.named`, `buildIt`.
  final String invocation;

  /// The library that declares it, or `null` when it is the entity's own.
  final String? libraryUri;

  /// The named parameters it accepts.
  final Set<String> parameters;
}

/// Describes a single field on an entity class as understood by the generators.
class FieldManifest {
  /// Dart field name (e.g. `'firstName'`).
  final String name;

  /// Human-readable label (from [@Field.label] or derived from [name]).
  final String label;

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

  /// The hand-written form widget (`@Field.form.builder`), if any.
  final CustomWidgetRef? customForm;

  /// The hand-written display widget (`@Field.displayBuilder`), if any.
  final CustomWidgetRef? customDisplay;

  /// The places the field appears in (`@Field.on`), or `null` for every place.
  final Set<Place>? places;

  /// When `true` the field takes part in the list search ([@Field.searchable]).
  final bool searchable;

  /// When `true` the field is offered in the list sort menu ([@Field.sortable]).
  final bool sortable;

  /// The name the server knows the field by: the `@JsonKey(name:)` value, the
  /// class's `@JsonSerializable(fieldRename:)` applied to [name], or [name].
  /// Used as the `sort` value of list requests.
  final String jsonName;

  /// Whether the server owns the value (`@Field.readOnly`): never in a form
  /// or a request body.
  final bool readOnly;

  /// The forms the field is limited to (`FormOptions.on`), or `null` for both.
  final Set<FormMode>? formModes;

  const FieldManifest({
    required this.name,
    required this.label,
    required this.isParent,
    required this.dartType,
    this.validators = const [],
    this.fieldWidget = FieldWidget.auto,
    this.isEnum = false,
    this.isNullable = false,
    this.customForm,
    this.customDisplay,
    this.places,
    this.readOnly = false,
    this.formModes,
    this.searchable = false,
    this.sortable = false,
    String? jsonName,
  }) : jsonName = jsonName ?? name;

  /// Whether the field appears in [place].
  bool isOn(Place place) => places == null || places!.contains(place);

  /// Whether the field is allowed in the [mode] request (not read-only).
  bool isOnMode(FormMode mode) =>
      !readOnly && (formModes == null || formModes!.contains(mode));

  /// Whether the field is in the form of [mode]: in [Place.form], not
  /// read-only and not limited to the other mode.
  bool inForm(FormMode mode) =>
      !isParent && !isShownNowhere && isOn(Place.form) && isOnMode(mode);

  /// Whether the field appears in no place at all (`@Field(on: {})`).
  bool get isShownNowhere => places != null && places!.isEmpty;

  /// Whether the form must reject an empty value: non-nullable fields are
  /// required by default, nullable fields only with [Validator.required].
  bool get isRequired =>
      !isNullable || validators.any((v) => v is RequiredValidator);
}
