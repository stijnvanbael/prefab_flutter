import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'prefab_page.dart';

/// Maps the list query of a generated screen onto the REST API and the API's
/// response back onto a [PrefabPage].
///
/// The defaults implement the prefab server contract:
///
/// * query parameters `q` (search), `sort` (`field` or `-field` for
///   descending), `page` (zero-based) and `size`;
/// * a paged response `{ "items": [...], "total": n }`. A bare JSON array is
///   accepted too and is treated as a single page.
///
/// Subclass it (or pass other names to the constructor) and override
/// [prefabListAdapterProvider] to plug in a backend with a different shape.
class PrefabListAdapter {
  /// Query parameter carrying the search text.
  final String searchParam;

  /// Query parameter carrying the sort field (`-` prefix = descending).
  final String sortParam;

  /// Query parameter carrying the zero-based page index.
  final String pageParam;

  /// Query parameter carrying the page size.
  final String sizeParam;

  /// Response key holding the items of a page.
  final String itemsKey;

  /// Response key holding the total number of items.
  final String totalKey;

  /// Page size used when the caller does not pass one.
  final int defaultPageSize;

  const PrefabListAdapter({
    this.searchParam = 'q',
    this.sortParam = 'sort',
    this.pageParam = 'page',
    this.sizeParam = 'size',
    this.itemsKey = 'items',
    this.totalKey = 'total',
    this.defaultPageSize = 20,
  });

  /// Builds the query parameters for a list request. Empty search and absent
  /// sort/page values are left out. A `null` [page] requests an unpaged list.
  Map<String, dynamic> queryParameters({
    String? search,
    String? sort,
    bool descending = false,
    int? page,
    int? pageSize,
  }) {
    return {
      if (search != null && search.isNotEmpty) searchParam: search,
      if (sort != null) sortParam: descending ? '-$sort' : sort,
      if (page != null) ...{
        pageParam: page,
        sizeParam: pageSize ?? defaultPageSize,
      },
    };
  }

  /// Converts a response body into a [PrefabPage]. With a `null` [page] (an
  /// unpaged list) all items form a single page.
  PrefabPage<T> parsePage<T>(
    Object? data,
    T Function(Map<String, dynamic> json) fromJson, {
    int? page,
    int? pageSize,
  }) {
    final List rawItems;
    int? total;
    if (data is List) {
      rawItems = data;
    } else if (data is Map && data[itemsKey] is List) {
      rawItems = data[itemsKey] as List;
      final rawTotal = data[totalKey];
      if (rawTotal is num) total = rawTotal.toInt();
    } else {
      throw FormatException(
        'Unexpected list response: expected a JSON array or an object with '
        'an "$itemsKey" array and a "$totalKey" count, got '
        '${data.runtimeType}.',
      );
    }
    final items = rawItems
        .map((e) => fromJson(e as Map<String, dynamic>))
        .toList();
    return PrefabPage<T>(
      items: items,
      totalItems: total ?? items.length,
      page: page ?? 0,
      pageSize: page == null ? items.length : (pageSize ?? defaultPageSize),
    );
  }
}

/// The [PrefabListAdapter] used by every generated API client. Override it in
/// your root `ProviderScope` to adapt a backend with other parameter names or
/// another response shape.
final prefabListAdapterProvider = Provider<PrefabListAdapter>(
  (ref) => const PrefabListAdapter(),
);
