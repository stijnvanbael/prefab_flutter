import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'prefab_api_error.dart';
import 'dart:convert';

import 'prefab_event.dart';
import 'prefab_page.dart';

/// How the sort field and direction are written into the `sort` parameter.
enum PrefabSortFormat {
  /// `price` or `-price` (descending).
  minusPrefix,

  /// `price,asc` or `price,desc` (Spring Data).
  commaDirection,
}

/// How an update carries the version of an optimistically locked entity
/// (`@Version`).
enum PrefabVersionTransport {
  /// As the version field of the JSON body (the entity's own `toJson`).
  body,

  /// As the `If-Match` header; the version field is left out of the body.
  ifMatch,
}

/// A filter on a date field: both ends are inclusive and either may be open.
class PrefabDateRange {
  const PrefabDateRange({this.start, this.end});

  /// First day of the range, or `null` for no lower bound.
  final DateTime? start;

  /// Last day of the range, or `null` for no upper bound.
  final DateTime? end;

  @override
  bool operator ==(Object other) =>
      other is PrefabDateRange && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);
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
/// * ids (`Reference<T>` strings or numbers) are URL-encoded path segments;
/// * named operations are `POST {collection}/{id}/{operation}` with the
///   parameters as the JSON body.
///
/// Filters (`@Field(filterable: true)`) are sent as one parameter per field,
/// named by the field's JSON name (`category=office`, `inStock=true`); a
/// [PrefabDateRange] becomes `releasedOnFrom` and `releasedOnTo`
/// (`yyyy-MM-dd`). Text filters offer suggestions only when
/// [autocompletePath] is set: `GET {collection}/{autocompletePath}?field=name&q=ke`
/// answers a JSON array of strings (or an object with the array under
/// [itemsKey]).
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
/// Updates of an entity with a `@Version` send the version in the body (the
/// Prefab preset, [PrefabVersionTransport.body]) or in the `If-Match` header
/// ([versionTransport]); a stale version is answered with `409 Conflict`.
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

  /// Where updates carry the version of a `@Version` entity.
  final PrefabVersionTransport versionTransport;

  /// HTTP method of a named operation (`@Update(path: ...)`), sent to
  /// `{collection}/{id}/{operation}`.
  final String operationMethod;

  /// Prepended to the name of every filter parameter (`filter.` gives
  /// `filter.category=office`).
  final String filterPrefix;

  /// Appended to a date filter's name for the lower bound.
  final String filterFromSuffix;

  /// Appended to a date filter's name for the upper bound.
  final String filterToSuffix;

  /// Path below the collection of the autocomplete endpoint for text
  /// filters, e.g. `autocomplete`. `null` (the default) means the backend has
  /// none and text filters show no suggestions.
  final String? autocompletePath;

  /// Query parameter of the autocomplete request naming the field.
  final String autocompleteFieldParam;
  /// Path segment appended to the collection URL to open the event stream of
  /// a `@Streaming` entity (`/products` -> `/products/stream`).
  final String streamPath;

  /// SSE event names of the three event types.
  final String createdEvent;
  final String updatedEvent;
  final String deletedEvent;

  /// Whether the event stream replays the events missed while disconnected
  /// when a reconnect sends the `Last-Event-ID` header (the `id:` of the last
  /// event received). Then lists and details are not reloaded after a
  /// reconnect that has such an id; otherwise they always are.
  final bool resumeWithLastEventId;

  /// The Prefab preset (see the class documentation).
  const PrefabBackend({
    this.versionTransport = PrefabVersionTransport.body,
    this.operationMethod = 'POST',
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
    this.filterPrefix = '',
    this.filterFromSuffix = 'From',
    this.filterToSuffix = 'To',
    this.autocompletePath,
    this.autocompleteFieldParam = 'field',
    this.streamPath = 'stream',
    this.createdEvent = 'created',
    this.updatedEvent = 'updated',
    this.deletedEvent = 'deleted',
    this.resumeWithLastEventId = false,
  });

  /// The Simple preset: `sort=-field` and `{ "items": [...], "total": n }`.
  const PrefabBackend.simple({
    this.versionTransport = PrefabVersionTransport.body,
    this.operationMethod = 'POST',
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
    this.filterPrefix = '',
    this.filterFromSuffix = 'From',
    this.filterToSuffix = 'To',
    this.autocompletePath,
    this.autocompleteFieldParam = 'field',
    this.streamPath = 'stream',
    this.createdEvent = 'created',
    this.updatedEvent = 'updated',
    this.deletedEvent = 'deleted',
    this.resumeWithLastEventId = false,
  });

  /// The URL of the event stream of the collection at [collectionUrl].
  String eventsUrl(String collectionUrl) => '$collectionUrl/$streamPath';

  /// Converts one server-sent event into a [PrefabEvent], or `null` for
  /// events that are not created, updated or deleted (heartbeats, unknown
  /// names) and for data that is not a JSON object.
  PrefabEvent? parseEvent(String? eventName, String data) {
    final PrefabEventType type;
    if (eventName == createdEvent) {
      type = PrefabEventType.created;
    } else if (eventName == updatedEvent) {
      type = PrefabEventType.updated;
    } else if (eventName == deletedEvent) {
      type = PrefabEventType.deleted;
    } else {
      return null;
    }
    try {
      final json = jsonDecode(data);
      return json is Map<String, dynamic> ? PrefabEvent(type, json) : null;
    } on FormatException {
      return null;
    }
  }

  /// Builds the query parameters for a list request. Empty search and absent
  /// sort/page values are left out, as are [filters] without a value. A `null`
  /// [page] requests an unpaged list. [filters] maps JSON field names to a
  /// `String`, `bool`, enum name or [PrefabDateRange].
  Map<String, dynamic> queryParameters({
    String? search,
    Map<String, Object?> filters = const {},
    String? sort,
    bool descending = false,
    int? page,
    int? pageSize,
  }) {
    return {
      if (search != null && search.isNotEmpty) searchParam: search,
      ...encodeFilters(filters),
      if (sort != null) sortParam: encodeSort(sort, descending),
      if (page != null) ...{
        pageParam: page,
        sizeParam: pageSize ?? defaultPageSize,
      },
    };
  }

  /// Encodes the filter values as query parameters (see the class
  /// documentation).
  Map<String, String> encodeFilters(Map<String, Object?> filters) {
    final result = <String, String>{};
    filters.forEach((field, value) {
      final name = '$filterPrefix$field';
      if (value == null) return;
      if (value is PrefabDateRange) {
        if (value.start != null) {
          result['$name$filterFromSuffix'] = _date(value.start!);
        }
        if (value.end != null) result['$name$filterToSuffix'] = _date(value.end!);
      } else if ('$value'.isNotEmpty) {
        result[name] = '$value';
      }
    });
    return result;
  }

  static String _date(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  /// The URL of the autocomplete endpoint below [collectionUrl], or `null`
  /// when the backend has none.
  String? autocompleteUrl(String collectionUrl) =>
      autocompletePath == null ? null : '$collectionUrl/$autocompletePath';

  /// Query parameters of an autocomplete request for [field] and [text].
  Map<String, dynamic> autocompleteQueryParameters(String field, String text) =>
      {autocompleteFieldParam: field, searchParam: text};

  /// Reads the suggestions from an autocomplete response.
  List<String> parseSuggestions(Object? data) {
    final raw = data is Map ? data[itemsKey] : data;
    return raw is List ? [for (final e in raw) '$e'] : const [];
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

  /// The body of an update: [json] as it is, or without [versionKey] when the
  /// version travels in a header.
  Map<String, dynamic> updateBody(
    Map<String, dynamic> json, {
    String? versionKey,
  }) {
    if (versionKey == null ||
        versionTransport != PrefabVersionTransport.ifMatch) {
      return json;
    }
    return {...json}..remove(versionKey);
  }

  /// The request options of an update: the `If-Match` header carrying
  /// [version] when the version travels in a header, otherwise `null`.
  Options? updateOptions(Object? version) {
    if (version == null || versionTransport != PrefabVersionTransport.ifMatch) {
      return null;
    }
    return Options(headers: {'If-Match': '"$version"'});
  }

  /// The request body of a named operation, from the JSON of its parameters
  /// (`null` for an operation without parameters). Both presets send the
  /// parameters as they are; override to wrap them.
  Object? operationBody(Map<String, dynamic>? parameters) => parameters;

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
