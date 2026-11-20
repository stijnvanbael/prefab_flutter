import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:prefab_flutter_generator/builder.dart';
import 'package:prefab_flutter_generator/src/features/actions/action_scanner.dart';
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

String _summary(List<Map<String, Object?>> actions) => [
      for (final a in actions)
        '{"name":"${a['name']}","uri":"package:a/actions.dart",'
            '"entity":"${a['entity'] ?? 'Alpha'}","label":"${a['label']}",'
            '"icon":${a['icon'] == null ? 'null' : '"${a['icon']}"'},'
            '"places":[${(a['places'] as List).map((p) => '"$p"').join(',')}],'
            '"order":${a['order'] ?? 0}}'
    ].join(',');

Future<String> _generate(Map<String, String> extra,
    {String entity = _entity}) async {
  String? out;
  await testBuilder(
    prefabBuilder(BuilderOptions.empty),
    {...prefabSources, 'a|lib/alpha.dart': entity, ...extra},
    generateFor: {'a|lib/alpha.dart'},
    outputs: {
      'a|lib/alpha.prefab.dart': decodedMatches(predicate<String>((s) {
        out = s;
        return true;
      }, 'captured')),
      // `generateFor` does not stop other inputs from being generated.
      if (extra.containsKey('a|lib/beta.dart'))
        'a|lib/beta.prefab.dart': anything,
    },
  );
  return out!;
}

String _json(List<Map<String, Object?>> actions) =>
    '[${_summary(actions)}]';

const _header = '''
import 'package:prefab_flutter/prefab_flutter.dart';
''';

void main() {
  group('scanActions', () {
    test('PF-44 AC#1 - reads label, icon, places and order', () {
      final actions = scanActions('''
$_header
@EntityAction(Product, label: 'Duplicate', icon: 'copy',
    on: {Place.detail, Place.item}, order: -1)
Future<void> duplicateProduct(
    BuildContext context, WidgetRef ref, Product product) async {}

@EntityAction(Product, label: 'Export', on: {Place.list})
void exportProducts(BuildContext context, WidgetRef ref) {}

@EntityAction(Product, label: 'Open')
void openProduct(BuildContext c, WidgetRef r, Product p) {}
''', 'package:a/actions.dart');
      expect(actions.map((a) => a.name),
          ['duplicateProduct', 'exportProducts', 'openProduct']);
      expect(actions[0].toJson()..remove('entityReference'), {
        'name': 'duplicateProduct',
        'uri': 'package:a/actions.dart',
        'entity': 'Product',
        'label': 'Duplicate',
        'icon': 'copy',
        'places': ['detail', 'item'],
        'order': -1,
      });
      expect(actions[1].places, ['list']);
      expect(actions[2].places, ['detail']);
      expect(actions[2].icon, isNull);
    });

    void rejects(String source, Matcher message) => expect(
        () => scanActions('$_header$source', 'package:a/actions.dart'),
        throwsA(isA<ActionException>()
            .having((e) => e.message, 'message', message)));

    test('PF-44 AC#5 - a wrong parameter list fails with a readable error', () {
      rejects('''
@EntityAction(Product, label: 'X')
void a(BuildContext context, Product product) {}
''', contains('expected the parameters (BuildContext, WidgetRef, Product) '
          'but found (BuildContext, Product)'));
      rejects('''
@EntityAction(Product, label: 'X')
void a(BuildContext context, WidgetRef ref, Review review) {}
''', contains('found (BuildContext, WidgetRef, Review)'));
      rejects('''
@EntityAction(Product, label: 'X', on: {Place.list})
void a(BuildContext context, WidgetRef ref, Product product) {}
''', contains('expected the parameters (BuildContext, WidgetRef)'));
      rejects('''
@EntityAction(Product, label: 'X')
void a(BuildContext context, WidgetRef ref, [Product? product]) {}
''', contains('required positional'));
    });

    test('PF-44 AC#5 - other misuse is reported with the function name', () {
      rejects('''
@EntityAction(Product, label: 'X', on: {Place.list, Place.item})
void a(BuildContext context, WidgetRef ref) {}
''', allOf(contains('@EntityAction on a'), contains('declare two functions')));
      rejects('''
@EntityAction(Product, label: 'X', icon: Icons.copy)
void a(BuildContext context, WidgetRef ref, Product product) {}
''', contains('icon must be the name'));
      rejects('''
@EntityAction(Product, label: 'X', on: {})
void a(BuildContext context, WidgetRef ref, Product product) {}
''', contains('at least one place'));
      rejects('''
@EntityAction(Product, label: 'X')
void _a(BuildContext context, WidgetRef ref, Product product) {}
''', contains('private'));
      rejects('''
@EntityAction(Product)
void a(BuildContext context, WidgetRef ref, Product product) {}
''', contains('label'));
    });

    test('ignores files and functions without the annotation', () {
      expect(scanActions('void a() {}', 'package:a/x.dart'), isEmpty);
    });
  });

  group('prefabActionsBuilder', () {
    test('PF-44 writes a summary only for files with @EntityAction', () async {
      await testBuilder(
        prefabActionsBuilder(BuilderOptions.empty),
        {
          'a|lib/x.dart': '''
@EntityAction(Alpha, label: 'Go')
void go(BuildContext c, WidgetRef r, Alpha a) {}
''',
          'a|lib/y.dart': 'void other() {}',
        },
        outputs: {
          'a|lib/x.prefab_actions.json': decodedMatches(allOf(
              contains('"name":"go"'), contains('"uri":"package:a/x.dart"'))),
        },
      );
    });
  });

  group('actions on the screens', () {
    test('PF-44 AC#1/#2 - detail: two icon buttons, the rest in a menu',
        () async {
      final out = await _generate({
        'a|lib/actions.prefab_actions.json': _json([
          {'name': 'zeta', 'label': 'Zeta', 'icon': 'copy', 'places': ['detail']},
          {'name': 'beta', 'label': 'Beta', 'places': ['detail']},
          {'name': 'alpha', 'label': 'Alpha', 'places': ['detail']},
          {'name': 'late', 'label': 'Late', 'icon': 'send', 'places': ['detail'], 'order': 5},
        ]),
      });
      expect(out, contains("import 'package:a/actions.dart';"));
      // Sorted by order, then label: Alpha, Beta, Zeta, Late(5).
      final alpha = out.indexOf("tooltip: 'Alpha'");
      final beta = out.indexOf("tooltip: 'Beta'");
      expect(alpha, isNonNegative);
      expect(beta, greaterThan(alpha));
      expect(out, contains('onPressed: alphaAsync.hasValue'));
      expect(out, contains('alpha(context, ref, alphaAsync.value!)'));
      expect(out, isNot(contains("tooltip: 'Zeta'")));
      expect(out, contains('PopupMenuButton<void>('));
      expect(out, contains('enabled: alphaAsync.hasValue'));
      expect(out.indexOf("Text('Zeta')"), lessThan(out.indexOf("Text('Late')")));
      expect(out, contains('child: const Row('));
      // Edit stays in front of the actions.
      expect(out.indexOf("tooltip: 'Edit'"), lessThan(alpha));
    });

    test('PF-44 AC#1/#3 - list AppBar and item menu', () async {
      final out = await _generate({
        'a|lib/actions.prefab_actions.json': _json([
          {'name': 'exportAlphas', 'label': "Export 'all'", 'icon': 'download', 'places': ['list']},
          {'name': 'duplicateAlpha', 'label': 'Duplicate', 'icon': 'copy', 'places': ['item']},
        ]),
      });
      expect(out, contains(r"tooltip: 'Export \'all\''"));
      expect(out, contains('onPressed: () => exportAlphas(context, ref)'));
      expect(out, contains('PopupMenuButton<void>('));
      expect(out, matches(RegExp(r'onTap: \(\) =>\s+duplicateAlpha\(context, ref, alpha\)')));
      expect(out, contains('trailing: Row('));
      // No action on the detail screen: it has no `actions` of its own here
      // beyond Edit.
      expect(out, isNot(contains('exportAlphas(context, ref, ')));
    });

    test('PF-44 - an action of another entity is not contributed', () async {
      final out = await _generate({
        'a|lib/actions.prefab_actions.json': _json([
          {'name': 'other', 'entity': 'Beta', 'label': 'X', 'places': ['detail']},
        ]),
        'a|lib/beta.dart':
            _entity.replaceAll('Alpha', 'Beta').replaceAll('alphas', 'betas'),
      });
      expect(out, isNot(contains('other(context')));
    });

    test('PF-44 - an action in the entity library is not imported again',
        () async {
      final out = await _generate({
        'a|lib/alpha.prefab_actions.json': _json([
          {'name': 'dup', 'label': 'Dup', 'places': ['detail']},
        ]).replaceAll('package:a/actions.dart', 'package:a/alpha.dart'),
      });
      expect(out, contains('dup(context, ref, alphaAsync.value!)'));
      expect(out, isNot(contains("import 'package:a/alpha.dart'")));
    });

    test('PF-44 AC#4 - promoted screens are left alone',
        () async {
      final out = await _generate({
        'a|lib/actions.prefab_actions.json': _json([
          {'name': 'dup', 'label': 'Dup', 'places': ['detail', 'item']},
        ]),
        'a|lib/s.prefab_promoted.json':
            '[{"name":"AlphaDetailScreen","uri":"package:a/s.dart"},'
                '{"name":"AlphaListScreen","uri":"package:a/s.dart"}]',
      });
      expect(out, isNot(contains('dup(')));
      expect(out, isNot(contains('package:a/actions.dart')));
    });

    test('PF-44 - an action for an unknown entity fails the build', () async {
      // The builder reports the error in the build log.
      final logs = <String>[];
      try {
        await testBuilder(
          prefabBuilder(BuilderOptions.empty),
          {
            ...prefabSources,
            'a|lib/alpha.dart': _entity,
            'a|lib/actions.prefab_actions.json': _json([
              {
                'name': 'dup',
                'entity': 'Alpa',
                'label': 'Dup',
                'places': ['detail']
              },
            ]),
          },
          generateFor: {'a|lib/alpha.dart'},
          outputs: {},
          onLog: (r) => logs.add('${r.message}\n${r.error ?? ''}'),
        );
      } catch (_) {}
      final log = logs.join('\n');
      expect(log, contains('@EntityAction on dup'));
      expect(log, contains('did you mean Alpha?'));
    });

    test('PF-44 - an entity without actions generates as before', () async {
      final out = await _generate({});
      expect(out, isNot(contains('PopupMenuButton')));
    });
  });
}
