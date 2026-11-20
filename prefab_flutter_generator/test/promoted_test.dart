import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:logging/logging.dart';
import 'package:prefab_flutter_generator/builder.dart';
import 'package:prefab_flutter_generator/src/promoted/promoted_scanner.dart';
import 'package:test/test.dart';

import 'support/prefab_sources.dart';

const _entity = '''
import 'package:prefab_flutter/prefab_flutter.dart';

@Entity(title: 'Alpha', path: 'alphas')
class Alpha {
  final int? id;
  @Field()
  final String name;
  Alpha({this.id, required this.name});
  factory Alpha.fromJson(Map<String, dynamic> json) => throw 0;
  Map<String, dynamic> toJson() => {};
}
''';

/// Messages logged at SEVERE level by the last [_generate] call (build_test 3
/// reports a failing builder as a log record, not as a thrown error).
final _severe = <String>[];

Future<String> _generate(Map<String, String> extra,
    {bool expectOutput = true}) async {
  String? out;
  _severe.clear();
  await testBuilder(
    prefabBuilder(BuilderOptions.empty),
    {...prefabSources, 'a|lib/alpha.dart': _entity, ...extra},
    generateFor: {'a|lib/alpha.dart'},
    onLog: (r) {
      if (r.level >= Level.SEVERE) _severe.add(r.message);
    },
    outputs: expectOutput
        ? {
            'a|lib/alpha.prefab.dart': decodedMatches(predicate<String>((s) {
              out = s;
              return true;
            }, 'captured')),
            // Other entities in the build are generated too.
            if (extra.containsKey('a|lib/beta.dart'))
              'a|lib/beta.prefab.dart': anything,
          }
        : {},
  );
  return out ?? '';
}

void main() {
  group('scanPromotedNames', () {
    test('finds annotated classes, variables and prefixed annotations', () {
      expect(
        scanPromotedNames('''
import 'package:prefab_flutter/prefab_flutter.dart' as p;
import 'package:prefab_flutter/prefab_flutter.dart';
@Promoted()
class A {}
@p.Promoted()
final b = 1;
class NotPromoted {}
@Deprecated('x')
class C {}
'''),
        ['A', 'b'],
      );
    });
  });

  group('prefabPromotedBuilder', () {
    test('writes a summary for a file with @Promoted', () async {
      await testBuilder(
        prefabPromotedBuilder(BuilderOptions.empty),
        {
          'a|lib/screens/x.dart': '''
@Promoted()
class AlphaDetailScreen {}
'''
        },
        outputs: {
          'a|lib/screens/x.prefab_promoted.json': decodedMatches(allOf(
              contains('"name":"AlphaDetailScreen"'),
              contains('"uri":"package:a/screens/x.dart"'),
              contains('"shape":{"kind":"class"'))),
        },
      );
    });

    test('writes nothing for a file without @Promoted', () async {
      await testBuilder(
        prefabPromotedBuilder(BuilderOptions.empty),
        {'a|lib/x.dart': 'class AlphaDetailScreen {}'},
        outputs: {},
      );
    });
  });

  group('prefabBuilder with @Promoted', () {
    test('skips the artifact, imports and re-exports the declaration',
        () async {
      final out = await _generate({
        'a|lib/screens/s.prefab_promoted.json':
            '[{"name":"AlphaDetailScreen","uri":"package:a/screens/s.dart"}]',
      });
      expect(out, isNot(contains('class AlphaDetailScreen')));
      expect(out, contains('class AlphaListScreen'));
      expect(out, contains("import 'package:a/screens/s.dart';"));
      expect(out,
          contains("export 'package:a/screens/s.dart' show AlphaDetailScreen;"));
    });

    test('fails with the closest artifact name for an unknown name', () async {
      await _generate({
        'a|lib/s.prefab_promoted.json':
            '[{"name":"AlphaDetailScren","uri":"package:a/s.dart"}]',
      }, expectOutput: false);
      expect(_severe.join('\n'), contains('did you mean AlphaDetailScreen?'));
    });

    test('accepts a promoted name generated from another file', () async {
      final out = await _generate({
        'a|lib/beta.dart': _entity
            .replaceAll('Alpha', 'Beta')
            .replaceAll('alphas', 'betas'),
        'a|lib/s.prefab_promoted.json':
            '[{"name":"BetaDetailScreen","uri":"package:a/s.dart"}]',
      });
      expect(out, contains('class AlphaDetailScreen'));
      expect(out, isNot(contains('BetaDetailScreen')));
    });
  });
}
