import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:prefab_flutter/prefab_flutter.dart';

import 'product.dart';
import 'product.prefab.dart';
import 'review.dart';

/// Hand-written actions on the generated screens (`@EntityAction`).
///
/// The generated detail screen of `Product` is promoted in this example, so
/// the product actions appear on the list screen only.
@EntityAction(
  Product,
  label: 'Duplicate',
  icon: 'copy',
  on: {Place.item},
)
Future<void> duplicateProduct(
    BuildContext context, WidgetRef ref, Product product) async {
  await ref.read(productsProvider.notifier).create(Product(
      name: '${product.name} (copy)',
      price: product.price,
      inStock: product.inStock,
      createdAt: product.createdAt));
}

@EntityAction(Product, label: 'Refresh', icon: 'refresh', on: {Place.list})
void refreshProducts(BuildContext context, WidgetRef ref) =>
    ref.invalidate(productsProvider);

@EntityAction(Review, label: 'Show comment', icon: 'comment')
void showReviewComment(BuildContext context, WidgetRef ref, Review review) =>
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(review.comment)));
