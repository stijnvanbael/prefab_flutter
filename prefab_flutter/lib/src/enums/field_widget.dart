/// Hint to the form-screen generator about which Flutter widget to render
/// for a particular field.
enum FieldWidget {
  /// Infer the widget from the Dart type (default).
  auto,

  /// Multi-line [TextFormField].
  multilineText,

  /// Obscured (password) [TextFormField].
  password,

  /// Numeric [TextFormField] with a numeric keyboard and an input formatter.
  /// Inferred for `int`, `double` and `num` fields.
  numberInput,

  /// Date picker backed by [showDatePicker].
  datePicker,

  /// Time picker backed by [showTimePicker]. Supports `Duration` (time since
  /// midnight) and `String` in `HH:mm` format.
  timePicker,

  /// Date picker followed by a time picker, for `DateTime` fields.
  dateTimePicker,

  /// [DropdownButtonFormField] for enum fields.
  dropdown,

  /// [Switch] widget regardless of the field type.
  toggle,
}
