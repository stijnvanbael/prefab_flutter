// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// PrefabGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
//
// ignore_for_file: curly_braces_in_flow_control_structures, deprecated_member_use
// **************************************************************************
// PrefabGenerator
// **************************************************************************

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:prefab_flutter_widgets/prefab_flutter_widgets.dart';

import 'dart:async';
import 'list_filters.dart';

class NovelApiClient {
  final Dio _dio;
  final PrefabBackend _adapter;

  NovelApiClient(this._dio, [this._adapter = const PrefabBackend()]);

  Future<PrefabPage<Novel>> list(
      {String? search,
      String? sort,
      Map<String, Object?> filters = const {},
      bool descending = false,
      int page = 0,
      int? pageSize}) async {
    final response = await _dio.get(
      '/novels',
      queryParameters: _adapter.queryParameters(
        search: search,
        sort: sort,
        filters: filters,
        descending: descending,
      ),
    );
    return _adapter.parsePage(
      response.data,
      Novel.fromJson,
    );
  }

  Future<Novel> getById(int id) async {
    final response = await _dio.get('/novels/${_adapter.encodeId(id)}');
    return Novel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> delete(Novel novel) async {
    await _dio.delete('/novels/${_adapter.encodeId(novel.id)}');
  }

  /// Suggestions for the text filter on [field]; empty when the
  /// backend adapter has no autocomplete endpoint.
  Future<List<String>> autocomplete(String field, String text) async {
    final path = _adapter.autocompleteUrl('/novels');
    if (path == null) return const [];
    final response = await _dio.get(
      path,
      queryParameters: _adapter.autocompleteQueryParameters(field, text),
    );
    return _adapter.parseSuggestions(response.data);
  }
}

final novelDetailProvider = FutureProvider.autoDispose.family<Novel, int>(
    (ref, id) => ref.watch(novelApiClientProvider).getById(id));

final novelsProvider =
    AsyncNotifierProvider.autoDispose<NovelsNotifier, PrefabPage<Novel>>(
        NovelsNotifier.new);

class NovelsNotifier extends AutoDisposeAsyncNotifier<PrefabPage<Novel>> {
  NovelApiClient get _client => ref.read(novelApiClientProvider);

  String _search = '';
  String? _sort;
  bool _descending = false;
  int _page = 0;
  Timer? _searchDebounce;

  /// The search text currently applied to the list.
  String get search => _search;

  /// The field the list is sorted by, or `null`.
  String? get sort => _sort;

  /// Whether the list is sorted descending.
  bool get descending => _descending;

  /// Zero-based index of the current page.
  int get page => _page;
  final Map<String, Object?> _filters = {};

  /// The filter values currently applied, by JSON field name.
  Map<String, Object?> get filters => Map.unmodifiable(_filters);

  @override
  Future<PrefabPage<Novel>> build() {
    ref.onDispose(() => _searchDebounce?.cancel());
    return _client.list(
        search: _search,
        sort: _sort,
        filters: _filters,
        descending: _descending);
  }

  Future<void> _load() async {
    state = const AsyncLoading<PrefabPage<Novel>>().copyWithPrevious(state);
    state = await AsyncValue.guard(() => _client.list(
        search: _search,
        sort: _sort,
        filters: _filters,
        descending: _descending));
  }

  /// Applies [query] after a short pause in typing and
  /// returns to the first page.
  void setSearch(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (query == _search) return;
      _search = query;
      _page = 0;
      _load();
    });
  }

  /// Sorts by [field] (`null` clears the sort) and reloads.
  Future<void> setSort(String? field, {bool descending = false}) {
    _sort = field;
    _descending = descending;
    _page = 0;
    return _load();
  }

  /// Sets the filter on [field] (a JSON field name; `null` or an empty text
  /// clears it), returns to the first page and reloads.
  Future<void> setFilter(String field, Object? value) {
    if (value == null || value == '') {
      _filters.remove(field);
    } else {
      _filters[field] = value;
    }
    _page = 0;
    return _load();
  }

  /// Clears every filter and reloads.
  Future<void> clearFilters() {
    _filters.clear();
    _page = 0;
    return _load();
  }

  /// Suggestions for the text filter on [field] from the backend.
  Future<List<String>> suggest(String field, String text) =>
      _client.autocomplete(field, text);
}

final novelApiClientProvider = Provider.autoDispose<NovelApiClient>((ref) =>
    NovelApiClient(
        ref.watch(prefabDioProvider), ref.watch(prefabBackendProvider)));

class NovelDetailScreen extends ConsumerWidget {
  final int id;

  const NovelDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final novelAsync = ref.watch(novelDetailProvider(id));
    final prefabTheme = PrefabTheme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Novel'),
      ),
      body: novelAsync.when(
        data: (novel) => ListView(
          padding: prefabTheme.detailPadding,
          children: [
            prefabTheme.detailFieldBuilder(
              context,
              'Title',
              Text(novel.title.toString()),
            ),
            prefabTheme.detailFieldBuilder(
              context,
              'Genre',
              Text(novel.genre?.toString() ?? '—'),
            ),
            prefabTheme.detailFieldBuilder(
              context,
              'Published',
              Text(novel.published.toString()),
            ),
            prefabTheme.detailFieldBuilder(
              context,
              'Released On',
              Text(novel.releasedOn?.toString() ?? '—'),
            ),
          ],
        ),
        loading: () => prefabTheme.loadingBuilder(context),
        error: (error, stackTrace) => ref
                .read(prefabBackendProvider)
                .parseError(error)
                .isNotFound
            ? prefabTheme.notFoundBuilder(context, () => context.go('/novels'))
            : prefabTheme.errorBuilder(context, error, stackTrace),
      ),
    );
  }
}

class NovelListScreen extends ConsumerWidget {
  const NovelListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final novelsAsync = ref.watch(novelsProvider);
    final notifier = ref.read(novelsProvider.notifier);
    final filterNotifier = ref.read(novelsProvider.notifier);
    final prefabTheme = PrefabTheme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Novel'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: PrefabSearchBar(
              initialValue: notifier.search,
              onChanged: notifier.setSearch,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Wrap(
              spacing: 16,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                PrefabTextFilter(
                  label: 'Title',
                  initialValue:
                      (filterNotifier.filters['title'] as String?) ?? '',
                  onChanged: (value) =>
                      filterNotifier.setFilter('title', value),
                  suggest: (text) => filterNotifier.suggest('title', text),
                ),
                PrefabEnumFilter(
                  label: 'Genre',
                  options: [
                    for (final v in Genre.values)
                      PrefabFilterOption(value: v.name, label: v.name),
                  ],
                  selected: filterNotifier.filters['genre'] as String?,
                  onChanged: (value) =>
                      filterNotifier.setFilter('genre', value),
                ),
                PrefabBoolFilter(
                  label: 'Published',
                  value: filterNotifier.filters['published'] as bool?,
                  onChanged: (value) =>
                      filterNotifier.setFilter('published', value),
                ),
                PrefabDateRangeFilter(
                  label: 'Released On',
                  value:
                      filterNotifier.filters['releasedOn'] as PrefabDateRange?,
                  onChanged: (value) =>
                      filterNotifier.setFilter('releasedOn', value),
                ),
              ],
            ),
          ),
          Expanded(
            child: novelsAsync.when(
              skipLoadingOnReload: true,
              data: (page) => page.items.isEmpty
                  ? prefabTheme.emptyBuilder(context)
                  : ListView.builder(
                      padding: prefabTheme.listPadding,
                      itemCount: page.items.length,
                      itemBuilder: (context, index) {
                        final novel = page.items[index];
                        return prefabTheme.listItemBuilder(
                          context,
                          title: Text(novel.title.toString()),
                          subtitle: null,
                          trailing: null,
                          actions: const [],
                          onTap: () => context.push('/novels/${novel.id}'),
                        );
                      },
                    ),
              loading: () => prefabTheme.loadingBuilder(context),
              error: (error, stackTrace) =>
                  prefabTheme.errorBuilder(context, error, stackTrace),
            ),
          ),
        ],
      ),
    );
  }
}

List<RouteBase> get $listFiltersRoutes => [
      GoRoute(
        path: '/novels',
        builder: (context, state) => const NovelListScreen(),
        routes: [
          GoRoute(
            path: ':id',
            builder: (context, state) =>
                NovelDetailScreen(id: int.parse(state.pathParameters['id']!)),
          ),
        ],
      ),
    ];
