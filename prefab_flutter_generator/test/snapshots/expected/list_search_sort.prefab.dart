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
import 'list_search_sort.dart';

class BookApiClient {
  final Dio _dio;
  final PrefabListAdapter _adapter;

  BookApiClient(this._dio, [this._adapter = const PrefabListAdapter()]);

  Future<PrefabPage<Book>> list(
      {String? search,
      String? sort,
      bool descending = false,
      int page = 0,
      int? pageSize}) async {
    final response = await _dio.get(
      '/books',
      queryParameters: _adapter.queryParameters(
        search: search,
        sort: sort,
        descending: descending,
      ),
    );
    return _adapter.parsePage(
      response.data,
      Book.fromJson,
    );
  }

  Future<Book> getById(int id) async {
    final response = await _dio.get('/books/$id');
    return Book.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> delete(Book book) async {
    await _dio.delete('/books/${book.id}');
  }
}

final bookDetailProvider = FutureProvider.autoDispose.family<Book, int>(
    (ref, id) => ref.watch(bookApiClientProvider).getById(id));

final booksProvider =
    AsyncNotifierProvider.autoDispose<BooksNotifier, PrefabPage<Book>>(
        BooksNotifier.new);

class BooksNotifier extends AutoDisposeAsyncNotifier<PrefabPage<Book>> {
  BookApiClient get _client => ref.read(bookApiClientProvider);

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

  @override
  Future<PrefabPage<Book>> build() {
    ref.onDispose(() => _searchDebounce?.cancel());
    return _client.list(search: _search, sort: _sort, descending: _descending);
  }

  Future<void> _load() async {
    state = const AsyncLoading<PrefabPage<Book>>().copyWithPrevious(state);
    state = await AsyncValue.guard(() =>
        _client.list(search: _search, sort: _sort, descending: _descending));
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
}

final bookApiClientProvider = Provider.autoDispose<BookApiClient>((ref) =>
    BookApiClient(
        ref.watch(prefabDioProvider), ref.watch(prefabListAdapterProvider)));

class BookDetailScreen extends ConsumerWidget {
  final int id;

  const BookDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookAsync = ref.watch(bookDetailProvider(id));
    final prefabTheme = PrefabTheme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book'),
      ),
      body: bookAsync.when(
        data: (book) => ListView(
          padding: prefabTheme.detailPadding,
          children: [
            prefabTheme.detailFieldBuilder(
              context,
              'Title',
              Text(book.title.toString()),
            ),
            prefabTheme.detailFieldBuilder(
              context,
              'Pages',
              Text(book.pages.toString()),
            ),
            prefabTheme.detailFieldBuilder(
              context,
              'Author',
              Text(book.author?.toString() ?? '—'),
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

class BookListScreen extends ConsumerWidget {
  const BookListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booksAsync = ref.watch(booksProvider);
    final notifier = ref.read(booksProvider.notifier);
    final prefabTheme = PrefabTheme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book'),
        actions: [
          PrefabSortMenu<Book>(
            options: const [
              PrefabSortOption(
                  id: 'title', label: 'Title ↑', icon: Icons.arrow_upward),
              PrefabSortOption(
                  id: '-title', label: 'Title ↓', icon: Icons.arrow_downward),
              PrefabSortOption(
                  id: 'pages', label: 'Pages ↑', icon: Icons.arrow_upward),
              PrefabSortOption(
                  id: '-pages', label: 'Pages ↓', icon: Icons.arrow_downward),
            ],
            selectedId: notifier.sort == null
                ? null
                : '${notifier.descending ? '-' : ''}${notifier.sort}',
            onSortChanged: (option) => notifier.setSort(
              option.id.replaceFirst('-', ''),
              descending: option.id.startsWith('-'),
            ),
          ),
        ],
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
          Expanded(
            child: booksAsync.when(
              skipLoadingOnReload: true,
              data: (page) => page.items.isEmpty
                  ? prefabTheme.emptyBuilder(context)
                  : ListView.builder(
                      padding: prefabTheme.listPadding,
                      itemCount: page.items.length,
                      itemBuilder: (context, index) {
                        final book = page.items[index];
                        return ListTile(
                          title: Text(book.title.toString()),
                          onTap: () => context.push('/books/${book.id}'),
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

List<RouteBase> get $listSearchSortRoutes => [
      GoRoute(
        path: '/books',
        builder: (context, state) => const BookListScreen(),
        routes: [
          GoRoute(
            path: ':id',
            builder: (context, state) =>
                BookDetailScreen(id: int.parse(state.pathParameters['id']!)),
          ),
        ],
      ),
    ];
