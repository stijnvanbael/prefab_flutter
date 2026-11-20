import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:prefab_flutter_generator/builder.dart';
import 'package:test/test.dart';

import 'support/prefab_sources.dart';

const _widgets = '''
class ColorField {
  const ColorField({
    super.key,
    required this.initialValue,
    required this.onChanged,
    required this.label,
    this.validator,
  });
  final int? initialValue;
  final void Function(int?) onChanged;
  final String label;
  final String? Function(int?)? validator;
  static ColorField build({
    required int? initialValue,
    required void Function(int?) onChanged,
    required String label,
  }) => throw 0;
}

class NoValidator {
  const NoValidator({
    required this.initialValue,
    required this.onChanged,
    required this.label,
  });
  final int? initialValue;
  final void Function(int?) onChanged;
  final String label;
}

class BadParams {
  const BadParams(this.value);
  final int value;
}

class Swatch {
  const Swatch({super.key, required this.value});
  final int? value;
}
''';

String _entity(String fieldDecl, {String views = ''}) => '''
import 'package:prefab_flutter/prefab_flutter.dart';
import 'widgets.dart';

@View(title: 'Thing', path: 'things'$views)
@Create()
@Update()
class Thing {
  final int? id;
  $fieldDecl

  Thing({this.id, required this.color});

  factory Thing.fromJson(Map<String, dynamic> json) => throw 0;
  Map<String, dynamic> toJson() => {};
}
''';

Future<String> _generate(String fieldDecl) async {
  String? out;
  await testBuilder(
    prefabBuilder(BuilderOptions.empty),
    {
      ...prefabSources,
      'a|lib/widgets.dart': _widgets,
      'a|lib/thing.dart': _entity(fieldDecl),
    },
    outputs: {
      'a|lib/thing.prefab.dart': decodedMatches(predicate<String>((s) {
        out = s;
        return true;
      }, 'captured')),
    },
  );
  return out!;
}

Future<String> _buildError(String fieldDecl) async {
  final logs = <String>[];
  try {
    await testBuilder(
      prefabBuilder(BuilderOptions.empty),
      {
        ...prefabSources,
        'a|lib/widgets.dart': _widgets,
        'a|lib/thing.dart': _entity(fieldDecl),
      },
      onLog: (r) => logs.add('${r.message} ${r.error ?? ''}'),
    );
  } catch (e) {
    logs.add(e.toString());
  }
  return logs.join('\n');
}

void main() {
  group('PF-65 custom field widgets', () {
    test('AC#1 - form widget is prefilled, validated and saved', () async {
      final out = await _generate(
        '@Field(form: FormOptions(custom: ColorField.new, '
        'validators: [Validator.required]))\n  final int color;',
      );
      expect(out, contains("import 'package:a/widgets.dart';"));
      expect(out, contains('int? _colorValue;'));
      expect(out, contains('_colorValue = item.color;'));
      expect(out, contains('ColorField('));
      expect(out, contains('initialValue: _colorValue,'));
      expect(out, contains('onChanged: (value) => _colorValue = value,'));
      expect(out, contains("label: 'Color',"));
      expect(out, contains("value == null ? 'Required' : null"));
      expect(out, contains('color: _colorValue!,'));
    });

    test('AC#1 - nullable field needs no validator', () async {
      final out = await _generate(
        '@Field(form: FormOptions(custom: NoValidator.new))\n'
        '  final int? color;',
      );
      expect(out, contains('NoValidator('));
      expect(out, isNot(contains('validator:')));
      expect(out, contains('color: _colorValue,'));
    });

    test('AC#1 - a named constructor or static function is called by name',
        () async {
      final out = await _generate(
        '@Field(form: FormOptions(custom: ColorField.build))\n'
        '  final int? color;',
      );
      expect(out, contains('ColorField.build('));
    });

    test('AC#2 - display widget in detail screen and list tile', () async {
      final out = await _generate(
        '@Field(display: Swatch.new)\n  final int? color;',
      );
      expect(out, contains('Swatch(value: thing.color),'));
      expect(out, contains('prefabTheme.detailFieldBuilder('));
      expect(out, contains('title: Swatch(value: thing.color),'));
      expect(out, isNot(contains("?.toString() ?? '—'")));
    });

    test('AC#4 - wrong signature names the field and the parameters',
        () async {
      final error = await _buildError(
        '@Field(display: BadParams.new)\n  final int color;',
      );
      expect(error, contains('Field "color"'));
      expect(error, contains('Field.display'));
      expect(error, contains('value'));
    });

    test('AC#4 - required field needs a validator parameter', () async {
      final error = await _buildError(
        '@Field(form: FormOptions(custom: NoValidator.new))\n'
        '  final int color;',
      );
      expect(error, contains('Field "color"'));
      expect(error, contains('validator'));
    });

    test('AC#4 - text validators are rejected', () async {
      final error = await _buildError(
        '@Field(form: FormOptions(custom: ColorField.new, '
        'validators: [Validator.email]))\n  final int? color;',
      );
      expect(error, contains('"color"'));
      expect(error, contains('Only Validator.required'));
    });
  });
}
