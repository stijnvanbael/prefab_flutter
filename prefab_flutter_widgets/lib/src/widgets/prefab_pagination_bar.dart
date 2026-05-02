import 'package:flutter/material.dart';

import '../models/prefab_page.dart';

/// A pagination controls bar driven by a [PrefabPageNotifier].
///
/// Displays previous/next page buttons and the current page position.
/// Rebuilds automatically whenever the notifier changes.
///
/// Example:
/// ```dart
/// PrefabPaginationBar(
///   notifier: ref.read(pageNotifierProvider),
///   totalPages: page.totalPages,
/// )
/// ```
class PrefabPaginationBar extends StatelessWidget {
  /// The notifier that holds (and mutates) the current page.
  final PrefabPageNotifier notifier;

  /// Total number of pages (typically derived from [PrefabPage.totalPages]).
  final int totalPages;

  const PrefabPaginationBar({
    super.key,
    required this.notifier,
    required this.totalPages,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: notifier,
      builder: (context, _) {
        final currentPage = notifier.page;
        final hasPrevious = currentPage > 0;
        final hasNext = currentPage < totalPages - 1;

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.first_page),
              tooltip: 'First page',
              onPressed: hasPrevious ? () => notifier.goToPage(0) : null,
            ),
            IconButton(
              icon: const Icon(Icons.chevron_left),
              tooltip: 'Previous page',
              onPressed: hasPrevious ? notifier.previousPage : null,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                totalPages == 0
                    ? '0 / 0'
                    : '${currentPage + 1} / $totalPages',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              tooltip: 'Next page',
              onPressed: hasNext ? notifier.nextPage : null,
            ),
            IconButton(
              icon: const Icon(Icons.last_page),
              tooltip: 'Last page',
              onPressed:
                  hasNext ? () => notifier.goToPage(totalPages - 1) : null,
            ),
          ],
        );
      },
    );
  }
}
