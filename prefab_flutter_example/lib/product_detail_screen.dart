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
      appBar: AppBar(title: const Text('Product (hand-written)')),
      body: product.when(
        data: (p) => ListTile(title: Text(p.name), subtitle: Text('${p.price}')),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }
}
