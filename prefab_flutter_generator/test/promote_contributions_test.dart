import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:logging/logging.dart';
import 'package:prefab_flutter_generator/builder.dart';
import 'package:prefab_flutter_generator/src/promoted/promote.dart';
import 'package:test/test.dart';

import 'support/prefab_sources.dart';

const _entity = '''
import 'package:prefab_flutter/prefab_flutter.dart';

@Entity(title: 'Alpha', path: 'alphas')
@Update()
class Alpha {
  final int? id;
  @Field()
  final String name;
  Alpha({this.id, required this.name});
  factory Alpha.fromJson(Map<String, dynamic> json) => throw 0;
  Map<String, dynamic> toJson() => {};
}
''';

const _actions = '''
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prefab_flutter/prefab_flutter.dart';

@EntityAction(Alpha, label: 'Archive', on: {Place.detail, Place.item})
void archive(BuildContext context, WidgetRef ref, Alpha alpha) {}
''';

const _screen = '''
import 'package:prefab_flutter/prefab_flutter.dart';

@EntityScreen(Alpha, path: 'live', title: 'Live')
class AlphaLive {
  const AlphaLive({super.key, required this.id});
  final int id;
}
''';

void main() {
  group('promote keeps the contributions (PF-68)', () {
    late List<PromoteSource> sources;

    setUp(() async {
      final library = await resolveSources({
        ...prefabSources,
        'a|lib/alpha.dart': _entity,
      }, (r) => r.libraryFor(AssetId('a', 'lib/alpha.dart')));
      sources = [PromoteSource(library, 'lib/alpha.dart')];
    });

    PromotedFile promote(String name) {
      final found = scanPackageContributions('a', {
        'lib/alpha.dart': _entity,
        'lib/alpha_actions.dart': _actions,
        'lib/alpha_live.dart': _screen,
      });
      return promoteArtifact(
        name,
        sources,
        actions: found.actions,
        childScreens: found.childScreens,
        packageName: 'a',
      );
    }

    test('PF-68 AC#1 - the detail screen has actions and screen links', () {
      final c = promote('AlphaDetailScreen').content;
      expect(c, contains('archive(context, ref, alphaAsync.value!)'));
      expect(c, contains("import 'package:a/alpha_actions.dart';"));
      expect(c, contains("title: const Text('Live')"));
      expect(c, contains("context.push('/alphas/\$id/live')"));
    });

    test('PF-68 AC#1 - the list screen has the item actions', () {
      final c = promote('AlphaListScreen').content;
      expect(c, contains('archive('));
      expect(c, contains("import 'package:a/alpha_actions.dart';"));
    });

    test('PF-68 AC#1 - without contributions the output is unchanged', () {
      final c = promoteArtifact('AlphaDetailScreen', sources).content;
      expect(c, isNot(contains('archive(')));
    });
  });

  group('a promoted screen with contributions warns (PF-68)', () {
    Future<List<String>> warnings({bool promoted = true}) async {
      final logs = <String>[];
      await testBuilder(
        prefabBuilder(BuilderOptions.empty),
        {
          ...prefabSources,
          'a|lib/alpha.dart': _entity,
          'a|lib/alpha_actions.prefab_declarations.json':
              '{"actions":[{"name":"archive","uri":"package:a/alpha_actions.dart",'
              '"entity":"Alpha","label":"Archive","icon":null,'
              '"places":["detail","item"],"order":0}]}',
          'a|lib/alpha_live.prefab_declarations.json':
              '{"screens":[{"entity":"Alpha","path":"live","title":"Live",'
              '"className":"AlphaLive","uri":"package:a/alpha_live.dart",'
              '"params":[{"name":"id","named":true,"required":true,'
              '"type":"int"}]}]}',
          if (promoted)
            'a|lib/s.prefab_declarations.json':
                '{"promoted":[{"name":"AlphaDetailScreen","uri":"package:a/s.dart"},'
                '{"name":"AlphaListScreen","uri":"package:a/s.dart"}]}',
        },
        generateFor: {'a|lib/alpha.dart'},
        outputs: {'a|lib/alpha.prefab.dart': anything},
        onLog: (r) {
          if (r.level == Level.WARNING) logs.add(r.message);
        },
      );
      return logs;
    }

    test('PF-68 AC#2 - names the screen and the contribution', () async {
      final logs = await warnings();
      expect(
        logs,
        anyElement(
          allOf(
            contains('AlphaDetailScreen is @Promoted'),
            contains('archive'),
          ),
        ),
      );
      expect(
        logs,
        anyElement(
          allOf(contains('AlphaListScreen is @Promoted'), contains('archive')),
        ),
      );
      expect(
        logs,
        anyElement(
          allOf(
            contains('AlphaDetailScreen is @Promoted'),
            contains('AlphaLive'),
          ),
        ),
      );
    });

    test('PF-68 AC#2 - no warning when the screens are generated', () async {
      expect(await warnings(promoted: false), isEmpty);
    });
  });
}
