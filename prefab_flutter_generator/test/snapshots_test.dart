import 'dart:io';

import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:path/path.dart' as p;
import 'package:prefab_flutter_generator/builder.dart';
import 'package:test/test.dart';

import 'support/prefab_sources.dart';

/// Snapshot tests: every file in `test/snapshots/fixtures/` is run through the
/// full builder and the complete `.prefab.dart` output is compared with
/// `test/snapshots/expected/<fixture>.prefab.dart`.
///
/// Rewrite the expected files with
/// `UPDATE_SNAPSHOTS=1 dart test test/snapshots_test.dart`.
void main() {
  final fixtures = Directory('test/snapshots/fixtures');
  final expectedDir = Directory('test/snapshots/expected');
  final update = Platform.environment['UPDATE_SNAPSHOTS'] == '1';

  final files = fixtures
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  test('there are fixtures', () => expect(files, isNotEmpty));

  for (final file in files) {
    final name = p.basenameWithoutExtension(file.path);
    test('snapshot of $name', () async {
      final source = file.readAsStringSync();
      // A `<name>.prefab_promoted.json` fixture stands in for the summary of
      // hand-written `@Promoted` declarations.
      final summary = File(p.join(fixtures.path, '$name.prefab_promoted.json'));
      String? actual;
      await testBuilder(
        prefabBuilder(BuilderOptions.empty),
        {
          ...prefabSources,
          'a|lib/$name.dart': source,
          if (summary.existsSync())
            'a|lib/$name.prefab_promoted.json': summary.readAsStringSync(),
        },
        outputs: {
          'a|lib/$name.prefab.dart': decodedMatches(predicate<String>((s) {
            actual = s;
            return true;
          }, 'captured')),
        },
      );
      final output = actual!;
      final expectedFile = File(p.join(expectedDir.path, '$name.prefab.dart'));

      if (update) {
        expectedFile.createSync(recursive: true);
        expectedFile.writeAsStringSync(output);
        return;
      }
      if (!expectedFile.existsSync()) {
        fail('Missing ${expectedFile.path}. Run '
            'UPDATE_SNAPSHOTS=1 dart test test/snapshots_test.dart');
      }
      final expected = expectedFile.readAsStringSync();
      if (expected != output) {
        fail('Generated output of $name.dart differs from ${expectedFile.path}'
            '\n${_diff(expected.split('\n'), output.split('\n'))}\n'
            'If the change is intended, run '
            'UPDATE_SNAPSHOTS=1 dart test test/snapshots_test.dart '
            'and review the diff.');
      }
    });
  }
}

/// A line diff (`-` expected, `+` actual) with three lines of context,
/// computed from the longest common subsequence.
String _diff(List<String> a, List<String> b) {
  final n = a.length, m = b.length;
  final lcs = List.generate(n + 1, (_) => List.filled(m + 1, 0));
  for (var i = n - 1; i >= 0; i--) {
    for (var j = m - 1; j >= 0; j--) {
      lcs[i][j] = a[i] == b[j]
          ? lcs[i + 1][j + 1] + 1
          : (lcs[i + 1][j] >= lcs[i][j + 1] ? lcs[i + 1][j] : lcs[i][j + 1]);
    }
  }
  final ops = <String>[];
  var i = 0, j = 0;
  while (i < n || j < m) {
    if (i < n && j < m && a[i] == b[j]) {
      ops.add('  ${a[i]}');
      i++;
      j++;
    } else if (j >= m || (i < n && lcs[i + 1][j] >= lcs[i][j + 1])) {
      ops.add('- ${a[i++]}');
    } else {
      ops.add('+ ${b[j++]}');
    }
  }
  const context = 3;
  final keep = List.filled(ops.length, false);
  for (var k = 0; k < ops.length; k++) {
    if (ops[k].startsWith('- ') || ops[k].startsWith('+ ')) {
      for (var c = k - context; c <= k + context; c++) {
        if (c >= 0 && c < ops.length) keep[c] = true;
      }
    }
  }
  final out = StringBuffer();
  var skipped = false;
  for (var k = 0; k < ops.length; k++) {
    if (keep[k]) {
      out.writeln(ops[k]);
      skipped = false;
    } else if (!skipped) {
      out.writeln('  ...');
      skipped = true;
    }
  }
  return out.toString();
}
