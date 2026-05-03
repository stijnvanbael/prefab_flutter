// GENERATED CODE - DO NOT MODIFY BY HAND
//
// **************************************************************************
// ProviderGenerator
// **************************************************************************

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'product.dart';
import 'product.api_client.dart';
import 'dio_provider.dart';

final productDetailProvider =
    FutureProvider.autoDispose.family<Product, Object>((ref, id) =>
        ref.watch(productApiClientProvider).getById(id));

final productsProvider = StateNotifierProvider.autoDispose<ProductsNotifier,
    AsyncValue<List<Product>>>(
  (ref) => ProductsNotifier(ref.watch(productApiClientProvider)));

class ProductsNotifier extends StateNotifier<AsyncValue<List<Product>>> {
  final ProductApiClient _client;

  ProductsNotifier(this._client) : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _client.list());
  }

  Future<void> create(Product product) async {
    await _client.create(product);
    await _load();
  }

  Future<void> update(Product product) async {
    await _client.update(product);
    await _load();
  }

  Future<void> delete(Product product) async {
    await _client.delete(product);
    await _load();
  }
}

final productApiClientProvider = Provider.autoDispose<ProductApiClient>(
  (ref) => ProductApiClient(ref.watch(dioProvider)));
