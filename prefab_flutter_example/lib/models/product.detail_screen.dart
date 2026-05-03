// GENERATED CODE - DO NOT MODIFY BY HAND
//
// **************************************************************************
// DetailScreenGenerator
// **************************************************************************

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prefab_flutter_widgets/prefab_flutter_widgets.dart';

import 'product.dart';
import 'product.provider.dart';

class ProductDetailScreen extends ConsumerWidget {
  final Object id;

  const ProductDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productAsync = ref.watch(productDetailProvider(id));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit',
            onPressed: () => context.push('/products/$id/edit'),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: 'Delete',
            onPressed: productAsync.hasValue
                ? () async {
                    final product = productAsync.value!;
                    final confirmed = await showPrefabDeleteDialog(
                      context: context,
                      item: product,
                      itemLabel: product.name.toString(),
                      onDelete: () =>
                          ref.read(productsProvider.notifier).delete(product),
                    );
                    if (confirmed && context.mounted) {
                      context.pop();
                    }
                  }
                : null,
          ),
        ],
      ),
      body: productAsync.when(
        data: (product) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ListTile(
              title: const Text('Name'),
              subtitle: Text(product.name.toString()),
            ),
            ListTile(
              title: const Text('Price'),
              subtitle: Text(product.price.toString()),
            ),
            ListTile(
              title: const Text('Description'),
              subtitle: Text(product.description.toString()),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('Error: $error')),
      ),
    );
  }
}
