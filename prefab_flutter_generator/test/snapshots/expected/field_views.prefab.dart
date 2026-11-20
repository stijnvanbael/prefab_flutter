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
import 'field_views.dart';

class ItemApiClient {
  final Dio _dio;
  final PrefabBackend _adapter;

  ItemApiClient(this._dio, [this._adapter = const PrefabBackend()]);

  Future<PrefabPage<Item>> list(
      {String? search,
      String? sort,
      bool descending = false,
      int page = 0,
      int? pageSize}) async {
    final response = await _dio.get(
      '/items',
      queryParameters: _adapter.queryParameters(
        search: search,
        sort: sort,
        descending: descending,
        page: page,
        pageSize: pageSize,
      ),
    );
    return _adapter.parsePage(
      response.data,
      Item.fromJson,
      page: page,
      pageSize: pageSize,
    );
  }

  Future<Item> getById(int id) async {
    final response = await _dio.get('/items/${_adapter.encodeId(id)}');
    return Item.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> delete(Item item) async {
    await _dio.delete('/items/${_adapter.encodeId(item.id)}');
  }
}

final itemDetailProvider = FutureProvider.autoDispose.family<Item, int>(
    (ref, id) => ref.watch(itemApiClientProvider).getById(id));

final itemsProvider =
    AsyncNotifierProvider.autoDispose<ItemsNotifier, PrefabPage<Item>>(
        ItemsNotifier.new);

class ItemsNotifier extends AutoDisposeAsyncNotifier<PrefabPage<Item>> {
  ItemApiClient get _client => ref.read(itemApiClientProvider);

  String _search = '';
  String? _sort;
  bool _descending = false;
  int _page = 0;
  int? _pageSize;
  Timer? _searchDebounce;

  /// The search text currently applied to the list.
  String get search => _search;

  /// The field the list is sorted by, or `null`.
  String? get sort => _sort;

  /// Whether the list is sorted descending.
  bool get descending => _descending;

  /// Zero-based index of the current page.
  int get page => _page;

  @override
  Future<PrefabPage<Item>> build() {
    ref.onDispose(() => _searchDebounce?.cancel());
    return _client.list(
        search: _search,
        sort: _sort,
        descending: _descending,
        page: _page,
        pageSize: _pageSize);
  }

  Future<void> _load() async {
    state = const AsyncLoading<PrefabPage<Item>>().copyWithPrevious(state);
    state = await AsyncValue.guard(() => _client.list(
        search: _search,
        sort: _sort,
        descending: _descending,
        page: _page,
        pageSize: _pageSize));
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

  /// Loads the zero-based page [page].
  Future<void> goToPage(int page) {
    _page = page;
    return _load();
  }

  /// Changes the page size and returns to the first page.
  Future<void> setPageSize(int pageSize) {
    _pageSize = pageSize;
    _page = 0;
    return _load();
  }
}

final itemApiClientProvider = Provider.autoDispose<ItemApiClient>((ref) =>
    ItemApiClient(
        ref.watch(prefabDioProvider), ref.watch(prefabBackendProvider)));

class ItemDetailScreen extends ConsumerWidget {
  final int id;

  const ItemDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemAsync = ref.watch(itemDetailProvider(id));
    final prefabTheme = PrefabTheme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Item'),
      ),
      body: itemAsync.when(
        data: (item) => ListView(
          padding: prefabTheme.detailPadding,
          children: [
            prefabTheme.detailFieldBuilder(
              context,
              'Secret',
              Text(item.secret.toString()),
            ),
            prefabTheme.detailFieldBuilder(
              context,
              'Note',
              Text(item.note?.toString() ?? '—'),
            ),
          ],
        ),
        loading: () => prefabTheme.loadingBuilder(context),
        error: (error, stackTrace) => ref
                .read(prefabBackendProvider)
                .parseError(error)
                .isNotFound
            ? prefabTheme.notFoundBuilder(context, () => context.go('/items'))
            : prefabTheme.errorBuilder(context, error, stackTrace),
      ),
    );
  }
}

class ItemListScreen extends ConsumerWidget {
  const ItemListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(itemsProvider);
    final notifier = ref.read(itemsProvider.notifier);
    final prefabTheme = PrefabTheme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Item'),
      ),
      body: Column(
        children: [
          Expanded(
            child: itemsAsync.when(
              skipLoadingOnReload: true,
              data: (page) => page.items.isEmpty
                  ? prefabTheme.emptyBuilder(context)
                  : ListView.builder(
                      padding: prefabTheme.listPadding,
                      itemCount: page.items.length,
                      itemBuilder: (context, index) {
                        final item = page.items[index];
                        return prefabTheme.listItemBuilder(
                          context,
                          title: Text(item.name.toString()),
                          subtitle: Text(item.note?.toString() ?? '—'),
                          trailing: null,
                          actions: const [],
                          onTap: () => context.push('/items/${item.id}'),
                        );
                      },
                    ),
              loading: () => prefabTheme.loadingBuilder(context),
              error: (error, stackTrace) =>
                  prefabTheme.errorBuilder(context, error, stackTrace),
            ),
          ),
          PrefabPaginationBar.controlled(
            page: itemsAsync.valueOrNull?.page ?? 0,
            totalPages: itemsAsync.valueOrNull?.totalPages ?? 0,
            onPageChanged: notifier.goToPage,
          ),
        ],
      ),
    );
  }
}

List<RouteBase> get $fieldViewsRoutes => [
      GoRoute(
        path: '/items',
        builder: (context, state) => const ItemListScreen(),
        routes: [
          GoRoute(
            path: ':id',
            builder: (context, state) =>
                ItemDetailScreen(id: int.parse(state.pathParameters['id']!)),
          ),
        ],
      ),
    ];
