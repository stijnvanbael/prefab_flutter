import 'package:prefab_flutter/prefab_flutter.dart';

import '../../core/code.dart';
import '../../core/field_registries.dart';
import '../../manifest/field_manifest.dart';

/// Indentation of a check inside the generated `validator:` callback.
const _indent = '                ';

/// Escapes [value] as a single-quoted Dart string literal.
String dartStringLiteral(String value) {
  final escaped = value
      .replaceAll(r'\', r'\\')
      .replaceAll("'", r"\'")
      .replaceAll(r'$', r'\$')
      .replaceAll('\n', r'\n')
      .replaceAll('\r', r'\r');
  return "'$escaped'";
}

/// A check that returns the validator's message (or [fallback]) when it fails.
String _message(Validator validator, String fallback) =>
    dartStringLiteral(validator.message ?? fallback);

Code _line(String text) => Code('$_indent$text\n');

Code _numberCheck(String failWhen, String message) => Code(
      '$_indent{\n'
      '$_indent  final n = double.tryParse(value);\n'
      '$_indent  if (n == null || n $failWhen) return $message;\n'
      '$_indent}\n',
    );

/// `Validator.required`: handled by the form template (it runs first and
/// promotes `value`), so it adds no further check.
class RequiredValidatorEmitter extends ValidatorEmitter<RequiredValidator> {
  const RequiredValidatorEmitter();

  @override
  Code check(FieldManifest field, RequiredValidator validator, String value) =>
      const Code('');
}

class EmailValidatorEmitter extends ValidatorEmitter<EmailValidator> {
  const EmailValidatorEmitter();

  @override
  Code check(FieldManifest field, EmailValidator validator, String value) =>
      _line(
        "if (!RegExp(r'^[^@\\s]+@[^@\\s]+\\.[^@\\s]+\$').hasMatch($value)) "
        "return ${_message(validator, 'Invalid email address')};",
      );
}

class UrlValidatorEmitter extends ValidatorEmitter<UrlValidator> {
  const UrlValidatorEmitter();

  @override
  Code check(FieldManifest field, UrlValidator validator, String value) => Code(
        '$_indent{\n'
        '$_indent  final uri = Uri.tryParse($value);\n'
        '$_indent  if (uri == null || !uri.isAbsolute) '
        'return ${_message(validator, 'Invalid URL')};\n'
        '$_indent}\n',
      );
}

class PositiveValidatorEmitter extends ValidatorEmitter<PositiveValidator> {
  const PositiveValidatorEmitter();

  @override
  Code check(FieldManifest field, PositiveValidator validator, String value) =>
      _numberCheck('<= 0', _message(validator, 'Must be a positive number'));
}

class NonNegativeValidatorEmitter
    extends ValidatorEmitter<NonNegativeValidator> {
  const NonNegativeValidatorEmitter();

  @override
  Code check(
          FieldManifest field, NonNegativeValidator validator, String value) =>
      _numberCheck('< 0', _message(validator, 'Must not be negative'));
}

class MinValidatorEmitter extends ValidatorEmitter<MinValidator> {
  const MinValidatorEmitter();

  @override
  Code check(FieldManifest field, MinValidator validator, String value) =>
      _numberCheck('< ${validator.value}',
          _message(validator, 'Must be at least ${validator.value}'));
}

class MaxValidatorEmitter extends ValidatorEmitter<MaxValidator> {
  const MaxValidatorEmitter();

  @override
  Code check(FieldManifest field, MaxValidator validator, String value) =>
      _numberCheck('> ${validator.value}',
          _message(validator, 'Must be at most ${validator.value}'));
}

class MinLengthValidatorEmitter extends ValidatorEmitter<MinLengthValidator> {
  const MinLengthValidatorEmitter();

  @override
  Code check(FieldManifest field, MinLengthValidator validator, String value) =>
      _line(
        'if ($value.length < ${validator.length}) return '
        "${_message(validator, 'Must be at least ${validator.length} characters')};",
      );
}

class MaxLengthValidatorEmitter extends ValidatorEmitter<MaxLengthValidator> {
  const MaxLengthValidatorEmitter();

  @override
  Code check(FieldManifest field, MaxLengthValidator validator, String value) =>
      _line(
        'if ($value.length > ${validator.length}) return '
        "${_message(validator, 'Must be at most ${validator.length} characters')};",
      );
}

class PatternValidatorEmitter extends ValidatorEmitter<PatternValidator> {
  const PatternValidatorEmitter();

  @override
  Code check(FieldManifest field, PatternValidator validator, String value) =>
      _line(
        'if (!RegExp(${dartStringLiteral(validator.regex)}).hasMatch($value)) '
        "return ${_message(validator, 'Invalid format')};",
      );
}

/// The checks every [Validator] adds to a field's `validator:` callback.
final validatorEmitters = ValidatorEmitters({
  RequiredValidator: const RequiredValidatorEmitter(),
  EmailValidator: const EmailValidatorEmitter(),
  UrlValidator: const UrlValidatorEmitter(),
  PositiveValidator: const PositiveValidatorEmitter(),
  NonNegativeValidator: const NonNegativeValidatorEmitter(),
  MinValidator: const MinValidatorEmitter(),
  MaxValidator: const MaxValidatorEmitter(),
  MinLengthValidator: const MinLengthValidatorEmitter(),
  MaxLengthValidator: const MaxLengthValidatorEmitter(),
  PatternValidator: const PatternValidatorEmitter(),
});
