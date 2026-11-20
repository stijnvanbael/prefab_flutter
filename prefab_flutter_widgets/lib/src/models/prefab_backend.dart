import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'prefab_api_error.dart';
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
/// Error responses are RFC 9457 Problem Details; [parseError] reads the
/// message and the field errors (see [errorsKey]). The Prefab preset expects
/// `{ "detail": "...", "errors": [{ "field": "price", "message": "..." }] }`,
/// the Simple preset `{ "message": "...", "errors": { "price": "..." } }`;
/// both accept both shapes of `errors`.
///
/// Both accept a bare JSON array as a single page. Pass other names to the
/// constructor, or subclass and override [queryParameters], [parsePage],
/// [parseError] or [encodeId], and override [prefabBackendProvider] to plug in another
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

  /// Error response key holding the general message. `title` is the fallback.
  final String errorMessageKey;

  /// Error response key holding the field errors: a list of objects (field
  /// name under [errorFieldKey], text under [errorFieldMessageKey]) or an
  /// object from field name to text (or list of texts).
  final String errorsKey;

  /// Key of the field name in an entry of the [errorsKey] list.
  final String errorFieldKey;

  /// Key of the text in an entry of the [errorsKey] list.
  final String errorFieldMessageKey;

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
    this.errorMessageKey = 'detail',
    this.errorsKey = 'errors',
    this.errorFieldKey = 'field',
    this.errorFieldMessageKey = 'message',
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
    this.errorMessageKey = 'message',
    this.errorsKey = 'errors',
    this.errorFieldKey = 'field',
    this.errorFieldMessageKey = 'message',
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

  /// Converts anything thrown by a request into a [PrefabApiError]: the
  /// status and the Problem Details of a `DioException` response, or the text
  /// of any other error (no status).
  PrefabApiError parseError(Object error) {
    if (error is PrefabApiError) return error;
    if (error is DioException) {
      final response = error.response;
      final data = response?.data;
      String? message;
      var fields = <String, String>{};
      if (data is Map) {
        final raw = data[errorMessageKey] ?? data['title'];
        if (raw is String && raw.isNotEmpty) message = raw;
        fields = _parseFieldErrors(data[errorsKey]);
      } else if (data is String && data.isNotEmpty) {
        message = data;
      }
      return PrefabApiError(
        status: response?.statusCode,
        message: message ?? error.message ?? '$error',
        fieldErrors: fields,
        cause: error,
      );
    }
    return PrefabApiError(message: '$error', cause: error);
  }

  Map<String, String> _parseFieldErrors(Object? raw) {
    final result = <String, String>{};
    void add(Object? field, Object? text) {
      if (field == null || text == null) return;
      final value = text is List ? text.join('\n') : '$text';
      final key = '$field';
      result[key] = result.containsKey(key) ? '${result[key]}\n$value' : value;
    }

    if (raw is List) {
      for (final entry in raw) {
        if (entry is Map) {
          add(entry[errorFieldKey], entry[errorFieldMessageKey]);
        }
      }
    } else if (raw is Map) {
      raw.forEach(add);
    }
    return result;
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
