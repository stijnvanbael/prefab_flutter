import 'package:material_ui/material_ui.dart';

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
  /// The notifier that holds (and mutates) the current page, or `null` for a
  /// bar created with [PrefabPaginationBar.controlled].
  final PrefabPageNotifier? notifier;

  /// Total number of pages (typically derived from [PrefabPage.totalPages]).
  final int totalPages;

  final int _page;
  final ValueChanged<int>? _onPageChanged;

  const PrefabPaginationBar({
    super.key,
    required PrefabPageNotifier this.notifier,
    required this.totalPages,
  }) : _page = 0,
       _onPageChanged = null;

  /// A bar whose state lives elsewhere (e.g. in a Riverpod notifier): it shows
  /// [page] (zero-based) and reports navigation through [onPageChanged].
  const PrefabPaginationBar.controlled({
    super.key,
    required int page,
    required this.totalPages,
    required ValueChanged<int> onPageChanged,
  }) : notifier = null,
       _page = page,
       _onPageChanged = onPageChanged;

  @override
  Widget build(BuildContext context) {
    final notifier = this.notifier;
    if (notifier == null) {
      return _bar(context, _page, _onPageChanged!);
    }
    return ListenableBuilder(
      listenable: notifier,
      builder: (context, _) => _bar(context, notifier.page, notifier.goToPage),
    );
  }

  Widget _bar(
    BuildContext context,
    int currentPage,
    ValueChanged<int> goToPage,
  ) {
    final hasPrevious = currentPage > 0;
    final hasNext = currentPage < totalPages - 1;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.first_page),
          tooltip: 'First page',
          onPressed: hasPrevious ? () => goToPage(0) : null,
        ),
        IconButton(
          icon: const Icon(Icons.chevron_left),
          tooltip: 'Previous page',
          onPressed: hasPrevious ? () => goToPage(currentPage - 1) : null,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            totalPages == 0 ? '0 / 0' : '${currentPage + 1} / $totalPages',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          tooltip: 'Next page',
          onPressed: hasNext ? () => goToPage(currentPage + 1) : null,
        ),
        IconButton(
          icon: const Icon(Icons.last_page),
          tooltip: 'Last page',
          onPressed: hasNext ? () => goToPage(totalPages - 1) : null,
        ),
      ],
    );
  }
}
