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

import 'crud_full.dart';
import 'dart:async';

class AlphaApiClient {
  final Dio _dio;
  final PrefabListAdapter _adapter;

  AlphaApiClient(this._dio, [this._adapter = const PrefabListAdapter()]);

  Future<PrefabPage<Alpha>> list(
      {String? search,
      String? sort,
      bool descending = false,
      int page = 0,
      int? pageSize}) async {
    final response = await _dio.get(
      '/alphas',
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
      Alpha.fromJson,
      page: page,
      pageSize: pageSize,
    );
  }

  Future<Alpha> getById(int id) async {
    final response = await _dio.get('/alphas/$id');
    return Alpha.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Alpha> create(Alpha alpha) async {
    final response = await _dio.post('/alphas', data: alpha.toJson());
    return Alpha.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Alpha> update(Alpha alpha) async {
    final response =
        await _dio.put('/alphas/${alpha.id}', data: alpha.toJson());
    return Alpha.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> delete(Alpha alpha) async {
    await _dio.delete('/alphas/${alpha.id}');
  }
}

final alphaDetailProvider = FutureProvider.autoDispose.family<Alpha, int>(
    (ref, id) => ref.watch(alphaApiClientProvider).getById(id));

final alphasProvider =
    AsyncNotifierProvider.autoDispose<AlphasNotifier, PrefabPage<Alpha>>(
        AlphasNotifier.new);

class AlphasNotifier extends AutoDisposeAsyncNotifier<PrefabPage<Alpha>> {
  AlphaApiClient get _client => ref.read(alphaApiClientProvider);

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
  Future<PrefabPage<Alpha>> build() {
    ref.onDispose(() => _searchDebounce?.cancel());
    return _client.list(
        search: _search,
        sort: _sort,
        descending: _descending,
        page: _page,
        pageSize: _pageSize);
  }

  Future<void> _load() async {
    state = const AsyncLoading<PrefabPage<Alpha>>().copyWithPrevious(state);
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

  Future<void> create(Alpha alpha) async {
    await _client.create(alpha);
    await _load();
  }

  Future<void> updateEntity(Alpha alpha) async {
    await _client.update(alpha);
    ref.invalidate(alphaDetailProvider(alpha.id!));
    await _load();
  }

  Future<void> delete(Alpha alpha) async {
    await _client.delete(alpha);
    ref.invalidate(alphaDetailProvider(alpha.id!));
    await _load();
  }
}

final alphaApiClientProvider = Provider.autoDispose<AlphaApiClient>((ref) =>
    AlphaApiClient(
        ref.watch(prefabDioProvider), ref.watch(prefabListAdapterProvider)));

class AlphaDetailScreen extends ConsumerWidget {
  final int id;

  const AlphaDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alphaAsync = ref.watch(alphaDetailProvider(id));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alpha'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit',
            onPressed: () => context.push('/alphas/$id/edit'),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: 'Delete',
            onPressed: alphaAsync.hasValue
                ? () async {
                    final alpha = alphaAsync.value!;
                    final confirmed = await showPrefabDeleteDialog(
                      context: context,
                      item: alpha,
                      itemLabel: alpha.name.toString(),
                      onDelete: () =>
                          ref.read(alphasProvider.notifier).delete(alpha),
                    );
                    if (confirmed && context.mounted) {
                      context.pop();
                    }
                  }
                : null,
          ),
        ],
      ),
      body: alphaAsync.when(
        data: (alpha) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ListTile(
              title: const Text('Name'),
              subtitle: Text(alpha.name.toString()),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('Error: $error')),
      ),
    );
  }
}

class AlphaListScreen extends ConsumerWidget {
  const AlphaListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alphasAsync = ref.watch(alphasProvider);
    final notifier = ref.read(alphasProvider.notifier);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alpha'),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Create Alpha',
        onPressed: () async {
          await context.push('/alphas/create');
          ref.invalidate(alphasProvider);
        },
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Expanded(
            child: alphasAsync.when(
              skipLoadingOnReload: true,
              data: (page) => page.items.isEmpty
                  ? const Center(child: Text('No items found'))
                  : ListView.builder(
                      itemCount: page.items.length,
                      itemBuilder: (context, index) {
                        final alpha = page.items[index];
                        return ListTile(
                          title: Text(alpha.name.toString()),
                          onTap: () => context.push('/alphas/${alpha.id}'),
                        );
                      },
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) =>
                  Center(child: Text('Error: $error')),
            ),
          ),
          PrefabPaginationBar.controlled(
            page: alphasAsync.valueOrNull?.page ?? 0,
            totalPages: alphasAsync.valueOrNull?.totalPages ?? 0,
            onPageChanged: notifier.goToPage,
          ),
        ],
      ),
    );
  }
}

class AlphaCreateScreen extends ConsumerStatefulWidget {
  const AlphaCreateScreen({super.key});

  @override
  ConsumerState<AlphaCreateScreen> createState() => _AlphaCreateScreenState();
}

class _AlphaCreateScreenState extends ConsumerState<AlphaCreateScreen> {
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
    final subscription = ref.listenManual(alphasProvider, (_, __) {});
    try {
      final entity = Alpha(
        name: _nameController.text,
      );
      await ref.read(alphasProvider.notifier).create(entity);
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alpha'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Required';
                return null;
              },
            ),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }
}

class AlphaEditScreen extends ConsumerStatefulWidget {
  final int id;

  const AlphaEditScreen({super.key, required this.id});

  @override
  ConsumerState<AlphaEditScreen> createState() => _AlphaEditScreenState();
}

class _AlphaEditScreenState extends ConsumerState<AlphaEditScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;
  bool _prefilled = false;
  // ignore: unused_field
  Alpha? _item;
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _prefillControllers(Alpha item) {
    _item = item;
    _nameController.text = item.name;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    // Keep the (auto-dispose) provider alive while the request runs.
    final subscription = ref.listenManual(alphasProvider, (_, __) {});
    try {
      final entity = Alpha(
        id: widget.id,
        name: _nameController.text,
      );
      await ref.read(alphasProvider.notifier).updateEntity(entity);
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
    final asyncItem = ref.watch(alphaDetailProvider(widget.id));
    asyncItem.whenData((item) {
      if (!_prefilled) {
        _prefilled = true;
        _prefillControllers(item);
      }
    });
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alpha'),
      ),
      body: asyncItem.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (_) => Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  return null;
                },
              ),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

List<RouteBase> get $crudFullRoutes => [
      GoRoute(
        path: '/alphas',
        builder: (context, state) => const AlphaListScreen(),
        routes: [
          GoRoute(
            path: 'create',
            builder: (context, state) => const AlphaCreateScreen(),
          ),
          GoRoute(
            path: ':id',
            builder: (context, state) =>
                AlphaDetailScreen(id: int.parse(state.pathParameters['id']!)),
            routes: [
              GoRoute(
                path: 'edit',
                builder: (context, state) =>
                    AlphaEditScreen(id: int.parse(state.pathParameters['id']!)),
              ),
            ],
          ),
        ],
      ),
    ];
