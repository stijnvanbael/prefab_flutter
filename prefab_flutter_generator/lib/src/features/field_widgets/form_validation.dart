import 'package:prefab_flutter/prefab_flutter.dart';
import 'package:source_gen/source_gen.dart';

import '../../core/code.dart';
import '../../manifest/field_manifest.dart';
import '../validators/validator_emitters.dart';
import 'form_field_emitter.dart';

// The validator callback of a form field; the check of each validator comes
// from the `validators` feature.

/// Quoted message of the `required` check (custom or `'Required'`).
String requiredMessage(FieldManifest field) => dartStringLiteral(
      field.validators
              .whereType<RequiredValidator>()
              .map((v) => v.message)
              .firstOrNull ??
          'Required',
    );

/// Rejects text-only validators on widgets that are not text inputs.
void checkValidatorsFor(FieldManifest field, FormFieldEmitter emitter) {
  if (emitter.isTextInput) return;
  for (final v in field.validators) {
    if (v is! RequiredValidator) {
      throw InvalidGenerationSourceError(
        '${v.runtimeType} cannot be used on "${field.name}" because it '
        'renders as a ${emitter.widget.name} field. Only Validator.required '
        'is supported there.',
      );
    }
  }
}

/// The `validator:` argument of a text form field, or an empty [Code] when the
/// field needs none.
Code validatorCallback(FieldManifest field, FormFieldEmitter emitter) {
  checkValidatorsFor(field, emitter);
  // `required` always runs first (or an empty-is-valid guard for optional
  // fields), so `value` is promoted to a non-null String for the others.
  final others =
      field.validators.where((v) => v is! RequiredValidator).toList();
  final numeric = emitter.parsesNumbers && FormFieldEmitter.isNumber(field);
  if (!field.isRequired && others.isEmpty && !numeric) return const Code('');
  final buffer = StringBuffer();
  buffer.writeln('              validator: (value) {');
  if (field.isRequired) {
    buffer.writeln(
      "                if (value == null || value.isEmpty) return ${requiredMessage(field)};",
    );
  } else {
    // Optional field: an empty value is valid, skip the other checks.
    buffer.writeln(
      "                if (value == null || value.isEmpty) return null;",
    );
  }
  if (numeric) {
    // Parseability check so the save handler can parse safely.
    final isInt = field.dartType == 'int';
    buffer.writeln(
      "                if (${field.dartType}.tryParse(value) == null) return '${isInt ? 'Must be a whole number' : 'Must be a number'}';",
    );
  }
  for (final validator in others) {
    buffer.write(
      validatorEmitters
          .resolve(validator)
          .check(field, validator, 'value')
          .text,
    );
  }
  buffer.writeln('                return null;');
  buffer.writeln('              },');
  return Code(buffer.toString());
}
