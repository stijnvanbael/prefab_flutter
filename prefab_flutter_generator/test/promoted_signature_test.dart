import 'dart:convert';
import 'dart:io';

import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:logging/logging.dart';
import 'package:prefab_flutter_generator/builder.dart';
import 'package:prefab_flutter_generator/src/promoted/promoted_scanner.dart';
import 'package:test/test.dart';

import 'support/prefab_sources.dart';

String _entity(String extra) => '''
import 'package:prefab_flutter/prefab_flutter.dart';

@Entity(title: 'Alpha', path: 'alphas')
@Create()
@Update()
@Delete()
class Alpha {
  final int? id;
  @Field()
  final String name;
  Alpha({this.id, required this.name});
  factory Alpha.fromJson(Map<String, dynamic> json) => throw 0;
  Map<String, dynamic> toJson() => {};
}
$extra
''';

/// Builds the summary of [source] like the promoted builder and runs the
/// generator with it; returns the SEVERE messages.
Future<String> _severe(String source, {String extra = ''}) async {
  final summary = <String>[];
  await testBuilder(
    prefabDeclarationsBuilder(BuilderOptions.empty),
    {'a|lib/p.dart': '@Promoted()\n$source'},
    outputs: {
      'a|lib/p.prefab_declarations.json':
          decodedMatches(predicate<String>((s) {
        summary.add(s);
        return true;
      }, 'captured')),
    },
  );
  final severe = <String>[];
  await testBuilder(
    prefabBuilder(BuilderOptions.empty),
    {
      ...prefabSources,
      'a|lib/alpha.dart': _entity(extra),
      'a|lib/p.prefab_declarations.json': summary.single,
    },
    generateFor: {'a|lib/alpha.dart'},
    onLog: (r) {
      if (r.level >= Level.SEVERE) severe.add(r.message);
    },
  );
  return severe.join('\n');
}

void main() {
  group('promoted signature', () {
    test('a screen with wrong constructor parameters names the expected ones',
        () async {
      final message = await _severe('''
class AlphaDetailScreen extends ConsumerWidget {
  final String id;
  const AlphaDetailScreen({super.key, required this.id});
}''');
      expect(message, contains('@Promoted AlphaDetailScreen'));
      expect(message,
          contains('Expected: const AlphaDetailScreen({super.key, required int id})'));
      expect(message, contains('parameter id has type String, expected int'));
    });

    test('a screen without const constructor or id is reported', () async {
      final message = await _severe('''
class AlphaEditScreen extends StatefulWidget {
  AlphaEditScreen({super.key});
}''');
      expect(message, contains('the constructor must be const'));
      expect(message, contains('missing named parameter required int id'));
    });

    test('a promoted list screen may not require more than the generator passes',
        () async {
      final message = await _severe('''
class AlphaListScreen extends StatelessWidget {
  final int page;
  const AlphaListScreen({super.key, required this.page});
}''');
      expect(message, contains('parameter page must not be required'));
    });

    test('a screen that is not a class is reported', () async {
      final message = await _severe('final AlphaCreateScreen = 1;');
      expect(message, contains('A screen must be a class'));
    });

    test('a promoted API client without the generated methods', () async {
      final message = await _severe('''
class AlphaApiClient {
  AlphaApiClient(Dio dio);
  Future<Alpha> getById(int id) => throw 0;
}''');
      expect(message, contains('Expected: AlphaApiClient(Dio, [PrefabListAdapter])'));
      expect(message, contains('missing method list'));
      expect(message, contains('missing method delete'));
      expect(message, contains('as positional parameters'));
    });

    test('a promoted provider with the wrong type', () async {
      final detail = await _severe(
          'final alphaDetailProvider = FutureProvider.autoDispose.family<Alpha, String>((ref, id) => throw 0);');
      expect(detail, contains('Expected: FutureProvider.autoDispose.family<Alpha, int>'));
      final list = await _severe(
          'final alphasProvider = Provider<List<Alpha>>((ref) => []);');
      expect(list, contains('AsyncNotifierProvider<AlphasNotifier, PrefabPage<Alpha>>'));
      final client = await _severe(
          'final alphaApiClientProvider = Provider<Dio>((ref) => throw 0);');
      expect(client, contains('Expected: Provider<AlphaApiClient>'));
    });

    test('promoted routes of the wrong type', () async {
      // The routes getter is named after the file: $alphaRoutes.
      final routes = await _severe('List<GoRoute> get \$alphaRoutes => [];');
      expect(routes, contains('The type must be List<RouteBase>'));
      final notGetter = await _severe('class \$alphaRoutes {}');
      expect(notGetter, contains('Routes are spread into the router'));
    });

    test('matching declarations and unreadable types pass', () async {
      expect(
          await _severe('''
class AlphaDetailScreen extends ConsumerWidget {
  final int id;
  const AlphaDetailScreen({super.key, required this.id});
}'''),
          isEmpty);
      expect(
          await _severe(
              'final alphaDetailProvider = buildProvider(); List<RouteBase> get \$alphaRoutes => [];'),
          isEmpty);
      expect(
          await _severe('''
class AlphaApiClient {
  AlphaApiClient(this._dio, [this._adapter = const PrefabListAdapter()]);
  Future<PrefabPage<Alpha>> list() => throw 0;
  Future<Alpha> getById(int id) => throw 0;
  Future<Alpha> create(Alpha a) => throw 0;
  Future<Alpha> update(Alpha a) => throw 0;
  Future<void> delete(Alpha a) => throw 0;
}'''),
          isEmpty);
    });
  });

  test('the summary holds the shape of the declaration', () {
    final found = scanPromoted('''
@Promoted()
class A { const A({super.key, required this.id}); final int id; }''');
    expect(found.single.$1, 'A');
    expect(found.single.$2['kind'], 'class');
  });

  // What `promote` writes must pass the check, so the generated code of every
  // artifact kind is promoted unchanged.
  for (final fixture in ['crud_full', 'parent_chain', 'entity_screens']) {
    test('the generated code of $fixture passes the check', () async {
      final source =
          File('test/snapshots/fixtures/$fixture.dart').readAsStringSync();
      final sources = {
        ...prefabSources,
        'a|lib/$fixture.dart': source,
        'a|lib/$fixture.prefab_declarations.json': File(
                'test/snapshots/fixtures/$fixture.prefab_declarations.json')
            .let((f) => f.existsSync() ? f.readAsStringSync() : '{}'),
      };
      String? generated;
      await testBuilder(
        prefabBuilder(BuilderOptions.empty),
        sources,
        generateFor: {'a|lib/$fixture.dart'},
        outputs: {
          'a|lib/$fixture.prefab.dart': decodedMatches(predicate<String>((s) {
            generated = s;
            return true;
          }, 'captured')),
        },
      );
      final annotated = generated!.replaceAllMapped(
          RegExp(
              r'^((?:class \w+(?:Screen|ApiClient)\b|final \w+Provider\b|List<RouteBase> get ).*)$',
              multiLine: true),
          (m) => '@Promoted()\n${m[1]}');
      final found = scanPromoted(annotated);
      expect(found, isNotEmpty);
      final severe = <String>[];
      await testBuilder(
        prefabBuilder(BuilderOptions.empty),
        {
          ...sources,
          'a|lib/p.prefab_declarations.json': jsonEncode({
            'promoted': [
              for (final (name, shape) in found)
                {'name': name, 'uri': 'package:a/p.dart', 'shape': shape},
            ],
          }),
        },
        generateFor: {'a|lib/$fixture.dart'},
        onLog: (r) {
          if (r.level >= Level.SEVERE) severe.add(r.message);
        },
      );
      expect(severe, isEmpty);
    });
  }
}

extension _Let<T> on T {
  R let<R>(R Function(T) f) => f(this);
}
