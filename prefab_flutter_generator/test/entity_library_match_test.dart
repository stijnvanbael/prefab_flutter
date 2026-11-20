import 'dart:convert';

import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:prefab_flutter_generator/builder.dart';
import 'package:prefab_flutter_generator/src/features/actions/action_scanner.dart';
import 'package:prefab_flutter_generator/src/features/entity_screens/child_screen.dart';
import 'package:test/test.dart';

import 'support/prefab_sources.dart';

String _entity(String path) => '''
import 'package:prefab_flutter/prefab_flutter.dart';

@Entity(title: 'Site', path: '$path')
@Update()
class Site {
  final String id;
  @Field()
  final String name;
  Site({required this.id, required this.name});
  factory Site.fromJson(Map<String, dynamic> json) => throw 0;
  Map<String, dynamic> toJson() => {};
}
''';

String _declarations(String imports, String entity) => '''
import 'package:flutter/widgets.dart';
import 'package:prefab_flutter/prefab_flutter.dart';
$imports

@EntityAction($entity, label: 'Ping')
void ping(BuildContext context, WidgetRef ref, Site site) {}

@EntityScreen($entity, path: 'live')
class SiteLive extends StatelessWidget {
  const SiteLive({super.key, required this.id});
  final String id;
  @override
  Widget build(BuildContext context) => const SizedBox();
}
''';

/// Generates `lib/one/site.dart` and `lib/two/site.dart`, which declare an
/// entity of the same name, and returns the output of each.
Future<Map<String, String>> _generate(String declarations,
    {Map<String, String> extra = const {}, List<String>? log}) async {
  const uri = 'package:a/declarations.dart';
  final out = <String, String>{};
  Matcher capture(String key) => decodedMatches(predicate<String>((s) {
        out[key] = s;
        return true;
      }, 'captured'));
  await testBuilder(
    prefabBuilder(BuilderOptions.empty),
    {
      ...prefabSources,
      'a|lib/one/site.dart': _entity('sites'),
      'a|lib/two/site.dart': _entity('locations'),
      'a|lib/declarations.dart': declarations,
      'a|lib/declarations.prefab_actions.json': jsonEncode(
          [for (final a in scanActions(declarations, uri)) a.toJson()]),
      'a|lib/declarations.prefab_screens.json': jsonEncode(
          [for (final s in scanChildScreens(declarations, uri)) s.toJson()]),
      ...extra,
    },
    generateFor: {'a|lib/one/site.dart', 'a|lib/two/site.dart'},
    onLog: (r) => log?.add(r.message),
    outputs: {
      'a|lib/one/site.prefab.dart': capture('one'),
      'a|lib/two/site.prefab.dart': capture('two'),
    },
  );
  return out;
}

void main() {
  group('PF-67', () {
    test('AC#1 - a declaration targets the entity of the imported library',
        () async {
      final out = await _generate(
          _declarations("import 'one/site.dart';", 'Site'));
      expect(out['one'], contains('ping('));
      expect(out['one'], contains('SiteLive'));
      expect(out['two'], isNot(contains('ping(')));
      expect(out['two'], isNot(contains('SiteLive')));
    });

    test('AC#1 - the import prefix selects the library', () async {
      final out = await _generate(_declarations(
          "import 'one/site.dart' as one;\nimport 'two/site.dart' as two;",
          'two.Site'));
      expect(out['two'], contains('ping('));
      expect(out['two'], contains('SiteLive'));
      expect(out['one'], isNot(contains('ping(')));
      expect(out['one'], isNot(contains('SiteLive')));
    });

    test('AC#1 - a hidden name is not taken from that import', () async {
      final out = await _generate(_declarations(
          "import 'one/site.dart' hide Site;\nimport 'two/site.dart';",
          'Site'));
      expect(out['two'], contains('ping('));
      expect(out['one'], isNot(contains('ping(')));
    });

    test('AC#2 - an entity reached through a barrel file is ambiguous',
        () async {
      final log = <String>[];
      await _generate(_declarations("import 'barrel.dart';", 'Site'),
              extra: {
                'a|lib/barrel.dart':
                    "export 'one/site.dart';\nexport 'two/site.dart';",
              },
              log: log)
          .then((_) {}, onError: (_) {});
      final message = log.join('\n');
      expect(message, contains('@EntityAction on ping'));
      expect(message, contains('package:a/one/site.dart'));
      expect(message, contains('package:a/two/site.dart'));
    });

    test('an entity reached through a barrel file is found when unique',
        () async {
      String? out;
      await testBuilder(
        prefabBuilder(BuilderOptions.empty),
        {
          ...prefabSources,
          'a|lib/one/site.dart': _entity('sites'),
          'a|lib/barrel.dart': "export 'one/site.dart';",
          'a|lib/declarations.dart':
              _declarations("import 'barrel.dart';", 'Site'),
          'a|lib/declarations.prefab_actions.json': jsonEncode([
            for (final a in scanActions(
                _declarations("import 'barrel.dart';", 'Site'),
                'package:a/declarations.dart'))
              a.toJson()
          ]),
        },
        generateFor: {'a|lib/one/site.dart'},
        outputs: {
          'a|lib/one/site.prefab.dart': decodedMatches(predicate<String>((s) {
            out = s;
            return true;
          }, 'captured')),
        },
      );
      expect(out, contains('ping('));
    });
  });
}
