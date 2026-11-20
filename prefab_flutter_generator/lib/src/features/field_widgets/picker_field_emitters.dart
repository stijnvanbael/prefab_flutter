import 'package:prefab_flutter/prefab_flutter.dart';
import 'package:source_gen/source_gen.dart';

import '../../core/code.dart';
import '../../manifest/field_manifest.dart';
import 'form_field_emitter.dart';
import 'form_validation.dart';

/// Shared by the pickers: a read-only text field showing the formatted value,
/// which opens a dialog on tap and keeps the picked value in `_<name>Value`.
abstract class PickerFieldEmitter extends FormFieldEmitter {
  const PickerFieldEmitter();

  @override
  bool get usesController => true;

  @override
  bool get isTextInput => true;

  @override
  Code? stateDeclaration(FieldManifest field) => Code(
        '  final _${field.name}Controller = TextEditingController();\n'
        '  ${field.dartType}? _${field.name}Value;\n',
      );

  @override
  Code initialValue(FieldManifest field, String entity) {
    final n = field.name;
    final display = displayExpression(field, '_${n}Value!');
    return Code(
      '    _${n}Value = $entity.$n;\n'
      '${field.isNullable ? "    _${n}Controller.text = _${n}Value == null ? '' : $display;" : '    _${n}Controller.text = $display;'}\n',
    );
  }

  @override
  String valueExpression(FieldManifest field) =>
      field.isNullable ? '_${field.name}Value' : '_${field.name}Value!';

  /// Dart expression for the locale-formatted display text of the non-null
  /// value [v] (uses `MaterialLocalizations`).
  String displayExpression(FieldManifest field, String v) =>
      'MaterialLocalizations.of(context).formatCompactDate($v)';

  /// The body of the `onTap` callback, indented for the form field.
  String onTapBody(FieldManifest field);

  @override
  Code formField(FieldManifest field) {
    final buffer = StringBuffer();
    buffer.writeln('            TextFormField(');
    buffer.writeln('              controller: _${field.name}Controller,');
    buffer.writeln('              readOnly: true,');
    buffer.writeln(
      "              decoration: const InputDecoration(labelText: '${field.label}'),",
    );
    buffer.writeln('              onTap: () async {');
    buffer.write(onTapBody(field));
    buffer.writeln('              },');
    buffer.write(validatorCallback(field, this).text);
    buffer.writeln('            ),');
    return Code(buffer.toString());
  }
}

/// [FieldWidget.datePicker]: a date (the default for `DateTime`).
class DatePickerFieldEmitter extends PickerFieldEmitter {
  const DatePickerFieldEmitter();

  @override
  FieldWidget get widget => FieldWidget.datePicker;

  @override
  bool accepts(FieldManifest field) => field.dartType == 'DateTime';

  @override
  String onTapBody(FieldManifest field) {
    final n = field.name;
    return '                final picked = await showDatePicker(\n'
        '                  context: context,\n'
        '                  initialDate: _${n}Value ?? DateTime.now(),\n'
        '                  firstDate: DateTime(2000),\n'
        '                  lastDate: DateTime(2100),\n'
        '                );\n'
        '                if (picked != null && context.mounted) {\n'
        '                  setState(() {\n'
        '                    _${n}Value = picked;\n'
        '                    _${n}Controller.text = ${displayExpression(field, 'picked')};\n'
        '                  });\n'
        '                }\n';
  }
}

/// [FieldWidget.timePicker]: a time of day for `Duration` (since midnight) and
/// `String` in `HH:mm` format.
class TimePickerFieldEmitter extends PickerFieldEmitter {
  const TimePickerFieldEmitter();

  @override
  FieldWidget get widget => FieldWidget.timePicker;

  @override
  bool accepts(FieldManifest field) => false;

  @override
  void check(FieldManifest field) {
    if (field.dartType != 'Duration' && field.dartType != 'String') {
      throw InvalidGenerationSourceError(
        'Field "${field.name}" uses FieldWidget.timePicker but has type '
        '${field.dartType}. timePicker supports Duration (time since '
        'midnight) and String in HH:mm format.',
      );
    }
  }

  @override
  String displayExpression(FieldManifest field, String v) =>
      'MaterialLocalizations.of(context)'
      '.formatTimeOfDay(${_timeOfDayExpression(field, v)})';

  /// Dart expression converting the non-null value [v] to a `TimeOfDay`.
  String _timeOfDayExpression(FieldManifest field, String v) {
    if (field.dartType == 'Duration') {
      return 'TimeOfDay(hour: $v.inHours % 24, minute: $v.inMinutes % 60)';
    }
    return "TimeOfDay(hour: int.parse($v.split(':')[0]), "
        "minute: int.parse($v.split(':')[1]))";
  }

  /// Dart expression converting the `TimeOfDay` [t] to the field's type.
  String _fromTimeOfDayExpression(FieldManifest field, String t) {
    if (field.dartType == 'Duration') {
      return 'Duration(hours: $t.hour, minutes: $t.minute)';
    }
    return "'\${$t.hour.toString().padLeft(2, '0')}:"
        "\${$t.minute.toString().padLeft(2, '0')}'";
  }

  @override
  String onTapBody(FieldManifest field) {
    final n = field.name;
    return '                final current = _${n}Value;\n'
        '                final picked = await showTimePicker(\n'
        '                  context: context,\n'
        '                  initialTime: current == null\n'
        '                      ? TimeOfDay.now()\n'
        '                      : ${_timeOfDayExpression(field, 'current')},\n'
        '                );\n'
        '                if (picked != null && context.mounted) {\n'
        '                  setState(() {\n'
        '                    _${n}Value = ${_fromTimeOfDayExpression(field, 'picked')};\n'
        '                    _${n}Controller.text = ${displayExpression(field, '_${n}Value!')};\n'
        '                  });\n'
        '                }\n';
  }
}

/// [FieldWidget.dateTimePicker]: a date followed by a time, for `DateTime`.
class DateTimePickerFieldEmitter extends PickerFieldEmitter {
  const DateTimePickerFieldEmitter();

  @override
  FieldWidget get widget => FieldWidget.dateTimePicker;

  @override
  bool accepts(FieldManifest field) => false;

  @override
  void check(FieldManifest field) {
    if (field.dartType != 'DateTime') {
      throw InvalidGenerationSourceError(
        'Field "${field.name}" uses FieldWidget.dateTimePicker but has type '
        '${field.dartType}. dateTimePicker supports DateTime.',
      );
    }
  }

  @override
  String displayExpression(FieldManifest field, String v) {
    const loc = 'MaterialLocalizations.of(context)';
    return "'\${$loc.formatCompactDate($v)} "
        "\${$loc.formatTimeOfDay(TimeOfDay.fromDateTime($v))}'";
  }

  @override
  String onTapBody(FieldManifest field) {
    final n = field.name;
    return '                final initial = _${n}Value ?? DateTime.now();\n'
        '                final date = await showDatePicker(\n'
        '                  context: context,\n'
        '                  initialDate: initial,\n'
        '                  firstDate: DateTime(2000),\n'
        '                  lastDate: DateTime(2100),\n'
        '                );\n'
        '                if (date == null || !context.mounted) return;\n'
        '                final time = await showTimePicker(\n'
        '                  context: context,\n'
        '                  initialTime: TimeOfDay.fromDateTime(initial),\n'
        '                );\n'
        '                if (time == null || !context.mounted) return;\n'
        '                final picked = DateTime(\n'
        '                  date.year, date.month, date.day, time.hour, time.minute,\n'
        '                );\n'
        '                setState(() {\n'
        '                  _${n}Value = picked;\n'
        '                  _${n}Controller.text = ${displayExpression(field, 'picked')};\n'
        '                });\n';
  }
}
