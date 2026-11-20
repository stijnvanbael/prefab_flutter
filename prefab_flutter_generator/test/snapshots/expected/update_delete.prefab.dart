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
import 'update_delete.dart';

class GammaApiClient {
  final Dio _dio;
  final PrefabListAdapter _adapter;

  GammaApiClient(this._dio, [this._adapter = const PrefabListAdapter()]);

  Future<PrefabPage<Gamma>> list(
      {String? search,
      String? sort,
      bool descending = false,
      int page = 0,
      int? pageSize}) async {
    final response = await _dio.get(
      '/gammas',
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
      Gamma.fromJson,
      page: page,
      pageSize: pageSize,
    );
  }

  Future<Gamma> getById(int id) async {
    final response = await _dio.get('/gammas/$id');
    return Gamma.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Gamma> update(Gamma gamma) async {
    final response =
        await _dio.put('/gammas/${gamma.id}', data: gamma.toJson());
    return Gamma.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> delete(Gamma gamma) async {
    await _dio.delete('/gammas/${gamma.id}');
  }
}

final gammaDetailProvider = FutureProvider.autoDispose.family<Gamma, int>(
    (ref, id) => ref.watch(gammaApiClientProvider).getById(id));

final gammasProvider =
    AsyncNotifierProvider.autoDispose<GammasNotifier, PrefabPage<Gamma>>(
        GammasNotifier.new);

class GammasNotifier extends AutoDisposeAsyncNotifier<PrefabPage<Gamma>> {
  GammaApiClient get _client => ref.read(gammaApiClientProvider);

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
  Future<PrefabPage<Gamma>> build() {
    ref.onDispose(() => _searchDebounce?.cancel());
    return _client.list(
        search: _search,
        sort: _sort,
        descending: _descending,
        page: _page,
        pageSize: _pageSize);
  }

  Future<void> _load() async {
    state = const AsyncLoading<PrefabPage<Gamma>>().copyWithPrevious(state);
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

  Future<void> updateEntity(Gamma gamma) async {
    await _client.update(gamma);
    ref.invalidate(gammaDetailProvider(gamma.id!));
    await _load();
  }

  Future<void> delete(Gamma gamma) async {
    await _client.delete(gamma);
    ref.invalidate(gammaDetailProvider(gamma.id!));
    await _load();
  }
}

final gammaApiClientProvider = Provider.autoDispose<GammaApiClient>((ref) =>
    GammaApiClient(
        ref.watch(prefabDioProvider), ref.watch(prefabListAdapterProvider)));

class GammaDetailScreen extends ConsumerWidget {
  final int id;

  const GammaDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gammaAsync = ref.watch(gammaDetailProvider(id));
    final prefabTheme = PrefabTheme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gamma'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit',
            onPressed: () => context.push('/gammas/$id/edit'),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: 'Delete',
            onPressed: gammaAsync.hasValue
                ? () async {
                    final gamma = gammaAsync.value!;
                    final confirmed = await showPrefabDeleteDialog(
                      context: context,
                      item: gamma,
                      itemLabel: gamma.name.toString(),
                      onDelete: () =>
                          ref.read(gammasProvider.notifier).delete(gamma),
                    );
                    if (confirmed && context.mounted) {
                      context.pop();
                    }
                  }
                : null,
          ),
        ],
      ),
      body: gammaAsync.when(
        data: (gamma) => ListView(
          padding: prefabTheme.detailPadding,
          children: [
            prefabTheme.detailFieldBuilder(
              context,
              'Name',
              gamma.name.toString(),
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

class GammaListScreen extends ConsumerWidget {
  const GammaListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gammasAsync = ref.watch(gammasProvider);
    final notifier = ref.read(gammasProvider.notifier);
    final prefabTheme = PrefabTheme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gamma'),
      ),
      body: Column(
        children: [
          Expanded(
            child: gammasAsync.when(
              skipLoadingOnReload: true,
              data: (page) => page.items.isEmpty
                  ? prefabTheme.emptyBuilder(context)
                  : ListView.builder(
                      padding: prefabTheme.listPadding,
                      itemCount: page.items.length,
                      itemBuilder: (context, index) {
                        final gamma = page.items[index];
                        return ListTile(
                          title: Text(gamma.name.toString()),
                          onTap: () => context.push('/gammas/${gamma.id}'),
                        );
                      },
                    ),
              loading: () => prefabTheme.loadingBuilder(context),
              error: (error, stackTrace) =>
                  prefabTheme.errorBuilder(context, error, stackTrace),
            ),
          ),
          PrefabPaginationBar.controlled(
            page: gammasAsync.valueOrNull?.page ?? 0,
            totalPages: gammasAsync.valueOrNull?.totalPages ?? 0,
            onPageChanged: notifier.goToPage,
          ),
        ],
      ),
    );
  }
}

class GammaEditScreen extends ConsumerStatefulWidget {
  final int id;

  const GammaEditScreen({super.key, required this.id});

  @override
  ConsumerState<GammaEditScreen> createState() => _GammaEditScreenState();
}

class _GammaEditScreenState extends ConsumerState<GammaEditScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;
  bool _prefilled = false;
  // ignore: unused_field
  Gamma? _item;
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _prefillControllers(Gamma item) {
    _item = item;
    _nameController.text = item.name;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    // Keep the (auto-dispose) provider alive while the request runs.
    final subscription = ref.listenManual(gammasProvider, (_, __) {});
    try {
      final entity = Gamma(
        id: widget.id,
        name: _nameController.text,
      );
      await ref.read(gammasProvider.notifier).updateEntity(entity);
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
    final asyncItem = ref.watch(gammaDetailProvider(widget.id));
    asyncItem.whenData((item) {
      if (!_prefilled) {
        _prefilled = true;
        _prefillControllers(item);
      }
    });
    final prefabTheme = PrefabTheme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gamma'),
      ),
      body: asyncItem.when(
        loading: () => prefabTheme.loadingBuilder(context),
        error: (e, st) => prefabTheme.errorBuilder(context, e, st),
        data: (_) => Form(
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
                'Save',
                _saving ? null : _save,
                _saving,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

List<RouteBase> get $updateDeleteRoutes => [
      GoRoute(
        path: '/gammas',
        builder: (context, state) => const GammaListScreen(),
        routes: [
          GoRoute(
            path: ':id',
            builder: (context, state) =>
                GammaDetailScreen(id: int.parse(state.pathParameters['id']!)),
            routes: [
              GoRoute(
                path: 'edit',
                builder: (context, state) =>
                    GammaEditScreen(id: int.parse(state.pathParameters['id']!)),
              ),
            ],
          ),
        ],
      ),
    ];
