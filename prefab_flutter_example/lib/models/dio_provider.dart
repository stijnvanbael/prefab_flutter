import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'product.dart';

/// Provides a [Dio] instance pre-configured with an in-memory interceptor so
/// the example app works without a real backend.
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(baseUrl: 'http://localhost'));
  dio.interceptors.add(_InMemoryProductInterceptor());
  return dio;
});

/// A Dio [Interceptor] that intercepts HTTP calls and serves product data from
/// an in-memory store, returning real [Product] objects so the generated API
/// client casts (`response.data as Product`) work correctly.
class _InMemoryProductInterceptor extends Interceptor {
  static final Map<int, Product> _store = {
    1: const Product(
      id: 1,
      name: 'Widget A',
      price: 9.99,
      description: 'A basic widget',
    ),
    2: const Product(
      id: 2,
      name: 'Widget B',
      price: 19.99,
      description: 'An advanced widget',
    ),
    3: const Product(
      id: 3,
      name: 'Gadget Pro',
      price: 49.99,
      description: 'A premium gadget',
    ),
  };

  static int _nextId = 4;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    final method = options.method.toUpperCase();
    final segments = options.path
        .split('/')
        .where((s) => s.isNotEmpty)
        .toList();

    if (segments.isEmpty || segments.first != 'products') {
      handler.next(options);
      return;
    }

    if (method == 'GET' && segments.length == 1) {
      // GET /products — return all products
      handler.resolve(Response(
        requestOptions: options,
        data: _store.values.toList(),
        statusCode: 200,
      ));
    } else if (method == 'GET' && segments.length == 2) {
      // GET /products/:id — return one product
      final id = int.tryParse(segments[1]);
      final product = id != null ? _store[id] : null;
      if (product != null) {
        handler.resolve(Response(
          requestOptions: options,
          data: product,
          statusCode: 200,
        ));
      } else {
        handler.reject(DioException(
          requestOptions: options,
          response: Response(requestOptions: options, statusCode: 404),
        ));
      }
    } else if (method == 'POST' && segments.length == 1) {
      // POST /products — create a new product
      final incoming = options.data as Product;
      final newProduct = Product(
        id: _nextId++,
        name: incoming.name,
        price: incoming.price,
        description: incoming.description,
      );
      _store[newProduct.id] = newProduct;
      handler.resolve(Response(
        requestOptions: options,
        data: newProduct,
        statusCode: 201,
      ));
    } else if (method == 'PUT' && segments.length == 2) {
      // PUT /products/:id — update an existing product
      final product = options.data as Product;
      _store[product.id] = product;
      handler.resolve(Response(
        requestOptions: options,
        data: product,
        statusCode: 200,
      ));
    } else if (method == 'DELETE' && segments.length == 2) {
      // DELETE /products/:id — remove a product
      final id = int.tryParse(segments[1]);
      if (id != null) {
        _store.remove(id);
      }
      handler.resolve(Response(
        requestOptions: options,
        data: null,
        statusCode: 204,
      ));
    } else {
      handler.next(options);
    }
  }
}
