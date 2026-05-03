// GENERATED CODE - DO NOT MODIFY BY HAND
//
// **************************************************************************
// ApiClientGenerator
// **************************************************************************

import 'package:dio/dio.dart';

import 'product.dart';

class ProductApiClient {
  final Dio _dio;

  ProductApiClient(this._dio);

  Future<List<Product>> list() async {
    final response = await _dio.get('/products');
    return (response.data as List).map((e) => e as Product).toList();
  }

  Future<Product> getById(Object id) async {
    final response = await _dio.get('/products/$id');
    return response.data as Product;
  }

  Future<Product> create(Product product) async {
    final response = await _dio.post('/products', data: product);
    return response.data as Product;
  }

  Future<Product> update(Product product) async {
    final response = await _dio.put('/products/${product.id}', data: product);
    return response.data as Product;
  }

  Future<void> delete(Product product) async {
    await _dio.delete('/products/${product.id}');
  }
}
