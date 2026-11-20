import 'package:prefab_flutter/prefab_flutter.dart';
import 'package:source_gen/source_gen.dart';

import '../../core/code.dart';
import '../../manifest/field_manifest.dart';
import '../field_widgets/form_field_emitter.dart';
import '../validators/validator_emitters.dart' show dartStringLiteral;
import '../field_widgets/form_validation.dart';

/// A hand-written form widget (`@Field(form: FormOptions(builder: ...))`).
///
/// The form keeps the value in `_<name>Value` and hands the widget the
/// plain-Flutter contract of `PrefabFieldBuilder`: `initialValue`,
/// `onChanged`, `label` and, if the field is required and the widget takes
/// one, a `validator` that runs the validators fitting the field type. It claims every field that names a custom widget, ahead
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
    final type = field.dartType;
    for (final v in field.validators) {
      final String? needs = switch (v) {
        RequiredValidator() => null,
        MinValidator() ||
        MaxValidator() ||
        PositiveValidator() ||
        NonNegativeValidator() =>
          _isNumeric(type) ? null : 'a numeric field (int, double or num)',
        MinLengthValidator() || MaxLengthValidator() =>
          (type == 'String' || _isCollection(type))
              ? null
              : 'a String or a collection (List, Set, Iterable)',
        _ => type == 'String' ? null : 'a String field',
      };
      if (needs != null) {
        throw InvalidGenerationSourceError(
          '${v.runtimeType} cannot be used on "${field.name}" (type '
          '$type) because it needs $needs. The custom widget '
          '${custom.invocation} receives the validators that fit the field '
          'type; check other rules inside the widget.',
        );
      }
    }
    if (_needsValidator(field) && !custom.parameters.contains('validator')) {
      throw InvalidGenerationSourceError(
        'Field "${field.name}" is required or has validators but its custom '
        'widget ${custom.invocation} takes no "validator" parameter, so the '
        'form cannot check the value. Add a '
        '`String? Function(T? value)? validator` parameter.',
      );
    }
  }

  static bool _isNumeric(String t) => t == 'int' || t == 'double' || t == 'num';

  static bool _isCollection(String t) =>
      t.startsWith('List<') ||
      t.startsWith('Set<') ||
      t.startsWith('Iterable<');

  static bool _needsValidator(FieldManifest field) =>
      field.isRequired || field.validators.any((v) => v is! RequiredValidator);

  /// The check of one validator on the non-null `value`.
  String _check(Validator v, String value) {
    String msg(String fallback) => dartStringLiteral(v.message ?? fallback);
    const i = '                  ';
    return switch (v) {
      MinValidator() =>
        '${i}if ($value < ${v.value}) return ${msg('Must be at least ${v.value}')};\n',
      MaxValidator() =>
        '${i}if ($value > ${v.value}) return ${msg('Must be at most ${v.value}')};\n',
      PositiveValidator() =>
        '${i}if ($value <= 0) return ${msg('Must be a positive number')};\n',
      NonNegativeValidator() =>
        '${i}if ($value < 0) return ${msg('Must not be negative')};\n',
      MinLengthValidator() =>
        '${i}if ($value.length < ${v.length}) return ${msg('Must have at least ${v.length} characters or items')};\n',
      MaxLengthValidator() =>
        '${i}if ($value.length > ${v.length}) return ${msg('Must have at most ${v.length} characters or items')};\n',
      EmailValidator() =>
        "${i}if (!RegExp(r'^[^@\\s]+@[^@\\s]+\\.[^@\\s]+\$').hasMatch($value)) return ${msg('Invalid email address')};\n",
      UrlValidator() =>
        '${i}if (!(Uri.tryParse($value)?.isAbsolute ?? false)) return ${msg('Invalid URL')};\n',
      PatternValidator() =>
        '${i}if (!RegExp(${dartStringLiteral(v.regex)}).hasMatch($value)) return ${msg('Invalid format')};\n',
      _ => '',
    };
  }

  @override
  Code? stateDeclaration(FieldManifest field) =>
      Code('  ${field.dartType}? _${field.name}Value;\n');

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
    if (_needsValidator(field)) {
      final others = field.validators
          .where((v) => v is! RequiredValidator)
          .toList();
      if (others.isEmpty) {
        buffer.writeln('              validator: (value) =>');
        buffer.writeln(
          '                  value == null ? ${requiredMessage(field)} : null,',
        );
      } else {
        buffer.writeln('              validator: (value) {');
        buffer.writeln(
          field.isRequired
              ? '                if (value == null) return ${requiredMessage(field)};'
              : '                if (value == null) return null;',
        );
        buffer.writeln('                {');
        for (final v in others) {
          buffer.write(_check(v, 'value'));
        }
        buffer.writeln('                }');
        buffer.writeln('                return null;');
        buffer.writeln('              },');
      }
    }
    buffer.writeln('            ),');
    return Code(
      buffer.toString(),
      imports: {if (custom.libraryUri != null) custom.libraryUri!},
    );
  }
}
