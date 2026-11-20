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

import 'custom_field.dart';
import 'dart:async';

class AppThemeApiClient {
  final Dio _dio;
  final PrefabBackend _adapter;

  AppThemeApiClient(this._dio, [this._adapter = const PrefabBackend()]);

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
    final response = await _dio.get('/themes/${_adapter.encodeId(id)}');
    return AppTheme.fromJson(response.data as Map<String, dynamic>);
  }

  Future<AppTheme> create(AppTheme appTheme) async {
    final response = await _dio.post('/themes', data: _createBody(appTheme));
    return AppTheme.fromJson(response.data as Map<String, dynamic>);
  }

  /// Only the fields of the create form (and the parent id).
  Map<String, dynamic> _createBody(AppTheme appTheme) => {
        for (final e in appTheme.toJson().entries)
          if (const <String>{'name', 'accent', 'highlight'}.contains(e.key))
            e.key: e.value,
      };

  Future<AppTheme> update(AppTheme appTheme) async {
    final response = await _dio.put('/themes/${_adapter.encodeId(appTheme.id)}',
        data: appTheme.toJson());
    return AppTheme.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> delete(AppTheme appTheme) async {
    await _dio.delete('/themes/${_adapter.encodeId(appTheme.id)}');
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
        ref.watch(prefabDioProvider), ref.watch(prefabBackendProvider)));

class AppThemeDetailScreen extends ConsumerWidget {
  final int id;

  const AppThemeDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appThemeAsync = ref.watch(appThemeDetailProvider(id));
    final prefabTheme = PrefabTheme.of(context);
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
          padding: prefabTheme.detailPadding,
          children: [
            prefabTheme.detailFieldBuilder(
              context,
              'Name',
              Text(appTheme.name.toString()),
            ),
            prefabTheme.detailFieldBuilder(
              context,
              'Accent colour',
              ColorSwatch(value: appTheme.accent),
            ),
            prefabTheme.detailFieldBuilder(
              context,
              'Highlight',
              ColorSwatch(value: appTheme.highlight),
            ),
          ],
        ),
        loading: () => prefabTheme.loadingBuilder(context),
        error: (error, stackTrace) => ref
                .read(prefabBackendProvider)
                .parseError(error)
                .isNotFound
            ? prefabTheme.notFoundBuilder(context, () => context.go('/themes'))
            : prefabTheme.errorBuilder(context, error, stackTrace),
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
    final prefabTheme = PrefabTheme.of(context);
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
                  ? prefabTheme.emptyBuilder(context)
                  : ListView.builder(
                      padding: prefabTheme.listPadding,
                      itemCount: page.items.length,
                      itemBuilder: (context, index) {
                        final appTheme = page.items[index];
                        return prefabTheme.listItemBuilder(
                          context,
                          title: Text(appTheme.name.toString()),
                          subtitle: null,
                          trailing: null,
                          actions: const [],
                          onTap: () => context.push('/themes/${appTheme.id}'),
                        );
                      },
                    ),
              loading: () => prefabTheme.loadingBuilder(context),
              error: (error, stackTrace) =>
                  prefabTheme.errorBuilder(context, error, stackTrace),
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
  final _formErrors = PrefabFormErrors();
  final _nameController = TextEditingController();
  int? _accentValue;
  int? _highlightValue;

  @override
  void dispose() {
    _formErrors.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    _formErrors.clear();
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
      _formErrors.setError(
        ref.read(prefabBackendProvider).parseError(e),
        const {'name', 'accent', 'highlight'},
      );
    } finally {
      subscription.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    final prefabTheme = PrefabTheme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Theme'),
      ),
      body: Form(
        key: _formKey,
        onChanged: _formErrors.clearEdited,
        child: ListView(
          padding: prefabTheme.formPadding,
          children: [
            PrefabFormErrorBanner(errors: _formErrors),
            PrefabFieldError(
              errors: _formErrors,
              field: 'name',
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Required';
                    return null;
                  },
                ),
              ],
            ),
            PrefabFieldError(
              errors: _formErrors,
              field: 'accent',
              children: [
                ColorField(
                  initialValue: _accentValue,
                  onChanged: (value) => _accentValue = value,
                  label: 'Accent colour',
                  validator: (value) => value == null ? 'Required' : null,
                ),
              ],
            ),
            PrefabFieldError(
              errors: _formErrors,
              field: 'highlight',
              children: [
                ColorField(
                  initialValue: _highlightValue,
                  onChanged: (value) => _highlightValue = value,
                  label: 'Highlight',
                ),
              ],
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

class AppThemeEditScreen extends ConsumerStatefulWidget {
  final int id;

  const AppThemeEditScreen({super.key, required this.id});

  @override
  ConsumerState<AppThemeEditScreen> createState() => _AppThemeEditScreenState();
}

class _AppThemeEditScreenState extends ConsumerState<AppThemeEditScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;
  final _formErrors = PrefabFormErrors();
  bool _prefilled = false;
  // ignore: unused_field
  AppTheme? _item;
  final _nameController = TextEditingController();
  int? _accentValue;
  int? _highlightValue;

  @override
  void dispose() {
    _formErrors.dispose();
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
    _formErrors.clear();
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
      _formErrors.setError(
        ref.read(prefabBackendProvider).parseError(e),
        const {'name', 'accent', 'highlight'},
      );
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
    final prefabTheme = PrefabTheme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Theme'),
      ),
      body: asyncItem.when(
        loading: () => prefabTheme.loadingBuilder(context),
        error: (e, st) => ref
                .read(prefabBackendProvider)
                .parseError(e)
                .isNotFound
            ? prefabTheme.notFoundBuilder(context, () => context.go('/themes'))
            : prefabTheme.errorBuilder(context, e, st),
        data: (_) => Form(
          key: _formKey,
          onChanged: _formErrors.clearEdited,
          child: ListView(
            padding: prefabTheme.formPadding,
            children: [
              PrefabFormErrorBanner(errors: _formErrors),
              PrefabFieldError(
                errors: _formErrors,
                field: 'name',
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Name'),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Required';
                      return null;
                    },
                  ),
                ],
              ),
              PrefabFieldError(
                errors: _formErrors,
                field: 'accent',
                children: [
                  ColorField(
                    initialValue: _accentValue,
                    onChanged: (value) => _accentValue = value,
                    label: 'Accent colour',
                    validator: (value) => value == null ? 'Required' : null,
                  ),
                ],
              ),
              PrefabFieldError(
                errors: _formErrors,
                field: 'highlight',
                children: [
                  ColorField(
                    initialValue: _highlightValue,
                    onChanged: (value) => _highlightValue = value,
                    label: 'Highlight',
                  ),
                ],
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
