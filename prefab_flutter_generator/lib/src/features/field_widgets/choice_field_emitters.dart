import 'package:prefab_flutter/prefab_flutter.dart';

import '../../core/code.dart';
import '../../manifest/field_manifest.dart';
import 'form_field_emitter.dart';
import 'form_validation.dart';

/// Shared by the widgets that pick one value from a fixed set; the form state
/// keeps it in `_<name>Value`.
abstract class ChoiceFieldEmitter extends FormFieldEmitter {
  const ChoiceFieldEmitter();

  @override
  bool get usesController => false;

  @override
  bool get isTextInput => false;

  @override
  Code initialValue(FieldManifest field, String entity) =>
      Code('    _${field.name}Value = $entity.${field.name};\n');
}

/// [FieldWidget.toggle]: a switch for `bool` (a Yes/No dropdown when the field
/// is nullable).
class ToggleFieldEmitter extends ChoiceFieldEmitter {
  const ToggleFieldEmitter();

  @override
  FieldWidget get widget => FieldWidget.toggle;

  @override
  bool accepts(FieldManifest field) => field.dartType == 'bool';

  @override
  Code? stateDeclaration(FieldManifest field) => Code(
        field.isNullable
            ? '  bool? _${field.name}Value;\n'
            : '  bool _${field.name}Value = false;\n',
      );

  @override
  String valueExpression(FieldManifest field) => '_${field.name}Value';

  @override
  Code formField(FieldManifest field) {
    checkValidatorsFor(field, this);
    final buffer = StringBuffer();
    if (field.isNullable) {
      // Nullable bool: dropdown with an empty (null) option.
      buffer.writeln('            DropdownButtonFormField<bool>(');
      buffer.writeln('              value: _${field.name}Value,');
      buffer.writeln(
        "              decoration: const InputDecoration(labelText: '${field.label}'),",
      );
      buffer.writeln('              items: const [');
      buffer.writeln(
        "                DropdownMenuItem<bool>(value: null, child: Text('')),",
      );
      buffer.writeln(
        "                DropdownMenuItem<bool>(value: true, child: Text('Yes')),",
      );
      buffer.writeln(
        "                DropdownMenuItem<bool>(value: false, child: Text('No')),",
      );
      buffer.writeln('              ],');
      buffer.writeln(
        '              onChanged: (v) => setState(() => _${field.name}Value = v),',
      );
      if (field.validators.any((v) => v is RequiredValidator)) {
        buffer.writeln(
          "              validator: (value) => value == null ? ${requiredMessage(field)} : null,",
        );
      }
      buffer.writeln('            ),');
      return Code(buffer.toString());
    }
    buffer.writeln('            SwitchListTile(');
    buffer.writeln("              title: const Text('${field.label}'),");
    buffer.writeln('              value: _${field.name}Value,');
    buffer.writeln(
      '              onChanged: (v) => setState(() => _${field.name}Value = v),',
    );
    buffer.writeln('            ),');
    return Code(buffer.toString());
  }
}

/// [FieldWidget.dropdown]: a dropdown of the values of an enum.
class DropdownFieldEmitter extends ChoiceFieldEmitter {
  const DropdownFieldEmitter();

  @override
  FieldWidget get widget => FieldWidget.dropdown;

  @override
  bool accepts(FieldManifest field) => field.isEnum;

  @override
  Code? stateDeclaration(FieldManifest field) =>
      Code('  ${field.dartType}? _${field.name}Value;\n');

  @override
  String valueExpression(FieldManifest field) =>
      field.isNullable ? '_${field.name}Value' : '_${field.name}Value!';

  @override
  Code formField(FieldManifest field) {
    checkValidatorsFor(field, this);
    final type = field.dartType;
    final buffer = StringBuffer();
    buffer.writeln('            DropdownButtonFormField<$type>(');
    buffer.writeln('              value: _${field.name}Value,');
    buffer.writeln(
      "              decoration: const InputDecoration(labelText: '${field.label}'),",
    );
    buffer.writeln('              items: [');
    if (field.isNullable) {
      buffer.writeln(
        "                const DropdownMenuItem<$type>(value: null, child: Text('')),",
      );
    }
    buffer.writeln(
      '                ...$type.values.map((v) => DropdownMenuItem<$type>(',
    );
    buffer.writeln('                  value: v,');
    buffer.writeln('                  child: Text(v.name),');
    buffer.writeln('                )),');
    buffer.writeln('              ],');
    buffer.writeln(
      '              onChanged: (v) => setState(() => _${field.name}Value = v),',
    );
    if (field.isRequired) {
      buffer.writeln(
        "              validator: (value) => value == null ? ${requiredMessage(field)} : null,",
      );
    }
    buffer.writeln('            ),');
    return Code(buffer.toString());
  }
}
