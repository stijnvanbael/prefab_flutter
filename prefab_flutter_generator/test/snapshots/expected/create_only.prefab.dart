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

import 'create_only.dart';
import 'dart:async';

class BetaApiClient {
  final Dio _dio;
  final PrefabBackend _adapter;

  BetaApiClient(this._dio, [this._adapter = const PrefabBackend()]);

  Future<PrefabPage<Beta>> list(
      {String? search,
      String? sort,
      bool descending = false,
      int page = 0,
      int? pageSize}) async {
    final response = await _dio.get(
      '/betas',
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
      Beta.fromJson,
      page: page,
      pageSize: pageSize,
    );
  }

  Future<Beta> getById(int id) async {
    final response = await _dio.get('/betas/${_adapter.encodeId(id)}');
    return Beta.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Beta> create(Beta beta) async {
    final response = await _dio.post('/betas', data: beta.toJson());
    return Beta.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> delete(Beta beta) async {
    await _dio.delete('/betas/${_adapter.encodeId(beta.id)}');
  }
}

final betaDetailProvider = FutureProvider.autoDispose.family<Beta, int>(
    (ref, id) => ref.watch(betaApiClientProvider).getById(id));

final betasProvider =
    AsyncNotifierProvider.autoDispose<BetasNotifier, PrefabPage<Beta>>(
        BetasNotifier.new);

class BetasNotifier extends AutoDisposeAsyncNotifier<PrefabPage<Beta>> {
  BetaApiClient get _client => ref.read(betaApiClientProvider);

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
  Future<PrefabPage<Beta>> build() {
    ref.onDispose(() => _searchDebounce?.cancel());
    return _client.list(
        search: _search,
        sort: _sort,
        descending: _descending,
        page: _page,
        pageSize: _pageSize);
  }

  Future<void> _load() async {
    state = const AsyncLoading<PrefabPage<Beta>>().copyWithPrevious(state);
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

  Future<void> create(Beta beta) async {
    await _client.create(beta);
    await _load();
  }
}

final betaApiClientProvider = Provider.autoDispose<BetaApiClient>((ref) =>
    BetaApiClient(
        ref.watch(prefabDioProvider), ref.watch(prefabBackendProvider)));

class BetaDetailScreen extends ConsumerWidget {
  final int id;

  const BetaDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final betaAsync = ref.watch(betaDetailProvider(id));
    final prefabTheme = PrefabTheme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Beta'),
      ),
      body: betaAsync.when(
        data: (beta) => ListView(
          padding: prefabTheme.detailPadding,
          children: [
            prefabTheme.detailFieldBuilder(
              context,
              'Name',
              Text(beta.name.toString()),
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

class BetaListScreen extends ConsumerWidget {
  const BetaListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final betasAsync = ref.watch(betasProvider);
    final notifier = ref.read(betasProvider.notifier);
    final prefabTheme = PrefabTheme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Beta'),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Create Beta',
        onPressed: () async {
          await context.push('/betas/create');
          ref.invalidate(betasProvider);
        },
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Expanded(
            child: betasAsync.when(
              skipLoadingOnReload: true,
              data: (page) => page.items.isEmpty
                  ? prefabTheme.emptyBuilder(context)
                  : ListView.builder(
                      padding: prefabTheme.listPadding,
                      itemCount: page.items.length,
                      itemBuilder: (context, index) {
                        final beta = page.items[index];
                        return prefabTheme.listItemBuilder(
                          context,
                          title: Text(beta.name.toString()),
                          subtitle: null,
                          trailing: null,
                          actions: const [],
                          onTap: () => context.push('/betas/${beta.id}'),
                        );
                      },
                    ),
              loading: () => prefabTheme.loadingBuilder(context),
              error: (error, stackTrace) =>
                  prefabTheme.errorBuilder(context, error, stackTrace),
            ),
          ),
          PrefabPaginationBar.controlled(
            page: betasAsync.valueOrNull?.page ?? 0,
            totalPages: betasAsync.valueOrNull?.totalPages ?? 0,
            onPageChanged: notifier.goToPage,
          ),
        ],
      ),
    );
  }
}

class BetaCreateScreen extends ConsumerStatefulWidget {
  const BetaCreateScreen({super.key});

  @override
  ConsumerState<BetaCreateScreen> createState() => _BetaCreateScreenState();
}

class _BetaCreateScreenState extends ConsumerState<BetaCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    // Keep the (auto-dispose) provider alive while the request runs.
    final subscription = ref.listenManual(betasProvider, (_, __) {});
    try {
      final entity = Beta(
        name: _nameController.text,
      );
      await ref.read(betasProvider.notifier).create(entity);
      if (!mounted) return;
      context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      subscription.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    final prefabTheme = PrefabTheme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Beta'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: prefabTheme.formPadding,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Required';
                return null;
              },
            ),
            prefabTheme.saveButtonBuilder(
              context,
              'Create',
              _saving ? null : _save,
              _saving,
            ),
          ],
        ),
      ),
    );
  }
}

List<RouteBase> get $createOnlyRoutes => [
      GoRoute(
        path: '/betas',
        builder: (context, state) => const BetaListScreen(),
        routes: [
          GoRoute(
            path: 'create',
            builder: (context, state) => const BetaCreateScreen(),
          ),
          GoRoute(
            path: ':id',
            builder: (context, state) =>
                BetaDetailScreen(id: int.parse(state.pathParameters['id']!)),
          ),
        ],
      ),
    ];
