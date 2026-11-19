import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// An in-memory REST backend that implements the contract expected by the
/// generated API clients (`/products` and `/products/{productId}/reviews`).
class MockBackendAdapter implements HttpClientAdapter {
  final Map<String, List<Map<String, dynamic>>> _tables = {
    'products': [
      {'id': 1, 'name': 'Keyboard', 'price': 49.9, 'inStock': true},
      {'id': 2, 'name': 'Monitor', 'price': 199.0, 'inStock': false},
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

    // Resolve to a table key and optional id.
    String table;
    String? id;
    if (parts.length >= 3 && parts[0] == 'products' && parts[2] == 'reviews') {
      table = 'products/${parts[1]}/reviews';
      id = parts.length > 3 ? parts[3] : null;
    } else if (parts.isNotEmpty && parts[0] == 'products') {
      table = 'products';
      id = parts.length > 1 ? parts[1] : null;
    } else {
      return _json(404, {'error': 'not found'});
    }
    final rows = _tables.putIfAbsent(table, () => []);

    switch (options.method) {
      case 'GET':
        if (id == null) return _json(200, rows);
        final row = _find(rows, id);
        return row == null ? _json(404, {}) : _json(200, row);
      case 'POST':
        final row = Map<String, dynamic>.from(body as Map)..['id'] = _nextId++;
        if (parts.length >= 3) row['productId'] = int.parse(parts[1]);
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
