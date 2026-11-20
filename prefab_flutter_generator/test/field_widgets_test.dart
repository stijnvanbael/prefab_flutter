import 'package:prefab_flutter/prefab_flutter.dart';
import 'package:prefab_flutter_generator/src/core/code.dart';
import 'package:prefab_flutter_generator/src/features/features.dart';
import 'package:prefab_flutter_generator/src/features/field_widgets/field_widgets_feature.dart';
import 'package:prefab_flutter_generator/src/manifest/field_manifest.dart';
import 'package:source_gen/source_gen.dart';
import 'package:test/test.dart';

FieldManifest field(
  String type, {
  FieldWidget widget = FieldWidget.auto,
  bool nullable = false,
  bool isEnum = false,
  List<Validator> validators = const [],
}) =>
    FieldManifest(
      name: 'f',
      label: 'F',
      hidden: false,
      isParent: false,
      dartType: type,
      fieldWidget: widget,
      isNullable: nullable,
      isEnum: isEnum,
      validators: validators,
    );

void main() {
  group('field widget resolution', () {
    final cases = <String, FieldManifest>{
      'ToggleFieldEmitter': field('bool'),
      'DatePickerFieldEmitter': field('DateTime'),
      'NumberInputFieldEmitter': field('int'),
      'DropdownFieldEmitter': field('Color', isEnum: true),
      'PlainTextFieldEmitter': field('String'),
      'MultilineTextFieldEmitter':
          field('String', widget: FieldWidget.multilineText),
      'PasswordFieldEmitter': field('String', widget: FieldWidget.password),
      'TimePickerFieldEmitter':
          field('Duration', widget: FieldWidget.timePicker),
      'DateTimePickerFieldEmitter':
          field('DateTime', widget: FieldWidget.dateTimePicker),
    };
    cases.forEach((emitter, f) {
      test('$emitter renders ${f.dartType} ${f.fieldWidget.name}', () {
        expect(formFieldEmitters.resolve(f).runtimeType.toString(), emitter);
      });
    });

    test('every FieldWidget has an emitter', () {
      final widgets = formFieldEmitters.emitters.map((e) => e.widget).toSet();
      expect(widgets, containsAll(FieldWidget.values));
    });

    test('timePicker rejects other types', () {
      expect(
        () => formFieldEmitters
            .resolve(field('int', widget: FieldWidget.timePicker)),
        throwsA(isA<InvalidGenerationSourceError>()),
      );
    });

    test('dateTimePicker rejects other types', () {
      expect(
        () => formFieldEmitters
            .resolve(field('String', widget: FieldWidget.dateTimePicker)),
        throwsA(isA<InvalidGenerationSourceError>()),
      );
    });
  });

  group('state, prefill and value', () {
    FormFieldEmitter e(FieldManifest f) => formFieldEmitters.resolve(f);

    test('text uses a controller', () {
      final f = field('String', nullable: true);
      expect(e(f).stateDeclaration(f)!.text,
          '  final _fController = TextEditingController();\n');
      expect(e(f).initialValue(f, 'item').text,
          "    _fController.text = item.f ?? '';\n");
      expect(e(f).valueExpression(f),
          '_fController.text.isEmpty ? null : _fController.text');
      expect(e(f).usesController, isTrue);
    });

    test('number parses the text', () {
      final f = field('double');
      expect(e(f).valueExpression(f), 'double.parse(_fController.text)');
      expect(e(f).initialValue(f, 'x').text,
          '    _fController.text = x.f.toString();\n');
    });

    test('number input needs the services library', () {
      expect(e(field('int')).formField(field('int')).imports,
          {Libs.flutterServices});
    });

    test('toggle keeps a bool', () {
      final f = field('bool');
      expect(e(f).stateDeclaration(f)!.text, '  bool _fValue = false;\n');
      expect(e(f).valueExpression(f), '_fValue');
      expect(e(f).usesController, isFalse);
      final n = field('bool', nullable: true);
      expect(e(n).stateDeclaration(n)!.text, '  bool? _fValue;\n');
    });

    test('date picker keeps a value and a controller', () {
      final f = field('DateTime', nullable: true);
      expect(e(f).stateDeclaration(f)!.text, contains('DateTime? _fValue;'));
      expect(e(f).initialValue(f, 'item').text,
          contains("_fValue == null ? ''"));
      expect(e(f).valueExpression(f), '_fValue');
      expect(e(field('DateTime')).valueExpression(field('DateTime')),
          '_fValue!');
    });

    test('unsupported text types fail', () {
      final f = field('Uri');
      expect(() => e(f).valueExpression(f),
          throwsA(isA<InvalidGenerationSourceError>()));
    });
  });

  group('validators on widgets', () {
    test('a text input gets the validator callback', () {
      final f = field('String', validators: const [EmailValidator()]);
      final text = formFieldEmitters.resolve(f).formField(f).text;
      expect(text, contains('validator: (value) {'));
      expect(text, contains('Invalid email address'));
    });

    test('numbers are checked to parse', () {
      final f = field('int');
      expect(formFieldEmitters.resolve(f).formField(f).text,
          contains('Must be a whole number'));
    });

    test('a dropdown only accepts required', () {
      final f = field('Color',
          isEnum: true, validators: const [MinLengthValidator(2)]);
      expect(() => formFieldEmitters.resolve(f).formField(f),
          throwsA(isA<InvalidGenerationSourceError>()));
    });
  });

  test('the feature is registered', () {
    expect(registeredFeatures.map((f) => f.name), contains('field_widgets'));
  });
}
