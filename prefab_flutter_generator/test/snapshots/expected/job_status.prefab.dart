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
import 'job_status.dart';

class SummaryApiClient {
  final Dio _dio;
  final PrefabBackend _adapter;

  SummaryApiClient(this._dio, [this._adapter = const PrefabBackend()]);

  Future<PrefabPage<Summary>> list(
      {String? search,
      String? sort,
      bool descending = false,
      int page = 0,
      int? pageSize}) async {
    final response = await _dio.get(
      '/summaries',
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
      Summary.fromJson,
      page: page,
      pageSize: pageSize,
    );
  }

  Future<Summary> getById(int id) async {
    final response = await _dio.get('/summaries/${_adapter.encodeId(id)}');
    return Summary.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Summary> create(Summary summary) async {
    final response = await _dio.post('/summaries', data: _createBody(summary));
    return Summary.fromJson(response.data as Map<String, dynamic>);
  }

  /// Only the fields of the create form (and the parent id).
  Map<String, dynamic> _createBody(Summary summary) => {
        for (final e in summary.toJson().entries)
          if (const <String>{'title'}.contains(e.key)) e.key: e.value,
      };

  Future<void> delete(Summary summary) async {
    await _dio.delete('/summaries/${_adapter.encodeId(summary.id)}');
  }

  Future<void> regenerate(int id) async {
    await _dio.request<void>(
      '/summaries/${_adapter.encodeId(id)}/regenerate',
      data: _adapter.operationBody(null),
      options: Options(method: _adapter.operationMethod),
    );
  }
}

class SourceApiClient {
  final Dio _dio;
  final PrefabBackend _adapter;

  SourceApiClient(this._dio, [this._adapter = const PrefabBackend()]);

  Future<PrefabPage<Source>> list(
      {String? search,
      String? sort,
      bool descending = false,
      int page = 0,
      int? pageSize}) async {
    final response = await _dio.get(
      '/sources',
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
      Source.fromJson,
      page: page,
      pageSize: pageSize,
    );
  }

  Future<Source> getById(int id) async {
    final response = await _dio.get('/sources/${_adapter.encodeId(id)}');
    return Source.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> delete(Source source) async {
    await _dio.delete('/sources/${_adapter.encodeId(source.id)}');
  }
}

class UploadApiClient {
  final Dio _dio;
  final PrefabBackend _adapter;

  UploadApiClient(this._dio, [this._adapter = const PrefabBackend()]);

  Future<PrefabPage<Upload>> list(
      {required int sourceId,
      String? search,
      String? sort,
      bool descending = false,
      int page = 0,
      int? pageSize}) async {
    final response = await _dio.get(
      '/sources/$sourceId/uploads',
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
      Upload.fromJson,
      page: page,
      pageSize: pageSize,
    );
  }

  Future<Upload> getById(int id, {required int sourceId}) async {
    final response =
        await _dio.get('/sources/$sourceId/uploads/${_adapter.encodeId(id)}');
    return Upload.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> delete(Upload upload, {required int sourceId}) async {
    await _dio
        .delete('/sources/$sourceId/uploads/${_adapter.encodeId(upload.id)}');
  }
}

class RenderApiClient {
  final Dio _dio;
  final PrefabBackend _adapter;

  RenderApiClient(this._dio, [this._adapter = const PrefabBackend()]);

  Future<PrefabPage<Render>> list(
      {String? search,
      String? sort,
      bool descending = false,
      int page = 0,
      int? pageSize}) async {
    final response = await _dio.get(
      '/renders',
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
      Render.fromJson,
      page: page,
      pageSize: pageSize,
    );
  }

  Future<Render> getById(int id) async {
    final response = await _dio.get('/renders/${_adapter.encodeId(id)}');
    return Render.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> delete(Render render) async {
    await _dio.delete('/renders/${_adapter.encodeId(render.id)}');
  }

  /// The URL of the live event stream of the collection.
  String eventsUrl() => _adapter.eventsUrl('/renders');
}

final summaryDetailProvider =
    StreamProvider.autoDispose.family<Summary, int>((ref, id) {
  final client = ref.watch(summaryApiClientProvider);
  return prefabPolledDetail<Summary>(
    load: () => client.getById(id),
    isRunning: (summary) =>
        summary.status == SummaryStatus.queued ||
        summary.status == SummaryStatus.running,
    interval: const Duration(seconds: 3),
  );
});

final summarysProvider =
    AsyncNotifierProvider.autoDispose<SummarysNotifier, PrefabPage<Summary>>(
        SummarysNotifier.new);

class SummarysNotifier extends AutoDisposeAsyncNotifier<PrefabPage<Summary>> {
  SummaryApiClient get _client => ref.read(summaryApiClientProvider);

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

  /// Refreshes the page while one of its jobs runs.
  late final _jobPoller = PrefabJobPoller(
    interval: const Duration(seconds: 3),
    isRunning: () =>
        state.valueOrNull?.items.any((item) =>
            item.status == SummaryStatus.queued ||
            item.status == SummaryStatus.running) ??
        false,
    refresh: _refreshJobs,
  );

  @override
  Future<PrefabPage<Summary>> build() {
    ref.onDispose(() => _searchDebounce?.cancel());
    // Job status: poll while an item is running.
    ref.onDispose(_jobPoller.cancel);
    listenSelf((previous, next) => _jobPoller.check());
    return _client.list(
        search: _search,
        sort: _sort,
        descending: _descending,
        page: _page,
        pageSize: _pageSize);
  }

  Future<void> _load() async {
    state = const AsyncLoading<PrefabPage<Summary>>().copyWithPrevious(state);
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

  Future<void> create(Summary summary) async {
    await _client.create(summary);
    await _load();
  }

  Future<void> regenerate(int id) async {
    await _client.regenerate(id);
    ref.invalidate(summaryDetailProvider(id));
    await _load();
  }

  /// Loads the page again without a loading state (job polling).
  Future<void> _refreshJobs() async {
    state = AsyncData(await _client.list(
        search: _search,
        sort: _sort,
        descending: _descending,
        page: _page,
        pageSize: _pageSize));
  }
}

final summaryApiClientProvider = Provider.autoDispose<SummaryApiClient>((ref) =>
    SummaryApiClient(
        ref.watch(prefabDioProvider), ref.watch(prefabBackendProvider)));

final sourceDetailProvider = FutureProvider.autoDispose.family<Source, int>(
    (ref, id) => ref.watch(sourceApiClientProvider).getById(id));

final sourcesProvider =
    AsyncNotifierProvider.autoDispose<SourcesNotifier, PrefabPage<Source>>(
        SourcesNotifier.new);

class SourcesNotifier extends AutoDisposeAsyncNotifier<PrefabPage<Source>> {
  SourceApiClient get _client => ref.read(sourceApiClientProvider);

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
  Future<PrefabPage<Source>> build() {
    ref.onDispose(() => _searchDebounce?.cancel());
    return _client.list(
        search: _search,
        sort: _sort,
        descending: _descending,
        page: _page,
        pageSize: _pageSize);
  }

  Future<void> _load() async {
    state = const AsyncLoading<PrefabPage<Source>>().copyWithPrevious(state);
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

final sourceApiClientProvider = Provider.autoDispose<SourceApiClient>((ref) =>
    SourceApiClient(
        ref.watch(prefabDioProvider), ref.watch(prefabBackendProvider)));

final uploadDetailProvider =
    StreamProvider.autoDispose.family<Upload, (int, int)>((ref, args) {
  final client = ref.watch(uploadApiClientProvider);
  return prefabPolledDetail<Upload>(
    load: () => client.getById(args.$1, sourceId: args.$2),
    isRunning: (upload) =>
        upload.phase == UploadPhase.uploading ||
        upload.phase == UploadPhase.parsing,
    interval: const Duration(milliseconds: 1500),
  );
});

final uploadsProvider = AsyncNotifierProvider.autoDispose
    .family<UploadsNotifier, PrefabPage<Upload>, int>(UploadsNotifier.new);

class UploadsNotifier
    extends AutoDisposeFamilyAsyncNotifier<PrefabPage<Upload>, int> {
  int get sourceId => arg;

  UploadApiClient get _client => ref.read(uploadApiClientProvider);

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

  /// Refreshes the page while one of its jobs runs.
  late final _jobPoller = PrefabJobPoller(
    interval: const Duration(milliseconds: 1500),
    isRunning: () =>
        state.valueOrNull?.items.any((item) =>
            item.phase == UploadPhase.uploading ||
            item.phase == UploadPhase.parsing) ??
        false,
    refresh: _refreshJobs,
  );

  @override
  Future<PrefabPage<Upload>> build(int arg) {
    ref.onDispose(() => _searchDebounce?.cancel());
    // Job status: poll while an item is running.
    ref.onDispose(_jobPoller.cancel);
    listenSelf((previous, next) => _jobPoller.check());
    return _client.list(
        sourceId: sourceId,
        search: _search,
        sort: _sort,
        descending: _descending,
        page: _page,
        pageSize: _pageSize);
  }

  Future<void> _load() async {
    state = const AsyncLoading<PrefabPage<Upload>>().copyWithPrevious(state);
    state = await AsyncValue.guard(() => _client.list(
        sourceId: sourceId,
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

  /// Loads the page again without a loading state (job polling).
  Future<void> _refreshJobs() async {
    state = AsyncData(await _client.list(
        sourceId: sourceId,
        search: _search,
        sort: _sort,
        descending: _descending,
        page: _page,
        pageSize: _pageSize));
  }
}

final uploadApiClientProvider = Provider.autoDispose<UploadApiClient>((ref) =>
    UploadApiClient(
        ref.watch(prefabDioProvider), ref.watch(prefabBackendProvider)));

final renderDetailProvider =
    StreamProvider.autoDispose.family<Render, int>((ref, id) {
  final client = ref.watch(renderApiClientProvider);
  return prefabLiveDetail<Render>(
    load: () => client.getById(id),
    events: ref.watch(prefabEventsProvider(client.eventsUrl())),
    fromJson: Render.fromJson,
    id: id,
    idKey: 'id',
  );
});

final rendersProvider =
    AsyncNotifierProvider.autoDispose<RendersNotifier, PrefabPage<Render>>(
        RendersNotifier.new);

class RendersNotifier extends AutoDisposeAsyncNotifier<PrefabPage<Render>> {
  RenderApiClient get _client => ref.read(renderApiClientProvider);

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
  Future<PrefabPage<Render>> build() {
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
    state = const AsyncLoading<PrefabPage<Render>>().copyWithPrevious(state);
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

  /// Applies a live event to the loaded page. Created items that do
  /// not belong on this page are counted in `PrefabPage.newItems`.
  /// After a reconnect the list is reloaded: events may have been missed.
  void _onEvent(PrefabEvent event) {
    if (event.type == PrefabEventType.reconnected) {
      if (!state.isLoading) _load();
      return;
    }
    final page = state.valueOrNull;
    if (page == null) return;
    state = AsyncData(applyPrefabEvent<Render>(
      page,
      event,
      fromJson: Render.fromJson,
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

final renderApiClientProvider = Provider.autoDispose<RenderApiClient>((ref) =>
    RenderApiClient(
        ref.watch(prefabDioProvider), ref.watch(prefabBackendProvider)));

class SummaryDetailScreen extends ConsumerWidget {
  final int id;

  const SummaryDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(summaryDetailProvider(id));
    final prefabTheme = PrefabTheme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Summary'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Regenerate',
            onPressed: summaryAsync.hasValue
                ? () => runPrefabOperation(
                      context: context,
                      backend: ref.read(prefabBackendProvider),
                      label: 'Regenerate',
                      run: () =>
                          ref.read(summarysProvider.notifier).regenerate(id),
                    )
                : null,
          ),
        ],
      ),
      body: summaryAsync.when(
        data: (summary) => ListView(
          padding: prefabTheme.detailPadding,
          children: [
            PrefabJobBanner(
              state: switch (summary.status) {
                SummaryStatus.queued ||
                SummaryStatus.running =>
                  PrefabJobState.running,
                SummaryStatus.done => PrefabJobState.done,
                SummaryStatus.failed => PrefabJobState.failed,
              },
              message: summary.error,
            ),
            prefabTheme.detailFieldBuilder(
              context,
              'Title',
              Text(summary.title.toString()),
            ),
            prefabTheme.detailFieldBuilder(
              context,
              'Status',
              Text(summary.status.toString()),
            ),
            prefabTheme.detailFieldBuilder(
              context,
              'Error',
              Text(summary.error?.toString() ?? '—'),
            ),
          ],
        ),
        loading: () => prefabTheme.loadingBuilder(context),
        error: (error, stackTrace) =>
            ref.read(prefabBackendProvider).parseError(error).isNotFound
                ? prefabTheme.notFoundBuilder(
                    context, () => context.go('/summaries'))
                : prefabTheme.errorBuilder(context, error, stackTrace),
      ),
    );
  }
}

class SourceDetailScreen extends ConsumerWidget {
  final int id;

  const SourceDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sourceAsync = ref.watch(sourceDetailProvider(id));
    final prefabTheme = PrefabTheme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Source'),
      ),
      body: sourceAsync.when(
        data: (source) => ListView(
          padding: prefabTheme.detailPadding,
          children: [
            prefabTheme.detailFieldBuilder(
              context,
              'Name',
              Text(source.name.toString()),
            ),
          ],
        ),
        loading: () => prefabTheme.loadingBuilder(context),
        error: (error, stackTrace) => ref
                .read(prefabBackendProvider)
                .parseError(error)
                .isNotFound
            ? prefabTheme.notFoundBuilder(context, () => context.go('/sources'))
            : prefabTheme.errorBuilder(context, error, stackTrace),
      ),
    );
  }
}

class UploadDetailScreen extends ConsumerWidget {
  final int id;
  final int sourceId;

  const UploadDetailScreen(
      {super.key, required this.id, required this.sourceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uploadAsync = ref.watch(uploadDetailProvider((id, sourceId)));
    final prefabTheme = PrefabTheme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload'),
      ),
      body: uploadAsync.when(
        data: (upload) => ListView(
          padding: prefabTheme.detailPadding,
          children: [
            PrefabJobBanner(
              state: switch (upload.phase) {
                UploadPhase.uploading ||
                UploadPhase.parsing =>
                  PrefabJobState.running,
                UploadPhase.imported => PrefabJobState.done,
                UploadPhase.rejected ||
                UploadPhase.cancelled =>
                  PrefabJobState.failed,
              },
              message: upload.reason,
            ),
            prefabTheme.detailFieldBuilder(
              context,
              'Phase',
              Text(upload.phase.toString()),
            ),
          ],
        ),
        loading: () => prefabTheme.loadingBuilder(context),
        error: (error, stackTrace) =>
            ref.read(prefabBackendProvider).parseError(error).isNotFound
                ? prefabTheme.notFoundBuilder(
                    context, () => context.go('/sources/$sourceId/uploads'))
                : prefabTheme.errorBuilder(context, error, stackTrace),
      ),
    );
  }
}

class RenderDetailScreen extends ConsumerWidget {
  final int id;

  const RenderDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final renderAsync = ref.watch(renderDetailProvider(id));
    final prefabTheme = PrefabTheme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Render'),
      ),
      body: renderAsync.when(
        data: (render) => ListView(
          padding: prefabTheme.detailPadding,
          children: [
            PrefabJobBanner(
              state: switch (render.state) {
                SummaryStatus.queued ||
                SummaryStatus.running =>
                  PrefabJobState.running,
                SummaryStatus.done => PrefabJobState.done,
                SummaryStatus.failed => PrefabJobState.failed,
              },
              message: null,
            ),
            prefabTheme.detailFieldBuilder(
              context,
              'Name',
              Text(render.name.toString()),
            ),
            prefabTheme.detailFieldBuilder(
              context,
              'State',
              Text(render.state.toString()),
            ),
          ],
        ),
        loading: () => prefabTheme.loadingBuilder(context),
        error: (error, stackTrace) => ref
                .read(prefabBackendProvider)
                .parseError(error)
                .isNotFound
            ? prefabTheme.notFoundBuilder(context, () => context.go('/renders'))
            : prefabTheme.errorBuilder(context, error, stackTrace),
      ),
    );
  }
}

class SummaryListScreen extends ConsumerWidget {
  const SummaryListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summarysAsync = ref.watch(summarysProvider);
    final notifier = ref.read(summarysProvider.notifier);
    final prefabTheme = PrefabTheme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Summary'),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Create Summary',
        onPressed: () async {
          await context.push('/summaries/create');
          ref.invalidate(summarysProvider);
        },
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Expanded(
            child: summarysAsync.when(
              skipLoadingOnReload: true,
              data: (page) => page.items.isEmpty
                  ? prefabTheme.emptyBuilder(context)
                  : ListView.builder(
                      padding: prefabTheme.listPadding,
                      itemCount: page.items.length,
                      itemBuilder: (context, index) {
                        final summary = page.items[index];
                        return prefabTheme.listItemBuilder(
                          context,
                          title: Text(summary.title.toString()),
                          subtitle: null,
                          trailing:
                              Row(mainAxisSize: MainAxisSize.min, children: [
                            PrefabJobIndicator(
                                state: switch (summary.status) {
                              SummaryStatus.queued ||
                              SummaryStatus.running =>
                                PrefabJobState.running,
                              SummaryStatus.done => PrefabJobState.done,
                              SummaryStatus.failed => PrefabJobState.failed,
                            }),
                          ]),
                          actions: [
                            PopupMenuItem<void>(
                              onTap: () => runPrefabOperation(
                                context: context,
                                backend: ref.read(prefabBackendProvider),
                                label: 'Regenerate',
                                run: () => ref
                                    .read(summarysProvider.notifier)
                                    .regenerate(summary.id!),
                              ).then((started) {
                                if (started == true && context.mounted) {
                                  context.push('/summaries/${summary.id!}');
                                }
                              }),
                              child: const Row(
                                children: [
                                  Icon(Icons.refresh),
                                  SizedBox(width: 8),
                                  Text('Regenerate'),
                                ],
                              ),
                            ),
                          ],
                          onTap: () => context.push('/summaries/${summary.id}'),
                        );
                      },
                    ),
              loading: () => prefabTheme.loadingBuilder(context),
              error: (error, stackTrace) =>
                  prefabTheme.errorBuilder(context, error, stackTrace),
            ),
          ),
          PrefabPaginationBar.controlled(
            page: summarysAsync.valueOrNull?.page ?? 0,
            totalPages: summarysAsync.valueOrNull?.totalPages ?? 0,
            onPageChanged: notifier.goToPage,
          ),
        ],
      ),
    );
  }
}

class SourceListScreen extends ConsumerWidget {
  const SourceListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sourcesAsync = ref.watch(sourcesProvider);
    final notifier = ref.read(sourcesProvider.notifier);
    final prefabTheme = PrefabTheme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Source'),
      ),
      body: Column(
        children: [
          Expanded(
            child: sourcesAsync.when(
              skipLoadingOnReload: true,
              data: (page) => page.items.isEmpty
                  ? prefabTheme.emptyBuilder(context)
                  : ListView.builder(
                      padding: prefabTheme.listPadding,
                      itemCount: page.items.length,
                      itemBuilder: (context, index) {
                        final source = page.items[index];
                        return prefabTheme.listItemBuilder(
                          context,
                          title: Text(source.name.toString()),
                          subtitle: null,
                          trailing: null,
                          actions: const [],
                          onTap: () => context.push('/sources/${source.id}'),
                        );
                      },
                    ),
              loading: () => prefabTheme.loadingBuilder(context),
              error: (error, stackTrace) =>
                  prefabTheme.errorBuilder(context, error, stackTrace),
            ),
          ),
          PrefabPaginationBar.controlled(
            page: sourcesAsync.valueOrNull?.page ?? 0,
            totalPages: sourcesAsync.valueOrNull?.totalPages ?? 0,
            onPageChanged: notifier.goToPage,
          ),
        ],
      ),
    );
  }
}

class UploadListScreen extends ConsumerWidget {
  final int sourceId;

  const UploadListScreen({super.key, required this.sourceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uploadsAsync = ref.watch(uploadsProvider(sourceId));
    final notifier = ref.read(uploadsProvider(sourceId).notifier);
    final prefabTheme = PrefabTheme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload'),
      ),
      body: Column(
        children: [
          Expanded(
            child: uploadsAsync.when(
              skipLoadingOnReload: true,
              data: (page) => page.items.isEmpty
                  ? prefabTheme.emptyBuilder(context)
                  : ListView.builder(
                      padding: prefabTheme.listPadding,
                      itemCount: page.items.length,
                      itemBuilder: (context, index) {
                        final upload = page.items[index];
                        return prefabTheme.listItemBuilder(
                          context,
                          title: Text(upload.phase.toString()),
                          subtitle: null,
                          trailing:
                              Row(mainAxisSize: MainAxisSize.min, children: [
                            PrefabJobIndicator(
                                state: switch (upload.phase) {
                              UploadPhase.uploading ||
                              UploadPhase.parsing =>
                                PrefabJobState.running,
                              UploadPhase.imported => PrefabJobState.done,
                              UploadPhase.rejected ||
                              UploadPhase.cancelled =>
                                PrefabJobState.failed,
                            }),
                          ]),
                          actions: const [],
                          onTap: () => context
                              .push('/sources/$sourceId/uploads/${upload.id}'),
                        );
                      },
                    ),
              loading: () => prefabTheme.loadingBuilder(context),
              error: (error, stackTrace) =>
                  prefabTheme.errorBuilder(context, error, stackTrace),
            ),
          ),
          PrefabPaginationBar.controlled(
            page: uploadsAsync.valueOrNull?.page ?? 0,
            totalPages: uploadsAsync.valueOrNull?.totalPages ?? 0,
            onPageChanged: notifier.goToPage,
          ),
        ],
      ),
    );
  }
}

class RenderListScreen extends ConsumerWidget {
  const RenderListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rendersAsync = ref.watch(rendersProvider);
    final notifier = ref.read(rendersProvider.notifier);
    final prefabTheme = PrefabTheme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Render'),
      ),
      body: Column(
        children: [
          if ((rendersAsync.valueOrNull?.newItems ?? 0) > 0)
            PrefabNewItemsBanner(
              count: rendersAsync.requireValue.newItems,
              onRefresh: ref.read(rendersProvider.notifier).reload,
            ),
          Expanded(
            child: rendersAsync.when(
              skipLoadingOnReload: true,
              data: (page) => page.items.isEmpty
                  ? prefabTheme.emptyBuilder(context)
                  : ListView.builder(
                      padding: prefabTheme.listPadding,
                      itemCount: page.items.length,
                      itemBuilder: (context, index) {
                        final render = page.items[index];
                        return prefabTheme.listItemBuilder(
                          context,
                          title: Text(render.name.toString()),
                          subtitle: null,
                          trailing:
                              Row(mainAxisSize: MainAxisSize.min, children: [
                            PrefabJobIndicator(
                                state: switch (render.state) {
                              SummaryStatus.queued ||
                              SummaryStatus.running =>
                                PrefabJobState.running,
                              SummaryStatus.done => PrefabJobState.done,
                              SummaryStatus.failed => PrefabJobState.failed,
                            }),
                          ]),
                          actions: const [],
                          onTap: () => context.push('/renders/${render.id}'),
                        );
                      },
                    ),
              loading: () => prefabTheme.loadingBuilder(context),
              error: (error, stackTrace) =>
                  prefabTheme.errorBuilder(context, error, stackTrace),
            ),
          ),
          PrefabPaginationBar.controlled(
            page: rendersAsync.valueOrNull?.page ?? 0,
            totalPages: rendersAsync.valueOrNull?.totalPages ?? 0,
            onPageChanged: notifier.goToPage,
          ),
        ],
      ),
    );
  }
}

class SummaryCreateScreen extends ConsumerStatefulWidget {
  const SummaryCreateScreen({super.key});

  @override
  ConsumerState<SummaryCreateScreen> createState() =>
      _SummaryCreateScreenState();
}

class _SummaryCreateScreenState extends ConsumerState<SummaryCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;
  final _formErrors = PrefabFormErrors();
  final _titleController = TextEditingController();

  @override
  void dispose() {
    _formErrors.dispose();
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    _formErrors.clear();
    setState(() => _saving = true);
    // Keep the (auto-dispose) provider alive while the request runs.
    final subscription = ref.listenManual(summarysProvider, (_, __) {});
    try {
      final entity = Summary(
        title: _titleController.text,
        status: SummaryStatus.values.first,
      );
      await ref.read(summarysProvider.notifier).create(entity);
      if (!mounted) return;
      context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _formErrors.setError(
        ref.read(prefabBackendProvider).parseError(e),
        const {'title'},
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
        title: const Text('Summary'),
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
              field: 'title',
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Required';
                    return null;
                  },
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

List<RouteBase> get $jobStatusRoutes => [
      GoRoute(
        path: '/summaries',
        builder: (context, state) => const SummaryListScreen(),
        routes: [
          GoRoute(
            path: 'create',
            builder: (context, state) => const SummaryCreateScreen(),
          ),
          GoRoute(
            path: ':id',
            builder: (context, state) =>
                SummaryDetailScreen(id: int.parse(state.pathParameters['id']!)),
          ),
        ],
      ),
      GoRoute(
        path: '/sources',
        builder: (context, state) => const SourceListScreen(),
        routes: [
          GoRoute(
            path: ':sourceId',
            builder: (context, state) => SourceDetailScreen(
                id: int.parse(state.pathParameters['sourceId']!)),
            routes: [
              GoRoute(
                path: 'uploads',
                builder: (context, state) => UploadListScreen(
                    sourceId: int.parse(state.pathParameters['sourceId']!)),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (context, state) => UploadDetailScreen(
                        id: int.parse(state.pathParameters['id']!),
                        sourceId: int.parse(state.pathParameters['sourceId']!)),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/renders',
        builder: (context, state) => const RenderListScreen(),
        routes: [
          GoRoute(
            path: ':id',
            builder: (context, state) =>
                RenderDetailScreen(id: int.parse(state.pathParameters['id']!)),
          ),
        ],
      ),
    ];
