import '../enums/field_widget.dart';
import '../enums/validator.dart';

/// Marks a field on a [@View] entity for inclusion in generated form and detail
/// screens.
///
/// Example:
/// ```dart
/// @FormField(label: 'Product name', validators: [Validator.required])
/// final String name;
/// ```
class FormField {
  /// Human-readable label shown next to the field. Defaults to the field name
  /// converted to title case when omitted.
  final String? label;

  /// Widget hint for the form-screen generator.
  final FieldWidget widget;

  /// Validation rules applied to this field in the form screen.
  final List<Validator> validators;

  /// When `true` the field is excluded from both the form and detail screens.
  final bool hidden;

  const FormField({
    this.label,
    this.widget = FieldWidget.auto,
    this.validators = const [],
    this.hidden = false,
  });
}
