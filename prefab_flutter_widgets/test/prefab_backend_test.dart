import 'package:flutter_test/flutter_test.dart';
import 'package:prefab_flutter_widgets/prefab_flutter_widgets.dart';

Map<String, dynamic> _fromJson(Map<String, dynamic> j) => j;

void main() {
  group('PrefabBackend (Prefab preset)', () {
    const backend = PrefabBackend();

    test('encodes sort as field,direction', () {
      expect(
        backend.queryParameters(
          search: 'tea',
          sort: 'unitPrice',
          descending: true,
          page: 2,
          pageSize: 10,
        ),
        {'q': 'tea', 'sort': 'unitPrice,desc', 'page': 2, 'size': 10},
      );
      expect(backend.queryParameters(sort: 'name'), {'sort': 'name,asc'});
      expect(backend.queryParameters(search: ''), isEmpty);
    });

    test('parses a recorded Spring PagedModel response', () {
      // Recorded from a Prefab backend: GET /products?page=1&size=2
      final page = backend.parsePage(
        {
          'content': [
            {'id': 'a1', 'name': 'Tea'},
            {'id': 'b2', 'name': 'Coffee'},
          ],
          'page': {'size': 2, 'number': 1, 'totalElements': 5, 'totalPages': 3},
        },
        _fromJson,
        page: 1,
        pageSize: 2,
      );
      expect(page.items.map((e) => e['id']), ['a1', 'b2']);
      expect(page.totalItems, 5);
      expect(page.page, 1);
      expect(page.totalPages, 3);
    });

    test('accepts a bare array and rejects other bodies', () {
      expect(backend.parsePage([{'id': 1}], _fromJson).totalItems, 1);
      expect(() => backend.parsePage('oops', _fromJson),
          throwsFormatException);
    });

    test('encodes ids as URL path segments', () {
      expect(backend.encodeId('ref/1 2'), 'ref%2F1%202');
      expect(backend.encodeId(42), '42');
    });
  });

  group('PrefabBackend.simple', () {
    const backend = PrefabBackend.simple();

    test('encodes sort with a minus prefix', () {
      expect(
        backend.queryParameters(sort: 'price', descending: true, page: 0),
        {'sort': '-price', 'page': 0, 'size': 20},
      );
    });

    test('parses { items, total }', () {
      final page = backend.parsePage(
        {
          'items': [{'id': 1}],
          'total': 25,
        },
        _fromJson,
        page: 1,
        pageSize: 2,
      );
      expect(page.totalItems, 25);
      expect(page.page, 1);
    });
  });

  test('names and keys are configurable', () {
    const custom = PrefabBackend(
      searchParam: 'query',
      sizeParam: 'limit',
      itemsKey: 'data',
      totalKey: 'meta.count',
      pageKey: null,
    );
    expect(custom.queryParameters(search: 'x', page: 1, pageSize: 5),
        {'query': 'x', 'page': 1, 'limit': 5});
    final page = custom.parsePage(
      {
        'data': [{'id': 1}],
        'meta': {'count': 9},
      },
      _fromJson,
      page: 0,
      pageSize: 1,
    );
    expect(page.totalItems, 9);
  });
}
