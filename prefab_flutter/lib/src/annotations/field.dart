import '../enums/field_widget.dart';
import '../enums/validator.dart';

/// Form-only settings of a [Field], passed as [Field.form].
///
/// Example:
/// ```dart
/// @Field(form: FormOptions(validators: [Validator.required]))
/// final String name;
/// ```
class FormOptions {
  /// Widget hint for the form-screen generator.
  final FieldWidget widget;

  /// Validation rules applied to this field in the form screen.
  final List<Validator> validators;

  const FormOptions({
    this.widget = FieldWidget.auto,
    this.validators = const [],
  });
}

/// Marks a field on a [@View] entity for inclusion in the generated list,
/// detail and form screens.
///
/// Display and listing concerns (label, visibility, and later searching,
/// sorting and views) live directly on [Field]; form-only settings live in
/// [form].
///
/// Example:
/// ```dart
/// @Field(label: 'Product name', form: FormOptions(validators: [Validator.required]))
/// final String name;
/// ```
class Field {
  /// Human-readable label shown next to the field. Defaults to the field name
  /// converted to title case when omitted.
  final String? label;

  /// When `true` the field is excluded from both the form and detail screens.
  final bool hidden;

  /// Form-only settings (widget and validators).
  final FormOptions form;

  /// Names of the views the field appears in (`'list'`, `'detail'`).
  /// `null` (the default) means the field appears in all views.
  final Set<String>? views;

  const Field({
    this.label,
    this.hidden = false,
    this.views,
    this.form = const FormOptions(),
  });
}

/// Deprecated predecessor of [Field].
///
/// Equivalent to `@Field(label: ..., hidden: ..., form: FormOptions(widget:
/// ..., validators: ...))`. Kept for one release.
@Deprecated('Use @Field (with form: FormOptions(...)) instead.')
class FormField {
  final String? label;
  final FieldWidget widget;
  final List<Validator> validators;
  final bool hidden;

  const FormField({
    this.label,
    this.widget = FieldWidget.auto,
    this.validators = const [],
    this.hidden = false,
  });
}
