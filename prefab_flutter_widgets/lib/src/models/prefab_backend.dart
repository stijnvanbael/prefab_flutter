import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'prefab_page.dart';

/// How the sort field and direction are written into the `sort` parameter.
enum PrefabSortFormat {
  /// `price` or `-price` (descending).
  minusPrefix,

  /// `price,asc` or `price,desc` (Spring Data).
  commaDirection,
}

/// Maps the requests of generated API clients onto a REST backend and the
/// backend's responses back onto Prefab types: the list query parameters, the
/// page response shape, the sort encoding and the id encoding in URLs.
///
/// The default constructor is the **Prefab preset**, which matches a Prefab
/// (Spring) backend without configuration:
///
/// * query parameters `q` (search), `sort=field,desc`, `page` (zero-based)
///   and `size`;
/// * a Spring `PagedModel` response
///   `{ "content": [...], "page": { "totalElements": n, "number": p } }`;
/// * ids (`Reference<T>` strings or numbers) are URL-encoded path segments.
///
/// [PrefabBackend.simple] is the **Simple preset** for plain backends:
/// `sort=-field` and `{ "items": [...], "total": n }`.
///
/// Both accept a bare JSON array as a single page. Pass other names to the
/// constructor, or subclass and override [queryParameters], [parsePage] or
/// [encodeId], and override [prefabBackendProvider] to plug in another
/// backend.
class PrefabBackend {
  /// Query parameter carrying the search text.
  final String searchParam;

  /// Query parameter carrying the sort field and direction.
  final String sortParam;

  /// How [sortParam] encodes the direction.
  final PrefabSortFormat sortFormat;

  /// Query parameter carrying the zero-based page index.
  final String pageParam;

  /// Query parameter carrying the page size.
  final String sizeParam;

  /// Response key holding the items of a page.
  final String itemsKey;

  /// Response key holding the total number of items. A dotted path such as
  /// `page.totalElements` reads a nested value.
  final String totalKey;

  /// Optional response key (dotted path) holding the zero-based page index.
  /// When absent from the response, the requested page is used.
  final String? pageKey;

  /// Page size used when the caller does not pass one.
  final int defaultPageSize;

  /// The Prefab preset (see the class documentation).
  const PrefabBackend({
    this.searchParam = 'q',
    this.sortParam = 'sort',
    this.sortFormat = PrefabSortFormat.commaDirection,
    this.pageParam = 'page',
    this.sizeParam = 'size',
    this.itemsKey = 'content',
    this.totalKey = 'page.totalElements',
    this.pageKey = 'page.number',
    this.defaultPageSize = 20,
  });

  /// The Simple preset: `sort=-field` and `{ "items": [...], "total": n }`.
  const PrefabBackend.simple({
    this.searchParam = 'q',
    this.sortParam = 'sort',
    this.sortFormat = PrefabSortFormat.minusPrefix,
    this.pageParam = 'page',
    this.sizeParam = 'size',
    this.itemsKey = 'items',
    this.totalKey = 'total',
    this.pageKey,
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
      if (sort != null) sortParam: encodeSort(sort, descending),
      if (page != null) ...{
        pageParam: page,
        sizeParam: pageSize ?? defaultPageSize,
      },
    };
  }

  /// Encodes a sort field and direction as the value of [sortParam].
  String encodeSort(String field, bool descending) {
    switch (sortFormat) {
      case PrefabSortFormat.minusPrefix:
        return descending ? '-$field' : field;
      case PrefabSortFormat.commaDirection:
        return '$field,${descending ? 'desc' : 'asc'}';
    }
  }

  /// Encodes an entity id as one URL path segment.
  String encodeId(Object? id) => Uri.encodeComponent('$id');

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
    int? responsePage;
    if (data is List) {
      rawItems = data;
    } else if (data is Map && data[itemsKey] is List) {
      rawItems = data[itemsKey] as List;
      final rawTotal = _lookup(data, totalKey);
      if (rawTotal is num) total = rawTotal.toInt();
      final key = pageKey;
      final rawPage = key == null ? null : _lookup(data, key);
      if (rawPage is num) responsePage = rawPage.toInt();
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
      page: page == null ? 0 : (responsePage ?? page),
      pageSize: page == null ? items.length : (pageSize ?? defaultPageSize),
    );
  }

  static Object? _lookup(Map data, String path) {
    Object? current = data;
    for (final part in path.split('.')) {
      if (current is! Map) return null;
      current = current[part];
    }
    return current;
  }
}

/// The [PrefabBackend] used by every generated API client (the Prefab preset
/// unless overridden). Override it in your root `ProviderScope`, e.g. with
/// `PrefabBackend.simple()` or a customised backend.
final prefabBackendProvider = Provider<PrefabBackend>(
  (ref) => const PrefabBackend(),
);
