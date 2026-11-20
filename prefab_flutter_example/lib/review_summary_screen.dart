import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:prefab_flutter/prefab_flutter.dart';

import 'review.dart';
import 'review.prefab.dart';

/// A hand-written screen below a review (`/products/:productId/reviews/:id/summary`).
/// The generated routes pass the review id and the id of its product, the
/// review's detail screen links to it, and `reviewBreadcrumbs` draws the same
/// breadcrumb bar as the generated screens.
@EntityScreen(Review, path: 'summary', title: 'Summary')
class ReviewSummaryScreen extends ConsumerWidget {
  final int id;
  final int productId;

  const ReviewSummaryScreen(
      {super.key, required this.id, required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final review = ref.watch(reviewDetailProvider((id, productId)));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review summary'),
        bottom: reviewBreadcrumbs(context, ref,
            title: 'Summary', id: id, productId: productId),
      ),
      body: Center(
        child: Text(review.valueOrNull?.comment ?? '…'),
      ),
    );
  }
}
