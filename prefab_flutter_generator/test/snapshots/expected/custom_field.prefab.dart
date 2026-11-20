// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// PrefabGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
//
// **************************************************************************
// PrefabGenerator
// **************************************************************************

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:prefab_flutter_widgets/prefab_flutter_widgets.dart';

import 'custom_field.dart';
import 'dart:async';

class AppThemeApiClient {
  final Dio _dio;
  final PrefabListAdapter _adapter;

  AppThemeApiClient(this._dio, [this._adapter = const PrefabListAdapter()]);

  Future<PrefabPage<AppTheme>> list(
      {String? search,
      String? sort,
      bool descending = false,
      int page = 0,
      int? pageSize}) async {
    final response = await _dio.get(
      '/themes',
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
      AppTheme.fromJson,
      page: page,
      pageSize: pageSize,
    );
  }

  Future<AppTheme> getById(int id) async {
    final response = await _dio.get('/themes/$id');
    return AppTheme.fromJson(response.data as Map<String, dynamic>);
  }

  Future<AppTheme> create(AppTheme appTheme) async {
    final response = await _dio.post('/themes', data: appTheme.toJson());
    return AppTheme.fromJson(response.data as Map<String, dynamic>);
  }

  Future<AppTheme> update(AppTheme appTheme) async {
    final response =
        await _dio.put('/themes/${appTheme.id}', data: appTheme.toJson());
    return AppTheme.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> delete(AppTheme appTheme) async {
    await _dio.delete('/themes/${appTheme.id}');
  }
}

final appThemeDetailProvider = FutureProvider.autoDispose.family<AppTheme, int>(
    (ref, id) => ref.watch(appThemeApiClientProvider).getById(id));

final appThemesProvider =
    AsyncNotifierProvider.autoDispose<AppThemesNotifier, PrefabPage<AppTheme>>(
        AppThemesNotifier.new);

class AppThemesNotifier extends AutoDisposeAsyncNotifier<PrefabPage<AppTheme>> {
  AppThemeApiClient get _client => ref.read(appThemeApiClientProvider);

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
  Future<PrefabPage<AppTheme>> build() {
    ref.onDispose(() => _searchDebounce?.cancel());
    return _client.list(
        search: _search,
        sort: _sort,
        descending: _descending,
        page: _page,
        pageSize: _pageSize);
  }

  Future<void> _load() async {
    state = const AsyncLoading<PrefabPage<AppTheme>>().copyWithPrevious(state);
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

  Future<void> create(AppTheme appTheme) async {
    await _client.create(appTheme);
    await _load();
  }

  Future<void> updateEntity(AppTheme appTheme) async {
    await _client.update(appTheme);
    ref.invalidate(appThemeDetailProvider(appTheme.id!));
    await _load();
  }
}

final appThemeApiClientProvider = Provider.autoDispose<AppThemeApiClient>(
    (ref) => AppThemeApiClient(
        ref.watch(prefabDioProvider), ref.watch(prefabListAdapterProvider)));

class AppThemeDetailScreen extends ConsumerWidget {
  final int id;

  const AppThemeDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appThemeAsync = ref.watch(appThemeDetailProvider(id));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Theme'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit',
            onPressed: () => context.push('/themes/$id/edit'),
          ),
        ],
      ),
      body: appThemeAsync.when(
        data: (appTheme) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ListTile(
              title: const Text('Name'),
              subtitle: Text(appTheme.name.toString()),
            ),
            ListTile(
              title: const Text('Accent colour'),
              subtitle: ColorSwatch(value: appTheme.accent),
            ),
            ListTile(
              title: const Text('Highlight'),
              subtitle: ColorSwatch(value: appTheme.highlight),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('Error: $error')),
      ),
    );
  }
}

class AppThemeListScreen extends ConsumerWidget {
  const AppThemeListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appThemesAsync = ref.watch(appThemesProvider);
    final notifier = ref.read(appThemesProvider.notifier);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Theme'),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Create Theme',
        onPressed: () async {
          await context.push('/themes/create');
          ref.invalidate(appThemesProvider);
        },
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Expanded(
            child: appThemesAsync.when(
              skipLoadingOnReload: true,
              data: (page) => page.items.isEmpty
                  ? const Center(child: Text('No items found'))
                  : ListView.builder(
                      itemCount: page.items.length,
                      itemBuilder: (context, index) {
                        final appTheme = page.items[index];
                        return ListTile(
                          title: Text(appTheme.name.toString()),
                          onTap: () => context.push('/themes/${appTheme.id}'),
                        );
                      },
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) =>
                  Center(child: Text('Error: $error')),
            ),
          ),
          PrefabPaginationBar.controlled(
            page: appThemesAsync.valueOrNull?.page ?? 0,
            totalPages: appThemesAsync.valueOrNull?.totalPages ?? 0,
            onPageChanged: notifier.goToPage,
          ),
        ],
      ),
    );
  }
}

class AppThemeCreateScreen extends ConsumerStatefulWidget {
  const AppThemeCreateScreen({super.key});

  @override
  ConsumerState<AppThemeCreateScreen> createState() =>
      _AppThemeCreateScreenState();
}

class _AppThemeCreateScreenState extends ConsumerState<AppThemeCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;
  final _nameController = TextEditingController();
  int? _accentValue;
  int? _highlightValue;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    // Keep the (auto-dispose) provider alive while the request runs.
    final subscription = ref.listenManual(appThemesProvider, (_, __) {});
    try {
      final entity = AppTheme(
        name: _nameController.text,
        accent: _accentValue!,
        highlight: _highlightValue,
      );
      await ref.read(appThemesProvider.notifier).create(entity);
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
        title: const Text('Theme'),
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
            ColorField(
              initialValue: _accentValue,
              onChanged: (value) => _accentValue = value,
              label: 'Accent colour',
              validator: (value) => value == null ? 'Required' : null,
            ),
            ColorField(
              initialValue: _highlightValue,
              onChanged: (value) => _highlightValue = value,
              label: 'Highlight',
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

class AppThemeEditScreen extends ConsumerStatefulWidget {
  final int id;

  const AppThemeEditScreen({super.key, required this.id});

  @override
  ConsumerState<AppThemeEditScreen> createState() => _AppThemeEditScreenState();
}

class _AppThemeEditScreenState extends ConsumerState<AppThemeEditScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;
  bool _prefilled = false;
  // ignore: unused_field
  AppTheme? _item;
  final _nameController = TextEditingController();
  int? _accentValue;
  int? _highlightValue;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _prefillControllers(AppTheme item) {
    _item = item;
    _nameController.text = item.name;
    _accentValue = item.accent;
    _highlightValue = item.highlight;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    // Keep the (auto-dispose) provider alive while the request runs.
    final subscription = ref.listenManual(appThemesProvider, (_, __) {});
    try {
      final entity = AppTheme(
        id: widget.id,
        name: _nameController.text,
        accent: _accentValue!,
        highlight: _highlightValue,
      );
      await ref.read(appThemesProvider.notifier).updateEntity(entity);
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
    final asyncItem = ref.watch(appThemeDetailProvider(widget.id));
    asyncItem.whenData((item) {
      if (!_prefilled) {
        _prefilled = true;
        _prefillControllers(item);
      }
    });
    return Scaffold(
      appBar: AppBar(
        title: const Text('Theme'),
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
              ColorField(
                initialValue: _accentValue,
                onChanged: (value) => _accentValue = value,
                label: 'Accent colour',
                validator: (value) => value == null ? 'Required' : null,
              ),
              ColorField(
                initialValue: _highlightValue,
                onChanged: (value) => _highlightValue = value,
                label: 'Highlight',
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

List<RouteBase> get $customFieldRoutes => [
      GoRoute(
        path: '/themes',
        builder: (context, state) => const AppThemeListScreen(),
        routes: [
          GoRoute(
            path: 'create',
            builder: (context, state) => const AppThemeCreateScreen(),
          ),
          GoRoute(
            path: ':id',
            builder: (context, state) => AppThemeDetailScreen(
                id: int.parse(state.pathParameters['id']!)),
            routes: [
              GoRoute(
                path: 'edit',
                builder: (context, state) => AppThemeEditScreen(
                    id: int.parse(state.pathParameters['id']!)),
              ),
            ],
          ),
        ],
      ),
    ];
