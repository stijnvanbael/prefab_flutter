import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:prefab_flutter/prefab_flutter.dart';

import 'product.prefab.dart';

/// The generated detail screen, taken over as hand-written code with
/// `@Promoted()`. It keeps the generated signature (a required `id`), so the
/// generated routes and list screen use it unchanged.
@Promoted()
class ProductDetailScreen extends ConsumerWidget {
  final int id;

  const ProductDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final product = ref.watch(productDetailProvider(id));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product (hand-written)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit',
            onPressed: () => context.push('/products/$id/edit'),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: 'Delete',
            onPressed: product.hasValue
                ? () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete product?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed != true) return;
                    await ref
                        .read(productApiClientProvider)
                        .delete(product.value!);
                    ref.invalidate(productsProvider);
                    if (context.mounted) context.pop();
                  }
                : null,
          ),
        ],
      ),
      body: product.when(
        data: (p) => ListView(
          children: [
            ListTile(title: Text(p.name), subtitle: Text('${p.price}')),
            if (p.description != null) ListTile(title: Text(p.description!)),
            // Hand-written navigation to the @EntityScreen route.
            ListTile(
              leading: const Icon(Icons.bar_chart),
              title: const Text('Statistics'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/products/$id/stats'),
            ),
            ListTile(
              leading: const Icon(Icons.rate_review),
              title: const Text('Reviews'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/products/$id/reviews'),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }
}
