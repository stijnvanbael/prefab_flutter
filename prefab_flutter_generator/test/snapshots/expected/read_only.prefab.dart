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
import 'read_only.dart';

class DeltaApiClient {
  final Dio _dio;
  final PrefabListAdapter _adapter;

  DeltaApiClient(this._dio, [this._adapter = const PrefabListAdapter()]);

  Future<PrefabPage<Delta>> list(
      {String? search,
      String? sort,
      bool descending = false,
      int page = 0,
      int? pageSize}) async {
    final response = await _dio.get(
      '/deltas',
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
      Delta.fromJson,
      page: page,
      pageSize: pageSize,
    );
  }

  Future<Delta> getById(int id) async {
    final response = await _dio.get('/deltas/$id');
    return Delta.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> delete(Delta delta) async {
    await _dio.delete('/deltas/${delta.id}');
  }
}

final deltaDetailProvider = FutureProvider.autoDispose.family<Delta, int>(
    (ref, id) => ref.watch(deltaApiClientProvider).getById(id));

final deltasProvider =
    AsyncNotifierProvider.autoDispose<DeltasNotifier, PrefabPage<Delta>>(
        DeltasNotifier.new);

class DeltasNotifier extends AutoDisposeAsyncNotifier<PrefabPage<Delta>> {
  DeltaApiClient get _client => ref.read(deltaApiClientProvider);

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
  Future<PrefabPage<Delta>> build() {
    ref.onDispose(() => _searchDebounce?.cancel());
    return _client.list(
        search: _search,
        sort: _sort,
        descending: _descending,
        page: _page,
        pageSize: _pageSize);
  }

  Future<void> _load() async {
    state = const AsyncLoading<PrefabPage<Delta>>().copyWithPrevious(state);
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

final deltaApiClientProvider = Provider.autoDispose<DeltaApiClient>((ref) =>
    DeltaApiClient(
        ref.watch(prefabDioProvider), ref.watch(prefabListAdapterProvider)));

class DeltaDetailScreen extends ConsumerWidget {
  final int id;

  const DeltaDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deltaAsync = ref.watch(deltaDetailProvider(id));
    final prefabTheme = PrefabTheme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Delta'),
      ),
      body: deltaAsync.when(
        data: (delta) => ListView(
          padding: prefabTheme.detailPadding,
          children: [
            prefabTheme.detailFieldBuilder(
              context,
              'Name',
              delta.name.toString(),
            ),
          ],
        ),
        loading: () => prefabTheme.loadingBuilder(context),
        error: (error, stackTrace) =>
            prefabTheme.errorBuilder(context, error, stackTrace),
      ),
    );
  }
}

class DeltaListScreen extends ConsumerWidget {
  const DeltaListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deltasAsync = ref.watch(deltasProvider);
    final notifier = ref.read(deltasProvider.notifier);
    final prefabTheme = PrefabTheme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Delta'),
      ),
      body: Column(
        children: [
          Expanded(
            child: deltasAsync.when(
              skipLoadingOnReload: true,
              data: (page) => page.items.isEmpty
                  ? prefabTheme.emptyBuilder(context)
                  : ListView.builder(
                      padding: prefabTheme.listPadding,
                      itemCount: page.items.length,
                      itemBuilder: (context, index) {
                        final delta = page.items[index];
                        return ListTile(
                          title: Text(delta.name.toString()),
                          onTap: () => context.push('/deltas/${delta.id}'),
                        );
                      },
                    ),
              loading: () => prefabTheme.loadingBuilder(context),
              error: (error, stackTrace) =>
                  prefabTheme.errorBuilder(context, error, stackTrace),
            ),
          ),
          PrefabPaginationBar.controlled(
            page: deltasAsync.valueOrNull?.page ?? 0,
            totalPages: deltasAsync.valueOrNull?.totalPages ?? 0,
            onPageChanged: notifier.goToPage,
          ),
        ],
      ),
    );
  }
}

List<RouteBase> get $readOnlyRoutes => [
      GoRoute(
        path: '/deltas',
        builder: (context, state) => const DeltaListScreen(),
        routes: [
          GoRoute(
            path: ':id',
            builder: (context, state) =>
                DeltaDetailScreen(id: int.parse(state.pathParameters['id']!)),
          ),
        ],
      ),
    ];
