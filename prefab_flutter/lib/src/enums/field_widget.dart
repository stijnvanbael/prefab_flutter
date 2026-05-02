/// Hint to the form-screen generator about which Flutter widget to render
/// for a particular field.
enum FieldWidget {
  /// Infer the widget from the Dart type (default).
  auto,

  /// Multi-line [TextFormField].
  multilineText,

  /// Obscured (password) [TextFormField].
  password,

  /// Date picker backed by [showDatePicker].
  datePicker,

  /// [DropdownButtonFormField] for enum fields.
  dropdown,

  /// [Switch] widget regardless of the field type.
  toggle,
}
