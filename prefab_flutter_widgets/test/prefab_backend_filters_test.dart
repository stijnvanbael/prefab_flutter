import 'package:flutter_test/flutter_test.dart';
import 'package:prefab_flutter_widgets/prefab_flutter_widgets.dart';

void main() {
  test('PF-55 AC#2 filters become query parameters', () {
    final params = const PrefabBackend().queryParameters(filters: {
      'category': 'office',
      'inStock': true,
      'name': '',
      'releasedOn':
          PrefabDateRange(start: DateTime(2024, 1, 5), end: DateTime(2024, 12, 31)),
      'open': const PrefabDateRange(start: null, end: null),
    });
    expect(params, {
      'category': 'office',
      'inStock': 'true',
      'releasedOnFrom': '2024-01-05',
      'releasedOnTo': '2024-12-31',
    });
    expect(
      const PrefabBackend(filterPrefix: 'filter.')
          .queryParameters(filters: {'a': 'b'}),
      {'filter.a': 'b'},
    );
  });

  test('PF-55 AC#3 autocomplete exists only when the adapter defines it', () {
    expect(const PrefabBackend().autocompleteUrl('/p'), isNull);
    const backend = PrefabBackend(autocompletePath: 'autocomplete');
    expect(backend.autocompleteUrl('/p'), '/p/autocomplete');
    expect(backend.autocompleteQueryParameters('name', 'ke'),
        {'field': 'name', 'q': 'ke'});
    expect(backend.parseSuggestions(['a', 'b']), ['a', 'b']);
    expect(backend.parseSuggestions({'content': ['c']}), ['c']);
    expect(backend.parseSuggestions(null), isEmpty);
  });
}
