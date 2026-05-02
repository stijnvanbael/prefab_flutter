import 'package:flutter/foundation.dart';

/// Carries one page of items together with pagination metadata.
///
/// [T] is the item type returned by the data source.
class PrefabPage<T> {
  /// The items on the current page.
  final List<T> items;

  /// Total number of items across all pages.
  final int totalItems;

  /// Zero-based index of the current page.
  final int page;

  /// Maximum number of items per page.
  final int pageSize;

  const PrefabPage({
    required this.items,
    required this.totalItems,
    required this.page,
    required this.pageSize,
  });

  /// Total number of pages, rounded up.
  int get totalPages => pageSize > 0 ? (totalItems / pageSize).ceil() : 0;

  /// Whether a previous page exists.
  bool get hasPreviousPage => page > 0;

  /// Whether a next page exists.
  bool get hasNextPage => page < totalPages - 1;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PrefabPage<T> &&
          runtimeType == other.runtimeType &&
          listEquals(items, other.items) &&
          totalItems == other.totalItems &&
          page == other.page &&
          pageSize == other.pageSize;

  @override
  int get hashCode => Object.hash(items, totalItems, page, pageSize);
}

/// A [ChangeNotifier] that holds the current page index and page size,
/// used to drive [PrefabPaginationBar] and data fetch calls.
class PrefabPageNotifier extends ChangeNotifier {
  int _page;
  int _pageSize;

  PrefabPageNotifier({int page = 0, int pageSize = 20})
      : _page = page,
        _pageSize = pageSize;

  /// Zero-based current page index.
  int get page => _page;

  /// Items per page.
  int get pageSize => _pageSize;

  /// Navigate to a specific page (no-op if already on that page).
  void goToPage(int page) {
    if (page == _page) return;
    _page = page;
    notifyListeners();
  }

  /// Navigate to the next page.
  void nextPage() => goToPage(_page + 1);

  /// Navigate to the previous page.
  void previousPage() {
    if (_page > 0) goToPage(_page - 1);
  }

  /// Update the page size and reset to page 0.
  void setPageSize(int pageSize) {
    _pageSize = pageSize;
    _page = 0;
    notifyListeners();
  }
}
