import 'package:prefab_flutter/prefab_flutter.dart';
import 'package:source_gen/source_gen.dart';

import '../../core/code.dart';
import '../../manifest/field_manifest.dart';
import 'form_field_emitter.dart';
import 'form_validation.dart';

/// Shared by the widgets that edit the value as text in a
/// `TextEditingController`.
abstract class TextFieldEmitter extends FormFieldEmitter {
  const TextFieldEmitter();

  @override
  bool get usesController => true;

  @override
  bool get isTextInput => true;

  @override
  Code? stateDeclaration(FieldManifest field) => Code(
        '  final _${field.name}Controller = TextEditingController();\n',
      );

  @override
  Code initialValue(FieldManifest field, String entity) {
    final String expr;
    if (field.dartType == 'String') {
      expr = field.isNullable
          ? "$entity.${field.name} ?? ''"
          : '$entity.${field.name}';
    } else {
      expr = field.isNullable
          ? "$entity.${field.name}?.toString() ?? ''"
          : '$entity.${field.name}.toString()';
    }
    return Code('    _${field.name}Controller.text = $expr;\n');
  }

  @override
  String valueExpression(FieldManifest field) {
    final text = '_${field.name}Controller.text';
    final String parsed;
    switch (field.dartType) {
      case 'String':
        parsed = text;
      case 'int':
      case 'double':
      case 'num':
        parsed = '${field.dartType}.parse($text)';
      default:
        throw InvalidGenerationSourceError(
          'Field "${field.name}" has type ${field.dartType}, which the '
          'generated form cannot convert from text. Supported types are '
          'String, int, double, num, bool, DateTime and enums.',
        );
    }
    return field.isNullable ? '$text.isEmpty ? null : $parsed' : parsed;
  }

  /// Lines between the controller and the validator of the `TextFormField`.
  String extraArguments(FieldManifest field) => '';

  Set<String> get imports => const {};

  @override
  Code formField(FieldManifest field) {
    final buffer = StringBuffer();
    buffer.writeln('            TextFormField(');
    buffer.writeln('              controller: _${field.name}Controller,');
    buffer.write(extraArguments(field));
    buffer.writeln(
      "              decoration: const InputDecoration(labelText: '${field.label}'),",
    );
    buffer.write(validatorCallback(field, this).text);
    buffer.writeln('            ),');
    return Code(buffer.toString(), imports: imports);
  }
}

/// Plain text: every type no other widget claims. It has no explicit
/// [FieldWidget], so it is registered with [FieldWidget.auto].
class PlainTextFieldEmitter extends TextFieldEmitter {
  const PlainTextFieldEmitter();

  @override
  FieldWidget get widget => FieldWidget.auto;

  @override
  bool accepts(FieldManifest field) => true;

  @override
  bool get parsesNumbers => true;
}

/// [FieldWidget.multilineText]: a text field that grows with its content.
class MultilineTextFieldEmitter extends TextFieldEmitter {
  const MultilineTextFieldEmitter();

  @override
  FieldWidget get widget => FieldWidget.multilineText;

  @override
  bool accepts(FieldManifest field) => false;

  @override
  String extraArguments(FieldManifest field) =>
      '              maxLines: null,\n'
      '              keyboardType: TextInputType.multiline,\n';
}

/// [FieldWidget.password]: an obscured text field.
class PasswordFieldEmitter extends TextFieldEmitter {
  const PasswordFieldEmitter();

  @override
  FieldWidget get widget => FieldWidget.password;

  @override
  bool accepts(FieldManifest field) => false;

  @override
  String extraArguments(FieldManifest field) =>
      '              obscureText: true,\n';
}

/// [FieldWidget.numberInput]: a numeric keyboard that only accepts digits.
class NumberInputFieldEmitter extends TextFieldEmitter {
  const NumberInputFieldEmitter();

  @override
  FieldWidget get widget => FieldWidget.numberInput;

  @override
  bool accepts(FieldManifest field) => FormFieldEmitter.isNumber(field);

  @override
  bool get parsesNumbers => true;

  // FilteringTextInputFormatter lives in services, which material_ui does
  // not re-export.
  @override
  Set<String> get imports => const {Libs.flutterServices};

  @override
  String extraArguments(FieldManifest field) {
    final isInt = field.dartType == 'int';
    final keyboard = isInt
        ? 'const TextInputType.numberWithOptions(signed: true)'
        : 'const TextInputType.numberWithOptions(signed: true, decimal: true)';
    final pattern = isInt ? r'^-?\d*$' : r'^-?\d*\.?\d*$';
    return '              keyboardType: $keyboard,\n'
        '              inputFormatters: [\n'
        "                FilteringTextInputFormatter.allow(RegExp(r'$pattern')),\n"
        '              ],\n';
  }
}
