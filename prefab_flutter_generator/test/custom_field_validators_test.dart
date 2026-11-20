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

String _entity(String fieldDecl, {String views = ''}) =>
    '''
import 'package:prefab_flutter/prefab_flutter.dart';
import 'widgets.dart';

@Entity(title: 'Thing', path: 'things'$views)
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
      'a|lib/thing.prefab.dart': decodedMatches(
        predicate<String>((s) {
          out = s;
          return true;
        }, 'captured'),
      ),
    },
  );
  return out!;
}

Future<String> _buildError(String fieldDecl) async {
  final logs = <String>[];
  try {
    await testBuilder(prefabBuilder(BuilderOptions.empty), {
      ...prefabSources,
      'a|lib/widgets.dart': _widgets,
      'a|lib/thing.dart': _entity(fieldDecl),
    }, onLog: (r) => logs.add('${r.message} ${r.error ?? ''}'));
  } catch (e) {
    logs.add(e.toString());
  }
  return logs.join('\n');
}

void main() {
  group('PF-69 validators on custom field widgets', () {
    test('AC#1,3 - min and max run through the widget validator', () async {
      final out = await _generate(
        '@Field(form: FormOptions(builder: ColorField.new, validators: ['
        'Validator.required, Validator.min(1), Validator.max(9)]))\n'
        '  final int color;',
      );
      expect(out, contains('if (value == null) return \'Required\';'));
      expect(out, contains("if (value < 1) return 'Must be at least 1';"));
      expect(out, contains("if (value > 9) return 'Must be at most 9';"));
    });

    test('AC#1 - optional field skips checks for null', () async {
      final out = await _generate(
        '@Field(form: FormOptions(builder: ColorField.new, '
        'validators: [Validator.positive]))\n  final int? color;',
      );
      expect(out, contains('if (value == null) return null;'));
      expect(out, contains('if (value <= 0)'));
    });

    test('AC#2,3 - a validator that cannot apply fails the build', () async {
      final error = await _buildError(
        '@Field(form: FormOptions(builder: ColorField.new, '
        'validators: [Validator.maxLength(3)]))\n  final int? color;',
      );
      expect(error, contains('MaxLengthValidator'));
      expect(error, contains('"color"'));
      expect(error, contains('String or a collection'));
    });

    test('AC#2 - widget without validator parameter is rejected', () async {
      final error = await _buildError(
        '@Field(form: FormOptions(builder: NoValidator.new, '
        'validators: [Validator.min(1)]))\n  final int? color;',
      );
      expect(error, contains('validator'));
    });
  });
}
