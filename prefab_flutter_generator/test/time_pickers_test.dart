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
  group('timePicker and dateTimePicker (PF-17)', () {
    test(
      'timePicker on Duration stores a typed Duration and formats via locale',
      () => _expectOutput(
        '@Field(form: FormOptions(widget: FieldWidget.timePicker)) final Duration f;',
        allOf(
          contains('Duration? _fValue;'),
          contains('showTimePicker('),
          contains('Duration(hours: picked.hour, minutes: picked.minute)'),
          contains('MaterialLocalizations.of(context).formatTimeOfDay('),
          contains('_fValue!'),
          isNot(contains('toIso8601String')),
        ),
      ),
    );

    test(
      'timePicker on String uses HH:mm',
      () => _expectOutput(
        '@Field(form: FormOptions(widget: FieldWidget.timePicker)) final String f;',
        allOf(
          contains('String? _fValue;'),
          contains("padLeft(2, '0')"),
          contains("split(':')"),
        ),
      ),
    );

    test(
      'dateTimePicker chains both pickers',
      () => _expectOutput(
        '@Field(form: FormOptions(widget: FieldWidget.dateTimePicker)) final DateTime f;',
        allOf(
          contains('DateTime? _fValue;'),
          contains('showDatePicker('),
          contains('showTimePicker('),
          contains('formatCompactDate('),
          contains('formatTimeOfDay('),
        ),
      ),
    );

    test(
      'datePicker display uses locale formatting, not ISO-8601',
      () => _expectOutput(
        '@Field(form: FormOptions()) final DateTime f;',
        allOf(
            contains('formatCompactDate('), isNot(contains('toIso8601String'))),
      ),
    );

    test(
      'timePicker on an unsupported type is a build error',
      () async {
        final out = await _buildError(
          '@Field(form: FormOptions(widget: FieldWidget.timePicker)) final int f;',
        );
        expect(out, contains('timePicker'));
        expect(out, contains('Duration'));
      },
    );

    test(
      'dateTimePicker on an unsupported type is a build error',
      () async {
        final out = await _buildError(
          '@Field(form: FormOptions(widget: FieldWidget.dateTimePicker)) final String f;',
        );
        expect(out, contains('dateTimePicker'));
      },
    );
  });
}
