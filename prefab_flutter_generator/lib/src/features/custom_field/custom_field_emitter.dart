import 'package:prefab_flutter/prefab_flutter.dart';
import 'package:source_gen/source_gen.dart';

import '../../core/code.dart';
import '../../manifest/field_manifest.dart';
import '../field_widgets/form_field_emitter.dart';
import '../validators/validator_emitters.dart' show dartStringLiteral;
import '../field_widgets/form_validation.dart';

/// A hand-written form widget (`@Field(form: FormOptions(custom: ...))`).
///
/// The form keeps the value in `_<name>Value` and hands the widget the
/// plain-Flutter contract of `PrefabFieldBuilder`: `initialValue`,
/// `onChanged`, `label` and, if the field is required and the widget takes
/// one, a `validator`. It claims every field that names a custom widget, ahead
/// of the `FieldWidget` emitters.
class CustomFormFieldEmitter extends FormFieldEmitter {
  const CustomFormFieldEmitter();

  /// Never used for lookup: [claims] selects this emitter.
  @override
  FieldWidget get widget => FieldWidget.auto;

  @override
  bool claims(FieldManifest field) => field.customForm != null;

  @override
  bool accepts(FieldManifest field) => false;

  @override
  bool get usesController => false;

  @override
  bool get isTextInput => false;

  @override
  void check(FieldManifest field) {
    final custom = field.customForm!;
    for (final v in field.validators) {
      if (v is! RequiredValidator) {
        throw InvalidGenerationSourceError(
          '${v.runtimeType} cannot be used on "${field.name}" because it '
          'uses the custom widget ${custom.invocation}. Only '
          'Validator.required is supported there; check other rules inside '
          'the widget.',
        );
      }
    }
    if (field.isRequired && !custom.parameters.contains('validator')) {
      throw InvalidGenerationSourceError(
        'Field "${field.name}" is required but its custom widget '
        '${custom.invocation} takes no "validator" parameter, so the form '
        'cannot reject an empty value. Add a '
        '`String? Function(T? value)? validator` parameter.',
      );
    }
  }

  @override
  Code? stateDeclaration(FieldManifest field) => Code(
        '  ${field.dartType}? _${field.name}Value;\n',
      );

  @override
  Code initialValue(FieldManifest field, String entity) =>
      Code('    _${field.name}Value = $entity.${field.name};\n');

  @override
  String valueExpression(FieldManifest field) =>
      field.isNullable ? '_${field.name}Value' : '_${field.name}Value!';

  @override
  Code formField(FieldManifest field) {
    final custom = field.customForm!;
    final n = field.name;
    final buffer = StringBuffer()
      ..writeln('            ${custom.invocation}(')
      ..writeln('              initialValue: _${n}Value,')
      ..writeln('              onChanged: (value) => _${n}Value = value,')
      ..writeln("              label: ${dartStringLiteral(field.label)},");
    if (field.isRequired) {
      buffer.writeln('              validator: (value) =>');
      buffer.writeln(
        '                  value == null ? ${requiredMessage(field)} : null,',
      );
    }
    buffer.writeln('            ),');
    return Code(
      buffer.toString(),
      imports: {if (custom.libraryUri != null) custom.libraryUri!},
    );
  }
}
