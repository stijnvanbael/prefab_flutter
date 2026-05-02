/// Validation rules that the form-screen generator wires into form fields.
enum Validator {
  /// Field must not be empty.
  required,

  /// Field value must be a valid e-mail address.
  email,

  /// Field value must be a number greater than zero.
  positiveNumber,

  /// Field value must be a parseable [Uri].
  url,
}
