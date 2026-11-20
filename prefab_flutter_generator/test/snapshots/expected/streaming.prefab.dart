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
import 'streaming.dart';

class DeviceApiClient {
  final Dio _dio;
  final PrefabBackend _adapter;

  DeviceApiClient(this._dio, [this._adapter = const PrefabBackend()]);

  Future<PrefabPage<Device>> list(
      {String? search,
      String? sort,
      bool descending = false,
      int page = 0,
      int? pageSize}) async {
    final response = await _dio.get(
      '/devices',
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
      Device.fromJson,
      page: page,
      pageSize: pageSize,
    );
  }

  Future<Device> getById(int id) async {
    final response = await _dio.get('/devices/${_adapter.encodeId(id)}');
    return Device.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> delete(Device device) async {
    await _dio.delete('/devices/${_adapter.encodeId(device.id)}');
  }

  /// The URL of the live event stream of the collection.
  String eventsUrl() => _adapter.eventsUrl('/devices');
}

class SiteApiClient {
  final Dio _dio;
  final PrefabBackend _adapter;

  SiteApiClient(this._dio, [this._adapter = const PrefabBackend()]);

  Future<PrefabPage<Site>> list(
      {String? search,
      String? sort,
      bool descending = false,
      int page = 0,
      int? pageSize}) async {
    final response = await _dio.get(
      '/sites',
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
      Site.fromJson,
      page: page,
      pageSize: pageSize,
    );
  }

  Future<Site> getById(int id) async {
    final response = await _dio.get('/sites/${_adapter.encodeId(id)}');
    return Site.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> delete(Site site) async {
    await _dio.delete('/sites/${_adapter.encodeId(site.id)}');
  }
}

class MeasurementApiClient {
  final Dio _dio;
  final PrefabBackend _adapter;

  MeasurementApiClient(this._dio, [this._adapter = const PrefabBackend()]);

  Future<PrefabPage<Measurement>> list(
      {required int siteId,
      String? search,
      String? sort,
      bool descending = false,
      int page = 0,
      int? pageSize}) async {
    final response = await _dio.get(
      '/sites/$siteId/measurements',
      queryParameters: _adapter.queryParameters(
        search: search,
        sort: sort,
        descending: descending,
      ),
    );
    return _adapter.parsePage(
      response.data,
      Measurement.fromJson,
    );
  }

  Future<Measurement> getById(int id, {required int siteId}) async {
    final response =
        await _dio.get('/sites/$siteId/measurements/${_adapter.encodeId(id)}');
    return Measurement.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> delete(Measurement measurement, {required int siteId}) async {
    await _dio.delete(
        '/sites/$siteId/measurements/${_adapter.encodeId(measurement.id)}');
  }

  /// The URL of the live event stream of the collection.
  String eventsUrl({required int siteId}) =>
      _adapter.eventsUrl('/sites/$siteId/measurements');
}

final deviceDetailProvider =
    StreamProvider.autoDispose.family<Device, int>((ref, id) {
  final client = ref.watch(deviceApiClientProvider);
  return prefabLiveDetail<Device>(
    load: () => client.getById(id),
    events: ref.watch(prefabEventsProvider(client.eventsUrl())),
    fromJson: Device.fromJson,
    id: id,
    idKey: 'id',
  );
});

final devicesProvider =
    AsyncNotifierProvider.autoDispose<DevicesNotifier, PrefabPage<Device>>(
        DevicesNotifier.new);

class DevicesNotifier extends AutoDisposeAsyncNotifier<PrefabPage<Device>> {
  DeviceApiClient get _client => ref.read(deviceApiClientProvider);

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
  Future<PrefabPage<Device>> build() {
    ref.onDispose(() => _searchDebounce?.cancel());
    // Live updates: follow the event stream while this notifier lives.
    final events = ref.watch(prefabEventsProvider(_client.eventsUrl()));
    final subscription = events.listen(_onEvent);
    ref.onDispose(subscription.cancel);
    return _client.list(
        search: _search,
        sort: _sort,
        descending: _descending,
        page: _page,
        pageSize: _pageSize);
  }

  Future<void> _load() async {
    state = const AsyncLoading<PrefabPage<Device>>().copyWithPrevious(state);
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

  Future<void> delete(Device device) async {
    await _client.delete(device);
    ref.invalidate(deviceDetailProvider(device.id!));
    await _load();
  }

  /// Applies a live event to the loaded page. Created items that do
  /// not belong on this page are counted in `PrefabPage.newItems`.
  void _onEvent(PrefabEvent event) {
    final page = state.valueOrNull;
    if (page == null) return;
    state = AsyncData(applyPrefabEvent<Device>(
      page,
      event,
      fromJson: Device.fromJson,
      idOf: (item) => item.id,
      idKey: 'id',
      paged: true,
      canInsert: _search.isEmpty && _sort == null,
    ));
  }

  /// Reloads the list, e.g. to show the items counted in
  /// `PrefabPage.newItems`.
  Future<void> reload() => _load();
}

final deviceApiClientProvider = Provider.autoDispose<DeviceApiClient>((ref) =>
    DeviceApiClient(
        ref.watch(prefabDioProvider), ref.watch(prefabBackendProvider)));

final siteDetailProvider = FutureProvider.autoDispose.family<Site, int>(
    (ref, id) => ref.watch(siteApiClientProvider).getById(id));

final sitesProvider =
    AsyncNotifierProvider.autoDispose<SitesNotifier, PrefabPage<Site>>(
        SitesNotifier.new);

class SitesNotifier extends AutoDisposeAsyncNotifier<PrefabPage<Site>> {
  SiteApiClient get _client => ref.read(siteApiClientProvider);

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
  Future<PrefabPage<Site>> build() {
    ref.onDispose(() => _searchDebounce?.cancel());
    return _client.list(
        search: _search,
        sort: _sort,
        descending: _descending,
        page: _page,
        pageSize: _pageSize);
  }

  Future<void> _load() async {
    state = const AsyncLoading<PrefabPage<Site>>().copyWithPrevious(state);
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

final siteApiClientProvider = Provider.autoDispose<SiteApiClient>((ref) =>
    SiteApiClient(
        ref.watch(prefabDioProvider), ref.watch(prefabBackendProvider)));

final measurementDetailProvider =
    StreamProvider.autoDispose.family<Measurement, (int, int)>((ref, args) {
  final client = ref.watch(measurementApiClientProvider);
  return prefabLiveDetail<Measurement>(
    load: () => client.getById(args.$1, siteId: args.$2),
    events: ref.watch(prefabEventsProvider(client.eventsUrl(siteId: args.$2))),
    fromJson: Measurement.fromJson,
    id: args.$1,
    idKey: 'id',
  );
});

final measurementsProvider = AsyncNotifierProvider.autoDispose
    .family<MeasurementsNotifier, PrefabPage<Measurement>, int>(
        MeasurementsNotifier.new);

class MeasurementsNotifier
    extends AutoDisposeFamilyAsyncNotifier<PrefabPage<Measurement>, int> {
  int get siteId => arg;

  MeasurementApiClient get _client => ref.read(measurementApiClientProvider);

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
  Future<PrefabPage<Measurement>> build(int arg) {
    ref.onDispose(() => _searchDebounce?.cancel());
    // Live updates: follow the event stream while this notifier lives.
    final events =
        ref.watch(prefabEventsProvider(_client.eventsUrl(siteId: siteId)));
    final subscription = events.listen(_onEvent);
    ref.onDispose(subscription.cancel);
    return _client.list(
        siteId: siteId, search: _search, sort: _sort, descending: _descending);
  }

  Future<void> _load() async {
    state =
        const AsyncLoading<PrefabPage<Measurement>>().copyWithPrevious(state);
    state = await AsyncValue.guard(() => _client.list(
        siteId: siteId, search: _search, sort: _sort, descending: _descending));
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

  /// Applies a live event to the loaded page. Created items that do
  /// not belong on this page are counted in `PrefabPage.newItems`.
  void _onEvent(PrefabEvent event) {
    final page = state.valueOrNull;
    if (page == null) return;
    state = AsyncData(applyPrefabEvent<Measurement>(
      page,
      event,
      fromJson: Measurement.fromJson,
      idOf: (item) => item.id,
      idKey: 'id',
      paged: false,
      canInsert: _search.isEmpty && _sort == null,
    ));
  }

  /// Reloads the list, e.g. to show the items counted in
  /// `PrefabPage.newItems`.
  Future<void> reload() => _load();
}

final measurementApiClientProvider = Provider.autoDispose<MeasurementApiClient>(
    (ref) => MeasurementApiClient(
        ref.watch(prefabDioProvider), ref.watch(prefabBackendProvider)));

class DeviceDetailScreen extends ConsumerWidget {
  final int id;

  const DeviceDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deviceAsync = ref.watch(deviceDetailProvider(id));
    final prefabTheme = PrefabTheme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Device'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: 'Delete',
            onPressed: deviceAsync.hasValue
                ? () async {
                    final device = deviceAsync.value!;
                    final confirmed = await showPrefabDeleteDialog(
                      context: context,
                      item: device,
                      itemLabel: device.name.toString(),
                      onDelete: () =>
                          ref.read(devicesProvider.notifier).delete(device),
                    );
                    if (confirmed && context.mounted) {
                      context.pop();
                    }
                  }
                : null,
          ),
        ],
      ),
      body: deviceAsync.when(
        data: (device) => ListView(
          padding: prefabTheme.detailPadding,
          children: [
            prefabTheme.detailFieldBuilder(
              context,
              'Name',
              Text(device.name.toString()),
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

class SiteDetailScreen extends ConsumerWidget {
  final int id;

  const SiteDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final siteAsync = ref.watch(siteDetailProvider(id));
    final prefabTheme = PrefabTheme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Site'),
      ),
      body: siteAsync.when(
        data: (site) => ListView(
          padding: prefabTheme.detailPadding,
          children: [
            prefabTheme.detailFieldBuilder(
              context,
              'Name',
              Text(site.name.toString()),
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

class MeasurementDetailScreen extends ConsumerWidget {
  final int id;
  final int siteId;

  const MeasurementDetailScreen(
      {super.key, required this.id, required this.siteId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final measurementAsync = ref.watch(measurementDetailProvider((id, siteId)));
    final prefabTheme = PrefabTheme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Measurement'),
      ),
      body: measurementAsync.when(
        data: (measurement) => ListView(
          padding: prefabTheme.detailPadding,
          children: [
            prefabTheme.detailFieldBuilder(
              context,
              'Value',
              Text(measurement.value.toString()),
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

class DeviceListScreen extends ConsumerWidget {
  const DeviceListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devicesAsync = ref.watch(devicesProvider);
    final notifier = ref.read(devicesProvider.notifier);
    final prefabTheme = PrefabTheme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Device'),
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
          if ((devicesAsync.valueOrNull?.newItems ?? 0) > 0)
            PrefabNewItemsBanner(
              count: devicesAsync.requireValue.newItems,
              onRefresh: ref.read(devicesProvider.notifier).reload,
            ),
          Expanded(
            child: devicesAsync.when(
              skipLoadingOnReload: true,
              data: (page) => page.items.isEmpty
                  ? prefabTheme.emptyBuilder(context)
                  : ListView.builder(
                      padding: prefabTheme.listPadding,
                      itemCount: page.items.length,
                      itemBuilder: (context, index) {
                        final device = page.items[index];
                        return prefabTheme.listItemBuilder(
                          context,
                          title: Text(device.name.toString()),
                          subtitle: null,
                          trailing: null,
                          actions: const [],
                          onTap: () => context.push('/devices/${device.id}'),
                        );
                      },
                    ),
              loading: () => prefabTheme.loadingBuilder(context),
              error: (error, stackTrace) =>
                  prefabTheme.errorBuilder(context, error, stackTrace),
            ),
          ),
          PrefabPaginationBar.controlled(
            page: devicesAsync.valueOrNull?.page ?? 0,
            totalPages: devicesAsync.valueOrNull?.totalPages ?? 0,
            onPageChanged: notifier.goToPage,
          ),
        ],
      ),
    );
  }
}

class SiteListScreen extends ConsumerWidget {
  const SiteListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sitesAsync = ref.watch(sitesProvider);
    final notifier = ref.read(sitesProvider.notifier);
    final prefabTheme = PrefabTheme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Site'),
      ),
      body: Column(
        children: [
          Expanded(
            child: sitesAsync.when(
              skipLoadingOnReload: true,
              data: (page) => page.items.isEmpty
                  ? prefabTheme.emptyBuilder(context)
                  : ListView.builder(
                      padding: prefabTheme.listPadding,
                      itemCount: page.items.length,
                      itemBuilder: (context, index) {
                        final site = page.items[index];
                        return prefabTheme.listItemBuilder(
                          context,
                          title: Text(site.name.toString()),
                          subtitle: null,
                          trailing: null,
                          actions: const [],
                          onTap: () => context.push('/sites/${site.id}'),
                        );
                      },
                    ),
              loading: () => prefabTheme.loadingBuilder(context),
              error: (error, stackTrace) =>
                  prefabTheme.errorBuilder(context, error, stackTrace),
            ),
          ),
          PrefabPaginationBar.controlled(
            page: sitesAsync.valueOrNull?.page ?? 0,
            totalPages: sitesAsync.valueOrNull?.totalPages ?? 0,
            onPageChanged: notifier.goToPage,
          ),
        ],
      ),
    );
  }
}

class MeasurementListScreen extends ConsumerWidget {
  final int siteId;

  const MeasurementListScreen({super.key, required this.siteId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final measurementsAsync = ref.watch(measurementsProvider(siteId));
    final prefabTheme = PrefabTheme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Measurement'),
      ),
      body: Column(
        children: [
          if ((measurementsAsync.valueOrNull?.newItems ?? 0) > 0)
            PrefabNewItemsBanner(
              count: measurementsAsync.requireValue.newItems,
              onRefresh: ref.read(measurementsProvider(siteId).notifier).reload,
            ),
          Expanded(
            child: measurementsAsync.when(
              skipLoadingOnReload: true,
              data: (page) => page.items.isEmpty
                  ? prefabTheme.emptyBuilder(context)
                  : ListView.builder(
                      padding: prefabTheme.listPadding,
                      itemCount: page.items.length,
                      itemBuilder: (context, index) {
                        final measurement = page.items[index];
                        return prefabTheme.listItemBuilder(
                          context,
                          title: Text(measurement.value.toString()),
                          subtitle: null,
                          trailing: null,
                          actions: const [],
                          onTap: () => context.push(
                              '/sites/$siteId/measurements/${measurement.id}'),
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

List<RouteBase> get $streamingRoutes => [
      GoRoute(
        path: '/devices',
        builder: (context, state) => const DeviceListScreen(),
        routes: [
          GoRoute(
            path: ':id',
            builder: (context, state) =>
                DeviceDetailScreen(id: int.parse(state.pathParameters['id']!)),
          ),
        ],
      ),
      GoRoute(
        path: '/sites',
        builder: (context, state) => const SiteListScreen(),
        routes: [
          GoRoute(
            path: ':siteId',
            builder: (context, state) => SiteDetailScreen(
                id: int.parse(state.pathParameters['siteId']!)),
            routes: [
              GoRoute(
                path: 'measurements',
                builder: (context, state) => MeasurementListScreen(
                    siteId: int.parse(state.pathParameters['siteId']!)),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (context, state) => MeasurementDetailScreen(
                        id: int.parse(state.pathParameters['id']!),
                        siteId: int.parse(state.pathParameters['siteId']!)),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ];
