import 'dart:convert';

import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:logging/logging.dart';
import 'package:prefab_flutter_generator/builder.dart';
import 'package:prefab_flutter_generator/src/features/entity_screens/child_screen.dart';
import 'package:test/test.dart';

import 'support/prefab_sources.dart';

const _entities = '''
import 'package:prefab_flutter/prefab_flutter.dart';

@View(title: 'Site', path: 'sites')
@Update()
class Site {
  final String id;
  @Field()
  final String name;
  Site({required this.id, required this.name});
  factory Site.fromJson(Map<String, dynamic> json) => throw 0;
  Map<String, dynamic> toJson() => {};
}

@View(title: 'Meter', path: 'meters')
class Meter {
  final int? id;
  @Parent(Site)
  @Field(hidden: true)
  final String siteId;
  @Field()
  final String label;
  Meter({this.id, required this.siteId, required this.label});
  factory Meter.fromJson(Map<String, dynamic> json) => throw 0;
  Map<String, dynamic> toJson() => {};
}
''';

String _screen(String annotations, String body) => '''
import 'package:flutter/widgets.dart';
import 'package:prefab_flutter/prefab_flutter.dart';

$annotations
class SiteLive extends StatelessWidget {
  $body
  @override
  Widget build(BuildContext context) => const SizedBox();
}
''';

const _goodBody = '''
  const SiteLive({super.key, required this.id});
  final String id;
''';

Future<String> _generate(String screenSource) async {
  String? out;
  await testBuilder(
    prefabBuilder(BuilderOptions.empty),
    {
      ...prefabSources,
      'a|lib/site.dart': _entities,
      'a|lib/site_live.dart': screenSource,
      'a|lib/site_live.prefab_screens.json': jsonEncode([
        for (final s
            in scanChildScreens(screenSource, 'package:a/site_live.dart'))
          s.toJson(),
      ]),
    },
    generateFor: {'a|lib/site.dart'},
    outputs: {
      'a|lib/site.prefab.dart': decodedMatches(predicate<String>((s) {
        out = s;
        return true;
      }, 'captured')),
    },
  );
  return out!;
}

void main() {
  group('scanChildScreens', () {
    test('PF-45 reads path, title and constructor parameters', () {
      final screens = scanChildScreens('''
import 'package:prefab_flutter/prefab_flutter.dart' as p;
@p.EntityScreen(Site, path: 'study-session')
class A extends Widget {
  const A({super.key, required this.id, int? depth, required String siteId});
  final int id;
}
class NotAScreen {}
''', 'package:a/a.dart');
      expect(screens, hasLength(1));
      final s = screens.single;
      expect(s.entity, 'Site');
      expect(s.path, 'study-session');
      expect(s.title, 'Study session');
      expect(s.className, 'A');
      expect(
          [for (final p in s.params) (p.name, p.type, p.named, p.required)], [
        ('key', null, true, false),
        ('id', 'int', true, true),
        ('depth', 'int?', true, false),
        ('siteId', 'String', true, true),
      ]);
    });
  });

  group('prefabScreensBuilder', () {
    test('PF-45 writes a summary only for files with @EntityScreen', () async {
      await testBuilder(
        prefabScreensBuilder(BuilderOptions.empty),
        {
          'a|lib/with.dart': _screen(
              "@EntityScreen(Site, path: 'live', title: 'Live')", _goodBody),
          'a|lib/without.dart': 'class X {}',
        },
        outputs: {
          'a|lib/with.prefab_screens.json': decodedMatches(allOf(
              contains('"className":"SiteLive"'),
              contains('"title":"Live"'))),
        },
      );
    });
  });

  group('generated output', () {
    late String output;
    setUpAll(() async {
      output = await _generate(_screen(
          "@EntityScreen(Site, path: 'live', title: 'Live')", _goodBody));
    });

    test('PF-45 AC#1 the route sits below the detail route and passes the id',
        () {
      expect(output, contains("import 'package:a/site_live.dart';"));
      expect(output, contains("path: 'live'"));
      // Site has the nested entity Meter, so its id parameter is `siteId`.
      expect(output,
          contains("SiteLive(id: state.pathParameters['siteId']!)"));
    });

    test('PF-45 AC#2 the detail screen links to the screen', () {
      expect(output, contains("title: const Text('Live')"));
      expect(output, contains("context.push('/sites/\$id/live')"));
    });

    test('PF-45 AC#3 a breadcrumb helper is generated', () {
      expect(output, contains('PrefabBreadcrumbBar siteBreadcrumbs('));
      expect(output, contains('required String title, required String id'));
    });
  });

  group('errors', () {
    /// Runs the builder on [screen] and checks that the build fails with a
    /// message that satisfies [message].
    Future<void> expectFails(String screen, Matcher message) async {
      final logs = <String>[];
      try {
        await testBuilder(
          prefabBuilder(BuilderOptions.empty),
          {
            ...prefabSources,
            'a|lib/site.dart': _entities,
            'a|lib/site_live.dart': screen,
            'a|lib/site_live.prefab_screens.json': jsonEncode([
              for (final s
                  in scanChildScreens(screen, 'package:a/site_live.dart'))
                s.toJson(),
            ]),
          },
          generateFor: {'a|lib/site.dart'},
          outputs: {},
          onLog: (r) {
            if (r.level >= Level.SEVERE) logs.add(r.message);
          },
        );
      } catch (e) {
        logs.add('$e');
      }
      expect(logs.join('\n'), message);
    }

    test('PF-45 AC#4 a missing id parameter names the expected parameters',
        () async {
      await expectFails(
        _screen("@EntityScreen(Site, path: 'live')",
            '  const SiteLive({super.key});\n'),
        allOf(contains('SiteLive'), contains('there is no parameter `id`'),
            contains('`String id`')),
      );
    });

    test('PF-45 AC#4 a wrong id type is reported', () async {
      await expectFails(
        _screen("@EntityScreen(Site, path: 'live')",
            '  const SiteLive({super.key, required this.id});\n  final int id;\n'),
        contains('`id` has type int, expected String'),
      );
    });

    test('PF-45 AC#4 an extra required parameter is reported', () async {
      await expectFails(
        _screen("@EntityScreen(Site, path: 'live')",
            '  const SiteLive({super.key, required this.id, required this.x});\n  final String id;\n  final int x;\n'),
        contains('`x` is required but the route cannot pass it'),
      );
    });

    test('PF-45 a path that clashes with the edit route is rejected',
        () async {
      await expectFails(
        _screen("@EntityScreen(Site, path: 'edit')", _goodBody),
        contains("path 'edit' is already used"),
      );
    });

    test('PF-45 a path that clashes with a nested entity is rejected',
        () async {
      await expectFails(
        _screen("@EntityScreen(Site, path: 'meters')", _goodBody),
        contains("path 'meters' is already used"),
      );
    });

    test('PF-45 an unknown entity names the closest one', () async {
      await expectFails(
        _screen("@EntityScreen(Sit, path: 'live')", _goodBody),
        allOf(contains('names Sit'), contains('did you mean Site?')),
      );
    });
  });
}
