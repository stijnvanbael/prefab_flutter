import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:prefab_flutter_generator/builder.dart';
import 'package:test/test.dart';
import 'support/prefab_sources.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Map<String, Object> _assets(String pkg, String path, String source) => {
      ...Map<String, Object>.from(prefabSources),
      '$pkg|$path': source,
    };

String _entity(String fieldDecl) => '''
import 'package:prefab_flutter/prefab_flutter.dart';

enum Color { red, green }

@View(title: 'Thing', path: 'things')
@Create()
@Update()
class Thing {
  late final int id;
  $fieldDecl

  Thing({required this.f});
}
''';

Future<void> _expectOutput(String fieldDecl, Matcher matcher) => testBuilder(
      formScreenBuilder(BuilderOptions.empty),
      _assets('a', 'lib/thing.dart', _entity(fieldDecl)),
      outputs: {'a|lib/thing.form_screen.dart': decodedMatches(matcher)},
    );

Future<String> _buildError(String fieldDecl) async {
  final logs = <String>[];
  try {
    await testBuilder(
      formScreenBuilder(BuilderOptions.empty),
      _assets('a', 'lib/thing.dart', _entity(fieldDecl)),
      onLog: (r) => logs.add('${r.message} ${r.error ?? ''}'),
    );
  } catch (e) {
    logs.add(e.toString());
  }
  return logs.join('\n');
}

void main() {
  group('Parameterised validators (PF-31)', () {
    test(
      'min',
      () => _expectOutput(
        "@Field(form: FormOptions(validators: [Validator.min(5)])) final int f;",
        allOf(
          contains('double.tryParse(value)'),
          contains('n < 5'),
          contains("'Must be at least 5'"),
        ),
      ),
    );

    test(
      'max',
      () => _expectOutput(
        "@Field(form: FormOptions(validators: [Validator.max(100)])) final int f;",
        allOf(contains('n > 100'), contains("'Must be at most 100'")),
      ),
    );

    test('positive and positiveNumber alias', () async {
      for (final v in ['positive', 'positiveNumber']) {
        await _expectOutput(
          "@Field(form: FormOptions(validators: [Validator.$v])) final double f;",
          allOf(contains('n <= 0'), contains("'Must be a positive number'")),
        );
      }
    });

    test(
      'nonNegative',
      () => _expectOutput(
        "@Field(form: FormOptions(validators: [Validator.nonNegative])) final int f;",
        allOf(contains('n < 0'), contains("'Must not be negative'")),
      ),
    );

    test(
      'email and url',
      () => _expectOutput(
        "@Field(form: FormOptions(validators: [Validator.email, Validator.url])) final String f;",
        allOf(
          contains("'Invalid email address'"),
          contains("'Invalid URL'"),
          contains('uri.isAbsolute'),
        ),
      ),
    );

    test(
      'minLength',
      () => _expectOutput(
        "@Field(form: FormOptions(validators: [Validator.minLength(3)])) final String f;",
        allOf(
          contains('value.length < 3'),
          contains("'Must be at least 3 characters'"),
        ),
      ),
    );

    test(
      'maxLength',
      () => _expectOutput(
        "@Field(form: FormOptions(validators: [Validator.maxLength(8)])) final String f;",
        allOf(
          contains('value.length > 8'),
          contains("'Must be at most 8 characters'"),
        ),
      ),
    );

    test(
      'pattern',
      () => _expectOutput(
        r"@Field(form: FormOptions(validators: [Validator.pattern(r'^[A-Z]+$')])) final String f;",
        allOf(contains(r"RegExp('^[A-Z]+\$')"), contains("'Invalid format'")),
      ),
    );

    test(
      'custom messages (including required and escaping)',
      () => _expectOutput(
        "@Field(form: FormOptions(validators: [RequiredValidator(message: 'Need it'), "
        "Validator.min(1, message: \"Can't be < 1\")])) final int f;",
        allOf(
          contains("return 'Need it'"),
          contains(r"return 'Can\'t be < 1'"),
        ),
      ),
    );

    test(
      'optional field skips checks when empty',
      () => _expectOutput(
        "@Field(form: FormOptions(validators: [Validator.maxLength(3)])) final String? f;",
        allOf(
          contains('value == null || value.isEmpty) return null'),
          contains('value.length > 3'),
        ),
      ),
    );

    test(
      'required on a dropdown checks null with custom message',
      () => _expectOutput(
        "@Field(form: FormOptions(validators: [RequiredValidator(message: 'Pick one')])) "
        "final Color? f;",
        allOf(
          contains("value == null ? 'Pick one' : null"),
          isNot(contains('isEmpty')),
        ),
      ),
    );

    test(
      'required enum is checked against null',
      () => _expectOutput(
        "@Field() final Color f;",
        allOf(
          contains("value == null ? 'Required' : null"),
          isNot(contains('value.isEmpty')),
        ),
      ),
    );

    test('text-only validator on a dropdown is rejected', () async {
      expect(
          await _buildError(
              '@Field(form: FormOptions(validators: [Validator.email])) final Color f;'),
          contains('EmailValidator cannot be used on "f"'));
    });

    test('text-only validator on a toggle is rejected', () async {
      expect(
          await _buildError(
              '@Field(form: FormOptions(validators: [Validator.min(1)])) final bool f;'),
          contains('MinValidator cannot be used on "f"'));
    });
  });

  group('numberInput', () {
    test(
      'int field gets a signed numeric keyboard and a digits formatter',
      () => _expectOutput(
        '@Field() final int f;',
        allOf(
          contains('const TextInputType.numberWithOptions(signed: true)'),
          contains(r"FilteringTextInputFormatter.allow(RegExp(r'^-?\d*$'))"),
        ),
      ),
    );

    test(
      'double field also allows one decimal separator',
      () => _expectOutput(
        '@Field() final double f;',
        allOf(
          contains('const TextInputType.numberWithOptions('),
          contains('decimal: true'),
          contains(
              r"FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*$'))"),
          contains('double.tryParse(value) == null'),
        ),
      ),
    );

    test(
      'explicit numberInput on a String field is accepted',
      () => _expectOutput(
        '@Field(form: FormOptions(widget: FieldWidget.numberInput)) '
        'final String f;',
        contains('keyboardType: const TextInputType.numberWithOptions'),
      ),
    );

    test(
      'range validators work on numberInput',
      () => _expectOutput(
        '@Field(form: FormOptions(validators: [Validator.min(1)])) final int f;',
        allOf(
          contains('const TextInputType.numberWithOptions(signed: true)'),
          contains('n < 1'),
        ),
      ),
    );
  });
}
