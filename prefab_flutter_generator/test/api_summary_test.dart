import 'dart:io';

import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:path/path.dart' as p;
import 'package:prefab_flutter_generator/builder.dart';
import 'package:test/test.dart';

import 'support/api_summary.dart';
import 'support/prefab_sources.dart';

/// Guards the public API of generated code (PF-47): the public declarations
/// and signatures of every snapshot fixture are compared with
/// `test/api/<fixture>.api.txt`. A difference is a change to the API that
/// hand-written code builds on; see "Public API summary" in
/// `docs/developer_guide.md`.
///
/// Rewrite the summaries with
/// `UPDATE_SNAPSHOTS=1 dart test test/api_summary_test.dart`.
void main() {
  final fixtures = Directory('test/snapshots/fixtures');
  final apiDir = Directory('test/api');
  final update = Platform.environment['UPDATE_SNAPSHOTS'] == '1';

  final files = fixtures
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  for (final file in files) {
    final name = p.basenameWithoutExtension(file.path);
    test('public API of $name', () async {
      final declarations =
          File(p.join(fixtures.path, '$name.prefab_declarations.json'));
      String? generated;
      await testBuilder(
        prefabBuilder(BuilderOptions.empty),
        {
          ...prefabSources,
          'a|lib/$name.dart': file.readAsStringSync(),
          if (declarations.existsSync())
            'a|lib/$name.prefab_declarations.json':
                declarations.readAsStringSync(),
        },
        outputs: {
          'a|lib/$name.prefab.dart': decodedMatches(predicate<String>((s) {
            generated = s;
            return true;
          }, 'captured')),
        },
      );
      final actual = extractPublicApi(generated!);
      final expectedFile = File(p.join(apiDir.path, '$name.api.txt'));
      if (update) {
        expectedFile.createSync(recursive: true);
        expectedFile.writeAsStringSync(actual);
        return;
      }
      if (!expectedFile.existsSync()) {
        fail('Missing ${expectedFile.path}. Run '
            'UPDATE_SNAPSHOTS=1 dart test test/api_summary_test.dart');
      }
      expect(actual, expectedFile.readAsStringSync(),
          reason: 'The public API of the code generated for $name.dart '
              'changed. If intended, run '
              'UPDATE_SNAPSHOTS=1 dart test test/api_summary_test.dart, '
              'review the diff and add a changelog entry (breaking change).');
    });
  }

  test('private names are not part of the summary', () {
    final api = extractPublicApi(
        'class _A {} class B { int x = 1; int _y = 2; void m() {} void _n() {} }');
    expect(api, contains('class B'));
    expect(api, isNot(contains('_A')));
    expect(api, isNot(contains('_y')));
    expect(api, isNot(contains('_n')));
  });
}
