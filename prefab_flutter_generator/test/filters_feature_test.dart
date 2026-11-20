import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:prefab_flutter_generator/builder.dart';
import 'package:test/test.dart';

import 'support/prefab_sources.dart';

const _source = r'''
import 'package:prefab_flutter/prefab_flutter.dart';

enum Genre { novel, poetry }

@Entity(title: 'Novel', path: 'novels')
class Novel {
  final int id;
  @Field(filterable: true)
  final String title;
  @Field(filterable: true)
  final Genre? genre;
  @Field(filterable: true)
  final bool published;
  @Field(filterable: true)
  final DateTime? releasedOn;
  final String plain;
  Novel({required this.id, required this.title, this.genre,
      required this.published, this.releasedOn, required this.plain});
  factory Novel.fromJson(Map<String, dynamic> json) => throw 0;
  Map<String, dynamic> toJson() => {};
}
''';

const _noFilters = r'''
import 'package:prefab_flutter/prefab_flutter.dart';

@Entity(title: 'Plain', path: 'plains')
class Plain {
  final int id;
  @Field(searchable: true)
  final String name;
  Plain({required this.id, required this.name});
  factory Plain.fromJson(Map<String, dynamic> json) => throw 0;
  Map<String, dynamic> toJson() => {};
}
''';

Map<String, Object> _assets(String source) => {
      ...Map<String, Object>.from(prefabSources),
      'a|lib/novel.dart': source,
    };

void main() {
  test('PF-55 AC#1 - the list screen shows a control per type', () async {
    await testBuilder(
      listScreenBuilder(BuilderOptions.empty),
      _assets(_source),
      outputs: {
        'a|lib/novel.list_screen.dart': decodedMatches(allOf(
          contains('PrefabTextFilter('),
          contains("filterNotifier.suggest('title', text)"),
          contains('PrefabEnumFilter('),
          contains('for (final v in Genre.values)'),
          contains('PrefabBoolFilter('),
          contains('PrefabDateRangeFilter('),
          isNot(contains("'plain'")),
        )),
      },
    );
  });

  test('PF-55 AC#2 - the notifier keeps filters and the client sends them',
      () async {
    await testBuilder(
      providerBuilder(BuilderOptions.empty),
      _assets(_source),
      outputs: {
        'a|lib/novel.provider.dart': decodedMatches(allOf(
          contains('final Map<String, Object?> _filters = {};'),
          contains('Future<void> setFilter(String field, Object? value)'),
          contains('filters: _filters'),
          contains('Future<List<String>> suggest(String field, String text)'),
        )),
      },
    );
    await testBuilder(
      apiClientBuilder(BuilderOptions.empty),
      _assets(_source),
      outputs: {
        'a|lib/novel.api_client.dart': decodedMatches(allOf(
          contains("Map<String, Object?> filters = const {}"),
          contains('filters: filters,'),
          contains('Future<List<String>> autocomplete('),
          contains('_adapter.autocompleteUrl('),
        )),
      },
    );
  });

  test('PF-55 AC#4 - entities without filters are unchanged', () async {
    await testBuilder(
      providerBuilder(BuilderOptions.empty),
      {
        ...Map<String, Object>.from(prefabSources),
        'a|lib/plain.dart': _noFilters,
      },
      outputs: {
        'a|lib/plain.provider.dart': decodedMatches(
          allOf(isNot(contains('filters')), isNot(contains('setFilter'))),
        ),
      },
    );
  });
}
