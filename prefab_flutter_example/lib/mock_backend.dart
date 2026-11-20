import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:prefab_flutter_widgets/prefab_flutter_widgets.dart';

/// The backend adapter the example app uses: the Prefab preset plus an
/// autocomplete endpoint for the text filters. Switch to `PrefabBackend.simple()` (and change [MockBackendAdapter]
/// to answer `{items, total}` and `sort=-field`) for a plain backend.
const exampleBackend = PrefabBackend(autocompletePath: 'autocomplete');

/// An in-memory REST backend that implements the contract expected by the
/// generated API clients (`/products`, `/products/{productId}/reviews` and
/// `/products/{productId}/reviews/{reviewId}/replies`).
class MockBackendAdapter implements HttpClientAdapter {
  final Map<String, List<Map<String, dynamic>>> _tables = {
    'products': [
      {
        'id': 1,
        'version': 0,
        'name': 'Keyboard',
        'price': 49.9,
        'inStock': true,
        'createdAt': '2024-01-15T09:00:00.000',
        'category': 'accessories',
        'description': 'Mechanical keyboard with tactile switches.',
        'releasedOn': '2024-03-01T00:00:00.000',
      },
      {
        'id': 2,
        'version': 0,
        'name': 'Monitor',
        'price': 199.0,
        'inStock': false,
        'createdAt': '2024-02-01T09:00:00.000',
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

  /// The open `/products/stream` connections. Every change of a product is
  /// sent to them as a server-sent event, as a `@Streaming` Prefab backend
  /// does.
  var _productEvents = StreamController<List<int>>.broadcast();

  /// Sends a server-sent event to every open product stream, as if another
  /// client had changed a product: [name] is `created`, `updated` or
  /// `deleted`, [data] the product JSON.
  void emitProductEvent(String name, Map<String, dynamic> data) =>
      _productEvents
          .add(utf8.encode('event: $name\ndata: ${jsonEncode(data)}\n\n'));

  /// Ends every open product stream, as a lost network connection does. The
  /// client reconnects with backoff; events emitted while no stream is open
  /// are lost.
  void dropProductStreams() {
    _productEvents.close();
    _productEvents = StreamController<List<int>>.broadcast();
  }

  /// Changes fields of a product without sending an event, as if it happened
  /// while the client was disconnected.
  void changeProductSilently(int id, Map<String, dynamic> fields) {
    final row = _tables['products']!.firstWhere((r) => r['id'] == id);
    row.addAll(fields);
  }

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

    if (options.method == 'GET' && options.uri.path == '/products/stream') {
      return ResponseBody(
        _productEvents.stream.map(Uint8List.fromList),
        200,
        headers: {
          Headers.contentTypeHeader: ['text/event-stream'],
        },
      );
    }

    // Resolve to a table key and optional id. Paths alternate collection and
    // id segments: /products/1/reviews/2/replies/3.
    const collections = {'products', 'reviews', 'replies'};
    // Named operations (PF-54): POST /products/{id}/{operation}.
    if (parts.length == 3 &&
        parts[0] == 'products' &&
        !collections.contains(parts[2])) {
      return _operation(parts[1], parts[2], body);
    }
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
        if (id == 'autocomplete') {
          // Suggestions for a text filter: the distinct values of `field`
          // that contain `q`.
          final field = '${options.queryParameters['field']}';
          final q = '${options.queryParameters['q'] ?? ''}'.toLowerCase();
          return _json(200, {
            for (final r in rows)
              if (r[field] is String &&
                  (r[field] as String).toLowerCase().contains(q))
                r[field] as String,
          }.toList());
        }
        if (id == null) return _json(200, _list(rows, options.queryParameters));
        final row = _find(rows, id);
        return row == null ? _json(404, {}) : _json(200, row);
      case 'POST':
        final invalid =
            table == 'products' ? _validateProduct(rows, body) : null;
        if (invalid != null) return invalid;
        final row = Map<String, dynamic>.from(body as Map)..['id'] = _nextId++;
        // Server-set fields (PF-53): the create request does not carry them.
        if (table == 'products') {
          row['createdAt'] = DateTime.now().toIso8601String();
        }
        if (table == 'products') row['version'] = 0;
        // The parent id field of the created row, named after the parent.
        if (parts.length >= 3) {
          final parentField = parts[parts.length - 3] == 'products'
              ? 'productId'
              : 'reviewId';
          row[parentField] = int.parse(parts[parts.length - 2]);
        }
        rows.add(row);
        if (table == 'products') emitProductEvent('created', row);
        return _json(201, row);
      case 'PUT':
        final invalid =
            table == 'products' ? _validateProduct(rows, body, id: id) : null;
        if (invalid != null) return invalid;
        final index = rows.indexWhere((r) => '${r['id']}' == id);
        if (index < 0) return _json(404, {});
        // Optimistic locking of products: an outdated version is a conflict.
        final current = rows[index]['version'];
        if (current != null && (body as Map)['version'] != current) {
          return _json(409, {
            'type': 'about:blank',
            'title': 'Conflict',
            'status': 409,
            'detail': 'The product was changed by someone else.',
          });
        }
        final row = {...rows[index], ...Map<String, dynamic>.from(body as Map)}
          ..['id'] = rows[index]['id']
          ..['version'] = current == null ? null : (current as int) + 1;
        rows[index] = row;
        if (table == 'products') emitProductEvent('updated', row);
        return _json(200, row);
      case 'DELETE':
        rows.removeWhere((r) => '${r['id']}' == id);
        if (table == 'products') {
          emitProductEvent('deleted', {'id': int.parse(id!)});
        }
        return _json(204, {});
    }
    return _json(405, {});
  }

  /// `POST /products/{id}/discontinue` takes the product out of stock;
  /// `POST /products/{id}/discount` (body `{percent, reason}`) lowers the
  /// price, up to 90 percent.
  ResponseBody _operation(String id, String operation, Object? body) {
    final row = _find(_tables['products']!, id);
    if (row == null) return _json(404, {'detail': 'Product not found'});
    switch (operation) {
      case 'discontinue':
        if (row['inStock'] == false) {
          return _json(409, {
            'title': 'Conflict',
            'status': 409,
            'detail': 'The product is already out of stock.',
          });
        }
        row['inStock'] = false;
        return _json(200, row);
      case 'discount':
        final percent = (body as Map)['percent'] as int;
        if (percent > 50 && (row['price'] as num) > 100) {
          return _json(422, {
            'title': 'Invalid request',
            'status': 422,
            'detail': 'The discount is too high.',
            'errors': [
              {
                'field': 'percent',
                'message': 'Expensive products take at most 50 percent',
              },
            ],
          });
        }
        row['price'] = (row['price'] as num) * (100 - percent) / 100;
        return _json(200, row);
    }
    return _json(404, {});
  }

  /// Server-side validation of a product, answered as RFC 9457 Problem
  /// Details in the format of the Prefab preset of `PrefabBackend`: a name
  /// that is already taken is an error of the `name` field, a price above
  /// 10000 an error of `price` plus one of `warehouse`, which the form does
  /// not have (so it appears above the form).
  ResponseBody? _validateProduct(
    List<Map<String, dynamic>> rows,
    Object? body, {
    String? id,
  }) {
    final product = body as Map;
    final errors = <Map<String, String>>[];
    final name = '${product['name']}'.toLowerCase();
    if (rows.any(
      (r) => '${r['name']}'.toLowerCase() == name && '${r['id']}' != id,
    )) {
      errors.add({
        'field': 'name',
        'message': 'A product with this name already exists',
      });
    }
    if (((product['price'] as num?) ?? 0) > 10000) {
      errors.add({'field': 'price', 'message': 'Must not exceed 10000'});
      errors.add({
        'field': 'warehouse',
        'message': 'No capacity for this product',
      });
    }
    if (errors.isEmpty) return null;
    return _json(422, {
      'type': 'about:blank',
      'title': 'Invalid request',
      'status': 422,
      'detail': 'The product is invalid.',
      'errors': errors,
    });
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
    // Filters: `field=value` for text, enum and bool values, and
    // `fieldFrom` / `fieldTo` (yyyy-MM-dd) for dates.
    for (final entry in query.entries) {
      final key = entry.key;
      if (const {'q', 'sort', 'page', 'size', 'field'}.contains(key)) continue;
      final value = '${entry.value}';
      if (key.endsWith('From') || key.endsWith('To')) {
        final isFrom = key.endsWith('From');
        final field = key.substring(0, key.length - (isFrom ? 4 : 2));
        result = result.where((r) {
          final date = r[field] as String?;
          if (date == null) return false;
          final day = date.substring(0, 10);
          return isFrom ? day.compareTo(value) >= 0 : day.compareTo(value) <= 0;
        }).toList();
      } else {
        result = result.where((r) {
          final v = r[key];
          return v is String
              ? v.toLowerCase().contains(value.toLowerCase())
              : '$v' == value;
        }).toList();
      }
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

/// Creates a [Dio] instance wired to the in-memory backend. Pass [adapter] to
/// keep a handle on the backend, e.g. to emit live events in a test.
Dio createMockDio([MockBackendAdapter? adapter]) =>
    Dio(BaseOptions(baseUrl: 'http://mock.local'))
      ..httpClientAdapter = adapter ?? MockBackendAdapter();
