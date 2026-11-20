import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:prefab_flutter_widgets/prefab_flutter_widgets.dart';

/// The backend adapter the example app uses: the Prefab preset, which is also
/// the default. Switch to `PrefabBackend.simple()` (and change [MockBackendAdapter]
/// to answer `{items, total}` and `sort=-field`) for a plain backend.
const exampleBackend = PrefabBackend();

/// An in-memory REST backend that implements the contract expected by the
/// generated API clients (`/products`, `/products/{productId}/reviews` and
/// `/products/{productId}/reviews/{reviewId}/replies`).
class MockBackendAdapter implements HttpClientAdapter {
  final Map<String, List<Map<String, dynamic>>> _tables = {
    'products': [
      {
        'id': 1,
        'name': 'Keyboard',
        'price': 49.9,
        'inStock': true,
        'category': 'accessories',
        'description': 'Mechanical keyboard with tactile switches.',
        'releasedOn': '2024-03-01T00:00:00.000',
      },
      {
        'id': 2,
        'name': 'Monitor',
        'price': 199.0,
        'inStock': false,
        'category': 'electronics',
      },
    ],
    'products/2/reviews': [
      {'id': 10, 'productId': 2, 'comment': 'Sharp picture', 'rating': 4},
    ],
    'products/2/reviews/10/replies': [
      {'id': 20, 'reviewId': 10, 'text': 'Agreed'},
    ],
  };
  int _nextId = 100;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final segments = options.uri.pathSegments.where((s) => s.isNotEmpty);
    final parts = segments.toList();
    Object? body = options.data;
    if (body is String) body = jsonDecode(body);

    // Resolve to a table key and optional id. Paths alternate collection and
    // id segments: /products/1/reviews/2/replies/3.
    const collections = {'products', 'reviews', 'replies'};
    if (parts.isEmpty ||
        [for (var i = 0; i < parts.length; i += 2) parts[i]]
            .any((c) => !collections.contains(c)) ||
        parts[0] != 'products') {
      return _json(404, {'error': 'not found'});
    }
    final isItem = parts.length.isEven;
    final id = isItem ? parts.last : null;
    final table = (isItem ? parts.sublist(0, parts.length - 1) : parts)
        .join('/');
    final rows = _tables.putIfAbsent(table, () => []);

    switch (options.method) {
      case 'GET':
        if (id == null) return _json(200, _list(rows, options.queryParameters));
        final row = _find(rows, id);
        return row == null ? _json(404, {}) : _json(200, row);
      case 'POST':
        final row = Map<String, dynamic>.from(body as Map)..['id'] = _nextId++;
        // The parent id field of the created row, named after the parent.
        if (parts.length >= 3) {
          final parentField = parts[parts.length - 3] == 'products'
              ? 'productId'
              : 'reviewId';
          row[parentField] = int.parse(parts[parts.length - 2]);
        }
        rows.add(row);
        return _json(201, row);
      case 'PUT':
        final index = rows.indexWhere((r) => '${r['id']}' == id);
        if (index < 0) return _json(404, {});
        final row = Map<String, dynamic>.from(body as Map)
          ..['id'] = rows[index]['id'];
        rows[index] = row;
        return _json(200, row);
      case 'DELETE':
        rows.removeWhere((r) => '${r['id']}' == id);
        return _json(204, {});
    }
    return _json(405, {});
  }

  /// Applies the list contract of the Prefab preset of `PrefabBackend`: `q`
  /// (search on string values), `sort=field,asc|desc`, `page` and `size`.
  /// Answers a Spring `PagedModel` when paged and a bare array otherwise.
  Object _list(List<Map<String, dynamic>> rows, Map<String, dynamic> query) {
    var result = List<Map<String, dynamic>>.of(rows);
    final q = '${query['q'] ?? ''}'.toLowerCase();
    if (q.isNotEmpty) {
      result = result
          .where((r) => r.values
              .any((v) => v is String && v.toLowerCase().contains(q)))
          .toList();
    }
    final sort = query['sort'] as String?;
    if (sort != null) {
      final parts = sort.split(',');
      final key = parts.first;
      final desc = parts.length > 1 && parts[1] == 'desc';
      result.sort((a, b) {
        final c = (a[key] as Comparable).compareTo(b[key]);
        return desc ? -c : c;
      });
    }
    if (query['page'] == null) return result;
    final size = int.parse('${query['size']}');
    final page = int.parse('${query['page']}');
    return {
      'content': result.skip(page * size).take(size).toList(),
      'page': {
        'size': size,
        'number': page,
        'totalElements': result.length,
        'totalPages': (result.length / size).ceil(),
      },
    };
  }

  Map<String, dynamic>? _find(List<Map<String, dynamic>> rows, String id) {
    for (final r in rows) {
      if ('${r['id']}' == id) return r;
    }
    return null;
  }

  ResponseBody _json(int status, Object? data) => ResponseBody.fromString(
        jsonEncode(data),
        status,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );

  @override
  void close({bool force = false}) {}
}

/// Creates a [Dio] instance wired to the in-memory backend.
Dio createMockDio() => Dio(BaseOptions(baseUrl: 'http://mock.local'))
  ..httpClientAdapter = MockBackendAdapter();
