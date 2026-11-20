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
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:prefab_flutter_widgets/prefab_flutter_widgets.dart';

import 'dart:async';
import 'named_operations.dart';

class ChargerApiClient {
  final Dio _dio;
  final PrefabBackend _adapter;

  ChargerApiClient(this._dio, [this._adapter = const PrefabBackend()]);

  Future<PrefabPage<Charger>> list(
      {String? search,
      String? sort,
      bool descending = false,
      int page = 0,
      int? pageSize}) async {
    final response = await _dio.get(
      '/chargers',
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
      Charger.fromJson,
      page: page,
      pageSize: pageSize,
    );
  }

  Future<Charger> getById(int id) async {
    final response = await _dio.get('/chargers/${_adapter.encodeId(id)}');
    return Charger.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Charger> update(Charger charger) async {
    final response = await _dio.put(
        '/chargers/${_adapter.encodeId(charger.id)}',
        data: charger.toJson());
    return Charger.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> delete(Charger charger) async {
    await _dio.delete('/chargers/${_adapter.encodeId(charger.id)}');
  }

  Future<void> start(int id, StartParameters parameters) async {
    await _dio.request<void>(
      '/chargers/${_adapter.encodeId(id)}/start',
      data: _adapter.operationBody(parameters.toJson()),
      options: Options(method: _adapter.operationMethod),
    );
  }

  Future<void> stop(int id) async {
    await _dio.request<void>(
      '/chargers/${_adapter.encodeId(id)}/stop',
      data: _adapter.operationBody(null),
      options: Options(method: _adapter.operationMethod),
    );
  }
}

class SessionApiClient {
  final Dio _dio;
  final PrefabBackend _adapter;

  SessionApiClient(this._dio, [this._adapter = const PrefabBackend()]);

  Future<PrefabPage<Session>> list(
      {required int chargerId,
      String? search,
      String? sort,
      bool descending = false,
      int page = 0,
      int? pageSize}) async {
    final response = await _dio.get(
      '/chargers/$chargerId/sessions',
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
      Session.fromJson,
      page: page,
      pageSize: pageSize,
    );
  }

  Future<Session> getById(int id, {required int chargerId}) async {
    final response = await _dio
        .get('/chargers/$chargerId/sessions/${_adapter.encodeId(id)}');
    return Session.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> delete(Session session, {required int chargerId}) async {
    await _dio.delete(
        '/chargers/$chargerId/sessions/${_adapter.encodeId(session.id)}');
  }

  Future<void> markPaid(int id, {required int chargerId}) async {
    await _dio.request<void>(
      '/chargers/$chargerId/sessions/${_adapter.encodeId(id)}/mark-paid',
      data: _adapter.operationBody(null),
      options: Options(method: _adapter.operationMethod),
    );
  }
}

final chargerDetailProvider = FutureProvider.autoDispose.family<Charger, int>(
    (ref, id) => ref.watch(chargerApiClientProvider).getById(id));

final chargersProvider =
    AsyncNotifierProvider.autoDispose<ChargersNotifier, PrefabPage<Charger>>(
        ChargersNotifier.new);

class ChargersNotifier extends AutoDisposeAsyncNotifier<PrefabPage<Charger>> {
  ChargerApiClient get _client => ref.read(chargerApiClientProvider);

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
  Future<PrefabPage<Charger>> build() {
    ref.onDispose(() => _searchDebounce?.cancel());
    return _client.list(
        search: _search,
        sort: _sort,
        descending: _descending,
        page: _page,
        pageSize: _pageSize);
  }

  Future<void> _load() async {
    state = const AsyncLoading<PrefabPage<Charger>>().copyWithPrevious(state);
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

  Future<void> updateEntity(Charger charger) async {
    await _client.update(charger);
    ref.invalidate(chargerDetailProvider(charger.id!));
    await _load();
  }

  Future<void> start(int id, StartParameters parameters) async {
    await _client.start(id, parameters);
    ref.invalidate(chargerDetailProvider(id));
    await _load();
  }

  Future<void> stop(int id) async {
    await _client.stop(id);
    ref.invalidate(chargerDetailProvider(id));
    await _load();
  }
}

final chargerApiClientProvider = Provider.autoDispose<ChargerApiClient>((ref) =>
    ChargerApiClient(
        ref.watch(prefabDioProvider), ref.watch(prefabBackendProvider)));

final sessionDetailProvider = FutureProvider.autoDispose
    .family<Session, (int, int)>((ref, args) => ref
        .watch(sessionApiClientProvider)
        .getById(args.$1, chargerId: args.$2));

final sessionsProvider = AsyncNotifierProvider.autoDispose
    .family<SessionsNotifier, PrefabPage<Session>, int>(SessionsNotifier.new);

class SessionsNotifier
    extends AutoDisposeFamilyAsyncNotifier<PrefabPage<Session>, int> {
  int get chargerId => arg;

  SessionApiClient get _client => ref.read(sessionApiClientProvider);

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
  Future<PrefabPage<Session>> build(int arg) {
    ref.onDispose(() => _searchDebounce?.cancel());
    return _client.list(
        chargerId: chargerId,
        search: _search,
        sort: _sort,
        descending: _descending,
        page: _page,
        pageSize: _pageSize);
  }

  Future<void> _load() async {
    state = const AsyncLoading<PrefabPage<Session>>().copyWithPrevious(state);
    state = await AsyncValue.guard(() => _client.list(
        chargerId: chargerId,
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

  Future<void> markPaid(int id) async {
    await _client.markPaid(id, chargerId: chargerId);
    ref.invalidate(sessionDetailProvider((id, chargerId)));
    await _load();
  }
}

final sessionApiClientProvider = Provider.autoDispose<SessionApiClient>((ref) =>
    SessionApiClient(
        ref.watch(prefabDioProvider), ref.watch(prefabBackendProvider)));

class ChargerDetailScreen extends ConsumerWidget {
  final int id;

  const ChargerDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chargerAsync = ref.watch(chargerDetailProvider(id));
    final prefabTheme = PrefabTheme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Charger'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit',
            onPressed: () => context.push('/chargers/$id/edit'),
          ),
          IconButton(
            icon: const Icon(Icons.play_arrow),
            tooltip: 'Start',
            onPressed: chargerAsync.hasValue
                ? () => context.push('/chargers/$id/start')
                : null,
          ),
          IconButton(
            icon: const Icon(Icons.bolt),
            tooltip: 'Stop',
            onPressed: chargerAsync.hasValue
                ? () => runPrefabOperation(
                      context: context,
                      backend: ref.read(prefabBackendProvider),
                      label: 'Stop',
                      confirm: 'Stop charging?',
                      run: () => ref.read(chargersProvider.notifier).stop(id),
                    )
                : null,
          ),
        ],
      ),
      body: chargerAsync.when(
        data: (charger) => ListView(
          padding: prefabTheme.detailPadding,
          children: [
            prefabTheme.detailFieldBuilder(
              context,
              'Name',
              Text(charger.name.toString()),
            ),
          ],
        ),
        loading: () => prefabTheme.loadingBuilder(context),
        error: (error, stackTrace) =>
            ref.read(prefabBackendProvider).parseError(error).isNotFound
                ? prefabTheme.notFoundBuilder(
                    context, () => context.go('/chargers'))
                : prefabTheme.errorBuilder(context, error, stackTrace),
      ),
    );
  }
}

class SessionDetailScreen extends ConsumerWidget {
  final int id;
  final int chargerId;

  const SessionDetailScreen(
      {super.key, required this.id, required this.chargerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(sessionDetailProvider((id, chargerId)));
    final prefabTheme = PrefabTheme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Session'),
      ),
      body: sessionAsync.when(
        data: (session) => ListView(
          padding: prefabTheme.detailPadding,
          children: [
            prefabTheme.detailFieldBuilder(
              context,
              'Name',
              Text(session.name.toString()),
            ),
          ],
        ),
        loading: () => prefabTheme.loadingBuilder(context),
        error: (error, stackTrace) =>
            ref.read(prefabBackendProvider).parseError(error).isNotFound
                ? prefabTheme.notFoundBuilder(
                    context, () => context.go('/chargers/$chargerId/sessions'))
                : prefabTheme.errorBuilder(context, error, stackTrace),
      ),
    );
  }
}

class ChargerListScreen extends ConsumerWidget {
  const ChargerListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chargersAsync = ref.watch(chargersProvider);
    final notifier = ref.read(chargersProvider.notifier);
    final prefabTheme = PrefabTheme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Charger'),
      ),
      body: Column(
        children: [
          Expanded(
            child: chargersAsync.when(
              skipLoadingOnReload: true,
              data: (page) => page.items.isEmpty
                  ? prefabTheme.emptyBuilder(context)
                  : ListView.builder(
                      padding: prefabTheme.listPadding,
                      itemCount: page.items.length,
                      itemBuilder: (context, index) {
                        final charger = page.items[index];
                        return prefabTheme.listItemBuilder(
                          context,
                          title: Text(charger.name.toString()),
                          subtitle: null,
                          trailing: null,
                          actions: [
                            PopupMenuItem<void>(
                              onTap: () => runPrefabOperation(
                                context: context,
                                backend: ref.read(prefabBackendProvider),
                                label: 'Stop',
                                confirm: 'Stop charging?',
                                run: () => ref
                                    .read(chargersProvider.notifier)
                                    .stop(charger.id!),
                              ),
                              child: const Text('Stop'),
                            ),
                          ],
                          onTap: () => context.push('/chargers/${charger.id}'),
                        );
                      },
                    ),
              loading: () => prefabTheme.loadingBuilder(context),
              error: (error, stackTrace) =>
                  prefabTheme.errorBuilder(context, error, stackTrace),
            ),
          ),
          PrefabPaginationBar.controlled(
            page: chargersAsync.valueOrNull?.page ?? 0,
            totalPages: chargersAsync.valueOrNull?.totalPages ?? 0,
            onPageChanged: notifier.goToPage,
          ),
        ],
      ),
    );
  }
}

class SessionListScreen extends ConsumerWidget {
  final int chargerId;

  const SessionListScreen({super.key, required this.chargerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(sessionsProvider(chargerId));
    final notifier = ref.read(sessionsProvider(chargerId).notifier);
    final prefabTheme = PrefabTheme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Session'),
      ),
      body: Column(
        children: [
          Expanded(
            child: sessionsAsync.when(
              skipLoadingOnReload: true,
              data: (page) => page.items.isEmpty
                  ? prefabTheme.emptyBuilder(context)
                  : ListView.builder(
                      padding: prefabTheme.listPadding,
                      itemCount: page.items.length,
                      itemBuilder: (context, index) {
                        final session = page.items[index];
                        return prefabTheme.listItemBuilder(
                          context,
                          title: Text(session.name.toString()),
                          subtitle: null,
                          trailing: null,
                          actions: [
                            PopupMenuItem<void>(
                              onTap: () => runPrefabOperation(
                                context: context,
                                backend: ref.read(prefabBackendProvider),
                                label: 'Mark paid',
                                run: () => ref
                                    .read(sessionsProvider(chargerId).notifier)
                                    .markPaid(session.id!),
                              ),
                              child: const Text('Mark paid'),
                            ),
                          ],
                          onTap: () => context.push(
                              '/chargers/$chargerId/sessions/${session.id}'),
                        );
                      },
                    ),
              loading: () => prefabTheme.loadingBuilder(context),
              error: (error, stackTrace) =>
                  prefabTheme.errorBuilder(context, error, stackTrace),
            ),
          ),
          PrefabPaginationBar.controlled(
            page: sessionsAsync.valueOrNull?.page ?? 0,
            totalPages: sessionsAsync.valueOrNull?.totalPages ?? 0,
            onPageChanged: notifier.goToPage,
          ),
        ],
      ),
    );
  }
}

class ChargerStartScreen extends ConsumerStatefulWidget {
  final int id;

  const ChargerStartScreen({super.key, required this.id});

  @override
  ConsumerState<ChargerStartScreen> createState() => _ChargerStartScreenState();
}

class _ChargerStartScreenState extends ConsumerState<ChargerStartScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;
  final _formErrors = PrefabFormErrors();
  final _connectorController = TextEditingController();

  final _limitController = TextEditingController();

  @override
  void dispose() {
    _formErrors.dispose();
    _connectorController.dispose();
    _limitController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    _formErrors.clear();
    setState(() => _saving = true);
    final subscription = ref.listenManual(chargersProvider, (_, __) {});
    try {
      final parameters = StartParameters(
        connector: _connectorController.text,
        limit: _limitController.text.isEmpty
            ? null
            : int.parse(_limitController.text),
      );
      await ref.read(chargersProvider.notifier).start(widget.id, parameters);
      if (!mounted) return;
      context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _formErrors.setError(
        ref.read(prefabBackendProvider).parseError(e),
        const {'connector', 'limit'},
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
        title: const Text('Start'),
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
              field: 'connector',
              children: [
                TextFormField(
                  controller: _connectorController,
                  decoration: const InputDecoration(labelText: 'Connector'),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Required';
                    return null;
                  },
                ),
              ],
            ),
            PrefabFieldError(
              errors: _formErrors,
              field: 'limit',
              children: [
                TextFormField(
                  controller: _limitController,
                  keyboardType:
                      const TextInputType.numberWithOptions(signed: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^-?\d*$')),
                  ],
                  decoration: const InputDecoration(labelText: 'Limit (kWh)'),
                  validator: (value) {
                    if (value == null || value.isEmpty) return null;
                    if (int.tryParse(value) == null)
                      return 'Must be a whole number';
                    return null;
                  },
                ),
              ],
            ),
            prefabTheme.saveButtonBuilder(
              context,
              'Start',
              _saving ? null : _save,
              _saving,
            ),
          ],
        ),
      ),
    );
  }
}

class ChargerEditScreen extends ConsumerStatefulWidget {
  final int id;

  const ChargerEditScreen({super.key, required this.id});

  @override
  ConsumerState<ChargerEditScreen> createState() => _ChargerEditScreenState();
}

class _ChargerEditScreenState extends ConsumerState<ChargerEditScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;
  final _formErrors = PrefabFormErrors();
  bool _prefilled = false;
  // ignore: unused_field
  Charger? _item;
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _formErrors.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _prefillControllers(Charger item) {
    _item = item;
    _nameController.text = item.name;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    _formErrors.clear();
    setState(() => _saving = true);
    // Keep the (auto-dispose) provider alive while the request runs.
    final subscription = ref.listenManual(chargersProvider, (_, __) {});
    try {
      final entity = Charger(
        id: widget.id,
        name: _nameController.text,
      );
      await ref.read(chargersProvider.notifier).updateEntity(entity);
      if (!mounted) return;
      context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _formErrors.setError(
        ref.read(prefabBackendProvider).parseError(e),
        const {'name'},
      );
    } finally {
      subscription.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncItem = ref.watch(chargerDetailProvider(widget.id));
    asyncItem.whenData((item) {
      if (!_prefilled) {
        _prefilled = true;
        _prefillControllers(item);
      }
    });
    final prefabTheme = PrefabTheme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Charger'),
      ),
      body: asyncItem.when(
        loading: () => prefabTheme.loadingBuilder(context),
        error: (e, st) =>
            ref.read(prefabBackendProvider).parseError(e).isNotFound
                ? prefabTheme.notFoundBuilder(
                    context, () => context.go('/chargers'))
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

List<RouteBase> get $namedOperationsRoutes => [
      GoRoute(
        path: '/chargers',
        builder: (context, state) => const ChargerListScreen(),
        routes: [
          GoRoute(
            path: ':chargerId',
            builder: (context, state) => ChargerDetailScreen(
                id: int.parse(state.pathParameters['chargerId']!)),
            routes: [
              GoRoute(
                path: 'edit',
                builder: (context, state) => ChargerEditScreen(
                    id: int.parse(state.pathParameters['chargerId']!)),
              ),
              GoRoute(
                path: 'start',
                builder: (context, state) => ChargerStartScreen(
                    id: int.parse(state.pathParameters['chargerId']!)),
              ),
              GoRoute(
                path: 'sessions',
                builder: (context, state) => SessionListScreen(
                    chargerId: int.parse(state.pathParameters['chargerId']!)),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (context, state) => SessionDetailScreen(
                        id: int.parse(state.pathParameters['id']!),
                        chargerId:
                            int.parse(state.pathParameters['chargerId']!)),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ];
