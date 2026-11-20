import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:prefab_flutter/prefab_flutter.dart';

import 'product.dart';
import 'product.prefab.dart';
import 'review.prefab.dart';

/// The reference for hand-written code built on generated parts (PF-48).
///
/// - `@EntityScreen` makes the generator add the route
///   `/products/:id/stats` and the `productBreadcrumbs` helper.
/// - It watches generated providers: `productDetailProvider(id)` and
///   `reviewsProvider(id)` (the nested reviews of the product).
/// - It draws the generated breadcrumb bar (`PrefabBreadcrumbBar`).
@EntityScreen(Product, path: 'stats', title: 'Statistics')
class ProductStatsScreen extends ConsumerWidget {
  final int id;

  const ProductStatsScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final product = ref.watch(productDetailProvider(id));
    final reviews = ref.watch(reviewsProvider(id));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product statistics'),
        bottom: productBreadcrumbs(context, ref, title: 'Statistics', id: id),
      ),
      body: product.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (p) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(p.name, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text('Price: ${p.price.toStringAsFixed(2)} EUR'),
            Text(p.inStock ? 'In stock' : 'Out of stock'),
            const Divider(height: 32),
            reviews.when(
              loading: () => const CircularProgressIndicator(),
              error: (e, _) => Text('$e'),
              data: (page) {
                final ratings = [
                  for (final r in page.items)
                    if (r.rating != null) r.rating!
                ];
                final average = ratings.isEmpty
                    ? null
                    : ratings.reduce((a, b) => a + b) / ratings.length;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Reviews: ${page.totalItems}'),
                    Text(average == null
                        ? 'Average rating: —'
                        : 'Average rating: ${average.toStringAsFixed(1)}'),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
