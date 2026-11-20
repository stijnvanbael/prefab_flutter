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
import 'parent_chain.dart';

class OrderApiClient {
  final Dio _dio;
  final PrefabListAdapter _adapter;

  OrderApiClient(this._dio, [this._adapter = const PrefabListAdapter()]);

  Future<PrefabPage<Order>> list(
      {String? search,
      String? sort,
      bool descending = false,
      int page = 0,
      int? pageSize}) async {
    final response = await _dio.get(
      '/orders',
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
      Order.fromJson,
      page: page,
      pageSize: pageSize,
    );
  }

  Future<Order> getById(int id) async {
    final response = await _dio.get('/orders/$id');
    return Order.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> delete(Order order) async {
    await _dio.delete('/orders/${order.id}');
  }
}

class OrderLineApiClient {
  final Dio _dio;
  final PrefabListAdapter _adapter;

  OrderLineApiClient(this._dio, [this._adapter = const PrefabListAdapter()]);

  Future<PrefabPage<OrderLine>> list(
      {required int orderId,
      String? search,
      String? sort,
      bool descending = false,
      int page = 0,
      int? pageSize}) async {
    final response = await _dio.get(
      '/orders/$orderId/lines',
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
      OrderLine.fromJson,
      page: page,
      pageSize: pageSize,
    );
  }

  Future<OrderLine> getById(int id, {required int orderId}) async {
    final response = await _dio.get('/orders/$orderId/lines/$id');
    return OrderLine.fromJson(response.data as Map<String, dynamic>);
  }

  Future<OrderLine> create(OrderLine orderLine, {required int orderId}) async {
    final response =
        await _dio.post('/orders/$orderId/lines', data: orderLine.toJson());
    return OrderLine.fromJson(response.data as Map<String, dynamic>);
  }

  Future<OrderLine> update(OrderLine orderLine, {required int orderId}) async {
    final response = await _dio.put('/orders/$orderId/lines/${orderLine.id}',
        data: orderLine.toJson());
    return OrderLine.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> delete(OrderLine orderLine, {required int orderId}) async {
    await _dio.delete('/orders/$orderId/lines/${orderLine.id}');
  }
}

class OrderLineNoteApiClient {
  final Dio _dio;
  final PrefabListAdapter _adapter;

  OrderLineNoteApiClient(this._dio,
      [this._adapter = const PrefabListAdapter()]);

  Future<PrefabPage<OrderLineNote>> list(
      {required int orderId,
      required int orderLineId,
      String? search,
      String? sort,
      bool descending = false,
      int page = 0,
      int? pageSize}) async {
    final response = await _dio.get(
      '/orders/$orderId/lines/$orderLineId/notes',
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
      OrderLineNote.fromJson,
      page: page,
      pageSize: pageSize,
    );
  }

  Future<OrderLineNote> getById(int id,
      {required int orderId, required int orderLineId}) async {
    final response =
        await _dio.get('/orders/$orderId/lines/$orderLineId/notes/$id');
    return OrderLineNote.fromJson(response.data as Map<String, dynamic>);
  }

  Future<OrderLineNote> create(OrderLineNote orderLineNote,
      {required int orderId, required int orderLineId}) async {
    final response = await _dio.post(
        '/orders/$orderId/lines/$orderLineId/notes',
        data: orderLineNote.toJson());
    return OrderLineNote.fromJson(response.data as Map<String, dynamic>);
  }

  Future<OrderLineNote> update(OrderLineNote orderLineNote,
      {required int orderId, required int orderLineId}) async {
    final response = await _dio.put(
        '/orders/$orderId/lines/$orderLineId/notes/${orderLineNote.id}',
        data: orderLineNote.toJson());
    return OrderLineNote.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> delete(OrderLineNote orderLineNote,
      {required int orderId, required int orderLineId}) async {
    await _dio.delete(
        '/orders/$orderId/lines/$orderLineId/notes/${orderLineNote.id}');
  }
}

final orderDetailProvider = FutureProvider.autoDispose.family<Order, int>(
    (ref, id) => ref.watch(orderApiClientProvider).getById(id));

final ordersProvider =
    AsyncNotifierProvider.autoDispose<OrdersNotifier, PrefabPage<Order>>(
        OrdersNotifier.new);

class OrdersNotifier extends AutoDisposeAsyncNotifier<PrefabPage<Order>> {
  OrderApiClient get _client => ref.read(orderApiClientProvider);

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
  Future<PrefabPage<Order>> build() {
    ref.onDispose(() => _searchDebounce?.cancel());
    return _client.list(
        search: _search,
        sort: _sort,
        descending: _descending,
        page: _page,
        pageSize: _pageSize);
  }

  Future<void> _load() async {
    state = const AsyncLoading<PrefabPage<Order>>().copyWithPrevious(state);
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

final orderApiClientProvider = Provider.autoDispose<OrderApiClient>((ref) =>
    OrderApiClient(
        ref.watch(prefabDioProvider), ref.watch(prefabListAdapterProvider)));

final orderLineDetailProvider = FutureProvider.autoDispose
    .family<OrderLine, (int, int)>((ref, args) => ref
        .watch(orderLineApiClientProvider)
        .getById(args.$1, orderId: args.$2));

final orderLinesProvider = AsyncNotifierProvider.autoDispose
    .family<OrderLinesNotifier, PrefabPage<OrderLine>, int>(
        OrderLinesNotifier.new);

class OrderLinesNotifier
    extends AutoDisposeFamilyAsyncNotifier<PrefabPage<OrderLine>, int> {
  int get orderId => arg;

  OrderLineApiClient get _client => ref.read(orderLineApiClientProvider);

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
  Future<PrefabPage<OrderLine>> build(int arg) {
    ref.onDispose(() => _searchDebounce?.cancel());
    return _client.list(
        orderId: orderId,
        search: _search,
        sort: _sort,
        descending: _descending,
        page: _page,
        pageSize: _pageSize);
  }

  Future<void> _load() async {
    state = const AsyncLoading<PrefabPage<OrderLine>>().copyWithPrevious(state);
    state = await AsyncValue.guard(() => _client.list(
        orderId: orderId,
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

  Future<void> create(OrderLine orderLine) async {
    await _client.create(orderLine, orderId: orderId);
    await _load();
  }

  Future<void> updateEntity(OrderLine orderLine) async {
    await _client.update(orderLine, orderId: orderId);
    ref.invalidate(orderLineDetailProvider((orderLine.id!, orderId)));
    await _load();
  }

  Future<void> delete(OrderLine orderLine) async {
    await _client.delete(orderLine, orderId: orderId);
    ref.invalidate(orderLineDetailProvider((orderLine.id!, orderId)));
    await _load();
  }
}

final orderLineApiClientProvider = Provider.autoDispose<OrderLineApiClient>(
    (ref) => OrderLineApiClient(
        ref.watch(prefabDioProvider), ref.watch(prefabListAdapterProvider)));

final orderLineNoteDetailProvider = FutureProvider.autoDispose
    .family<OrderLineNote, (int, int, int)>((ref, args) => ref
        .watch(orderLineNoteApiClientProvider)
        .getById(args.$1, orderId: args.$2, orderLineId: args.$3));

final orderLineNotesProvider = AsyncNotifierProvider.autoDispose
    .family<OrderLineNotesNotifier, PrefabPage<OrderLineNote>, (int, int)>(
        OrderLineNotesNotifier.new);

class OrderLineNotesNotifier extends AutoDisposeFamilyAsyncNotifier<
    PrefabPage<OrderLineNote>, (int, int)> {
  int get orderId => arg.$1;
  int get orderLineId => arg.$2;

  OrderLineNoteApiClient get _client =>
      ref.read(orderLineNoteApiClientProvider);

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
  Future<PrefabPage<OrderLineNote>> build((int, int) arg) {
    ref.onDispose(() => _searchDebounce?.cancel());
    return _client.list(
        orderId: orderId,
        orderLineId: orderLineId,
        search: _search,
        sort: _sort,
        descending: _descending,
        page: _page,
        pageSize: _pageSize);
  }

  Future<void> _load() async {
    state =
        const AsyncLoading<PrefabPage<OrderLineNote>>().copyWithPrevious(state);
    state = await AsyncValue.guard(() => _client.list(
        orderId: orderId,
        orderLineId: orderLineId,
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

  Future<void> create(OrderLineNote orderLineNote) async {
    await _client.create(orderLineNote,
        orderId: orderId, orderLineId: orderLineId);
    await _load();
  }

  Future<void> updateEntity(OrderLineNote orderLineNote) async {
    await _client.update(orderLineNote,
        orderId: orderId, orderLineId: orderLineId);
    ref.invalidate(
        orderLineNoteDetailProvider((orderLineNote.id!, orderId, orderLineId)));
    await _load();
  }

  Future<void> delete(OrderLineNote orderLineNote) async {
    await _client.delete(orderLineNote,
        orderId: orderId, orderLineId: orderLineId);
    ref.invalidate(
        orderLineNoteDetailProvider((orderLineNote.id!, orderId, orderLineId)));
    await _load();
  }
}

final orderLineNoteApiClientProvider =
    Provider.autoDispose<OrderLineNoteApiClient>((ref) =>
        OrderLineNoteApiClient(ref.watch(prefabDioProvider),
            ref.watch(prefabListAdapterProvider)));

class OrderDetailScreen extends ConsumerWidget {
  final int id;

  const OrderDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderDetailProvider(id));
    final prefabTheme = PrefabTheme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order'),
      ),
      body: orderAsync.when(
        data: (order) => ListView(
          padding: prefabTheme.detailPadding,
          children: [],
        ),
        loading: () => prefabTheme.loadingBuilder(context),
        error: (error, stackTrace) =>
            prefabTheme.errorBuilder(context, error, stackTrace),
      ),
    );
  }
}

class OrderLineDetailScreen extends ConsumerWidget {
  final int id;
  final int orderId;

  const OrderLineDetailScreen(
      {super.key, required this.id, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderLineAsync = ref.watch(orderLineDetailProvider((id, orderId)));
    final prefabTheme = PrefabTheme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Line'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit',
            onPressed: () => context.push('/orders/$orderId/lines/$id/edit'),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: 'Delete',
            onPressed: orderLineAsync.hasValue
                ? () async {
                    final orderLine = orderLineAsync.value!;
                    final confirmed = await showPrefabDeleteDialog(
                      context: context,
                      item: orderLine,
                      itemLabel: orderLine.product.toString(),
                      onDelete: () => ref
                          .read(orderLinesProvider(orderId).notifier)
                          .delete(orderLine),
                    );
                    if (confirmed && context.mounted) {
                      context.pop();
                    }
                  }
                : null,
          ),
        ],
      ),
      body: orderLineAsync.when(
        data: (orderLine) => ListView(
          padding: prefabTheme.detailPadding,
          children: [
            prefabTheme.detailFieldBuilder(
              context,
              'Product',
              Text(orderLine.product.toString()),
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

class OrderLineNoteDetailScreen extends ConsumerWidget {
  final int id;
  final int orderId;
  final int orderLineId;

  const OrderLineNoteDetailScreen(
      {super.key,
      required this.id,
      required this.orderId,
      required this.orderLineId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderLineNoteAsync =
        ref.watch(orderLineNoteDetailProvider((id, orderId, orderLineId)));
    final prefabTheme = PrefabTheme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Note'),
        bottom: PrefabBreadcrumbBar(
          items: [
            PrefabBreadcrumb(
              label: ref
                      .watch(orderDetailProvider(orderId))
                      .valueOrNull
                      ?.id
                      .toString() ??
                  '…',
              onTap: () => context.go('/orders/$orderId'),
            ),
            PrefabBreadcrumb(
              label: ref
                      .watch(orderLineDetailProvider((orderLineId, orderId)))
                      .valueOrNull
                      ?.product
                      .toString() ??
                  '…',
              onTap: () => context.go('/orders/$orderId/lines/$orderLineId'),
            ),
            const PrefabBreadcrumb(label: 'Note'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit',
            onPressed: () => context
                .push('/orders/$orderId/lines/$orderLineId/notes/$id/edit'),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: 'Delete',
            onPressed: orderLineNoteAsync.hasValue
                ? () async {
                    final orderLineNote = orderLineNoteAsync.value!;
                    final confirmed = await showPrefabDeleteDialog(
                      context: context,
                      item: orderLineNote,
                      itemLabel: orderLineNote.text.toString(),
                      onDelete: () => ref
                          .read(orderLineNotesProvider((orderId, orderLineId))
                              .notifier)
                          .delete(orderLineNote),
                    );
                    if (confirmed && context.mounted) {
                      context.pop();
                    }
                  }
                : null,
          ),
        ],
      ),
      body: orderLineNoteAsync.when(
        data: (orderLineNote) => ListView(
          padding: prefabTheme.detailPadding,
          children: [
            prefabTheme.detailFieldBuilder(
              context,
              'Text',
              Text(orderLineNote.text.toString()),
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

class OrderListScreen extends ConsumerWidget {
  const OrderListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(ordersProvider);
    final notifier = ref.read(ordersProvider.notifier);
    final prefabTheme = PrefabTheme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ordersAsync.when(
              skipLoadingOnReload: true,
              data: (page) => page.items.isEmpty
                  ? prefabTheme.emptyBuilder(context)
                  : ListView.builder(
                      padding: prefabTheme.listPadding,
                      itemCount: page.items.length,
                      itemBuilder: (context, index) {
                        final order = page.items[index];
                        return ListTile(
                          onTap: () => context.push('/orders/${order.id}'),
                        );
                      },
                    ),
              loading: () => prefabTheme.loadingBuilder(context),
              error: (error, stackTrace) =>
                  prefabTheme.errorBuilder(context, error, stackTrace),
            ),
          ),
          PrefabPaginationBar.controlled(
            page: ordersAsync.valueOrNull?.page ?? 0,
            totalPages: ordersAsync.valueOrNull?.totalPages ?? 0,
            onPageChanged: notifier.goToPage,
          ),
        ],
      ),
    );
  }
}

class OrderLineListScreen extends ConsumerWidget {
  final int orderId;

  const OrderLineListScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderLinesAsync = ref.watch(orderLinesProvider(orderId));
    final notifier = ref.read(orderLinesProvider(orderId).notifier);
    final prefabTheme = PrefabTheme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Line'),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Create Order Line',
        onPressed: () async {
          await context.push('/orders/$orderId/lines/create');
          ref.invalidate(orderLinesProvider(orderId));
        },
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Expanded(
            child: orderLinesAsync.when(
              skipLoadingOnReload: true,
              data: (page) => page.items.isEmpty
                  ? prefabTheme.emptyBuilder(context)
                  : ListView.builder(
                      padding: prefabTheme.listPadding,
                      itemCount: page.items.length,
                      itemBuilder: (context, index) {
                        final orderLine = page.items[index];
                        return ListTile(
                          title: Text(orderLine.product.toString()),
                          onTap: () => context
                              .push('/orders/$orderId/lines/${orderLine.id}'),
                        );
                      },
                    ),
              loading: () => prefabTheme.loadingBuilder(context),
              error: (error, stackTrace) =>
                  prefabTheme.errorBuilder(context, error, stackTrace),
            ),
          ),
          PrefabPaginationBar.controlled(
            page: orderLinesAsync.valueOrNull?.page ?? 0,
            totalPages: orderLinesAsync.valueOrNull?.totalPages ?? 0,
            onPageChanged: notifier.goToPage,
          ),
        ],
      ),
    );
  }
}

class OrderLineNoteListScreen extends ConsumerWidget {
  final int orderId;
  final int orderLineId;

  const OrderLineNoteListScreen(
      {super.key, required this.orderId, required this.orderLineId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderLineNotesAsync =
        ref.watch(orderLineNotesProvider((orderId, orderLineId)));
    final notifier =
        ref.read(orderLineNotesProvider((orderId, orderLineId)).notifier);
    final prefabTheme = PrefabTheme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Note'),
        bottom: PrefabBreadcrumbBar(
          items: [
            PrefabBreadcrumb(
              label: ref
                      .watch(orderDetailProvider(orderId))
                      .valueOrNull
                      ?.id
                      .toString() ??
                  '…',
              onTap: () => context.go('/orders/$orderId'),
            ),
            PrefabBreadcrumb(
              label: ref
                      .watch(orderLineDetailProvider((orderLineId, orderId)))
                      .valueOrNull
                      ?.product
                      .toString() ??
                  '…',
              onTap: () => context.go('/orders/$orderId/lines/$orderLineId'),
            ),
            const PrefabBreadcrumb(label: 'Note'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Create Note',
        onPressed: () async {
          await context
              .push('/orders/$orderId/lines/$orderLineId/notes/create');
          ref.invalidate(orderLineNotesProvider((orderId, orderLineId)));
        },
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Expanded(
            child: orderLineNotesAsync.when(
              skipLoadingOnReload: true,
              data: (page) => page.items.isEmpty
                  ? prefabTheme.emptyBuilder(context)
                  : ListView.builder(
                      padding: prefabTheme.listPadding,
                      itemCount: page.items.length,
                      itemBuilder: (context, index) {
                        final orderLineNote = page.items[index];
                        return ListTile(
                          title: Text(orderLineNote.text.toString()),
                          onTap: () => context.push(
                              '/orders/$orderId/lines/$orderLineId/notes/${orderLineNote.id}'),
                        );
                      },
                    ),
              loading: () => prefabTheme.loadingBuilder(context),
              error: (error, stackTrace) =>
                  prefabTheme.errorBuilder(context, error, stackTrace),
            ),
          ),
          PrefabPaginationBar.controlled(
            page: orderLineNotesAsync.valueOrNull?.page ?? 0,
            totalPages: orderLineNotesAsync.valueOrNull?.totalPages ?? 0,
            onPageChanged: notifier.goToPage,
          ),
        ],
      ),
    );
  }
}

class OrderLineCreateScreen extends ConsumerStatefulWidget {
  final int orderId;

  const OrderLineCreateScreen({super.key, required this.orderId});

  @override
  ConsumerState<OrderLineCreateScreen> createState() =>
      _OrderLineCreateScreenState();
}

class _OrderLineCreateScreenState extends ConsumerState<OrderLineCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;
  final _productController = TextEditingController();

  @override
  void dispose() {
    _productController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    // Keep the (auto-dispose) provider alive while the request runs.
    final subscription =
        ref.listenManual(orderLinesProvider(widget.orderId), (_, __) {});
    try {
      final entity = OrderLine(
        orderId: widget.orderId,
        product: _productController.text,
      );
      await ref
          .read(orderLinesProvider(widget.orderId).notifier)
          .create(entity);
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
        title: const Text('Order Line'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: prefabTheme.formPadding,
          children: [
            TextFormField(
              controller: _productController,
              decoration: const InputDecoration(labelText: 'Product'),
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

class OrderLineEditScreen extends ConsumerStatefulWidget {
  final int id;

  final int orderId;

  const OrderLineEditScreen(
      {super.key, required this.id, required this.orderId});

  @override
  ConsumerState<OrderLineEditScreen> createState() =>
      _OrderLineEditScreenState();
}

class _OrderLineEditScreenState extends ConsumerState<OrderLineEditScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;
  bool _prefilled = false;
  // ignore: unused_field
  OrderLine? _item;
  final _productController = TextEditingController();

  @override
  void dispose() {
    _productController.dispose();
    super.dispose();
  }

  void _prefillControllers(OrderLine item) {
    _item = item;
    _productController.text = item.product;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    // Keep the (auto-dispose) provider alive while the request runs.
    final subscription =
        ref.listenManual(orderLinesProvider(widget.orderId), (_, __) {});
    try {
      final entity = OrderLine(
        id: widget.id,
        orderId: widget.orderId,
        product: _productController.text,
      );
      await ref
          .read(orderLinesProvider(widget.orderId).notifier)
          .updateEntity(entity);
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
    final asyncItem =
        ref.watch(orderLineDetailProvider((widget.id, widget.orderId)));
    asyncItem.whenData((item) {
      if (!_prefilled) {
        _prefilled = true;
        _prefillControllers(item);
      }
    });
    final prefabTheme = PrefabTheme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Line'),
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
                controller: _productController,
                decoration: const InputDecoration(labelText: 'Product'),
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

class OrderLineNoteCreateScreen extends ConsumerStatefulWidget {
  final int orderId;
  final int orderLineId;

  const OrderLineNoteCreateScreen(
      {super.key, required this.orderId, required this.orderLineId});

  @override
  ConsumerState<OrderLineNoteCreateScreen> createState() =>
      _OrderLineNoteCreateScreenState();
}

class _OrderLineNoteCreateScreenState
    extends ConsumerState<OrderLineNoteCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;
  final _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    // Keep the (auto-dispose) provider alive while the request runs.
    final subscription = ref.listenManual(
        orderLineNotesProvider((widget.orderId, widget.orderLineId)),
        (_, __) {});
    try {
      final entity = OrderLineNote(
        orderLineId: widget.orderLineId,
        text: _textController.text,
      );
      await ref
          .read(orderLineNotesProvider((widget.orderId, widget.orderLineId))
              .notifier)
          .create(entity);
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
        title: const Text('Note'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: prefabTheme.formPadding,
          children: [
            TextFormField(
              controller: _textController,
              decoration: const InputDecoration(labelText: 'Text'),
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

class OrderLineNoteEditScreen extends ConsumerStatefulWidget {
  final int id;

  final int orderId;
  final int orderLineId;

  const OrderLineNoteEditScreen(
      {super.key,
      required this.id,
      required this.orderId,
      required this.orderLineId});

  @override
  ConsumerState<OrderLineNoteEditScreen> createState() =>
      _OrderLineNoteEditScreenState();
}

class _OrderLineNoteEditScreenState
    extends ConsumerState<OrderLineNoteEditScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;
  bool _prefilled = false;
  // ignore: unused_field
  OrderLineNote? _item;
  final _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _prefillControllers(OrderLineNote item) {
    _item = item;
    _textController.text = item.text;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    // Keep the (auto-dispose) provider alive while the request runs.
    final subscription = ref.listenManual(
        orderLineNotesProvider((widget.orderId, widget.orderLineId)),
        (_, __) {});
    try {
      final entity = OrderLineNote(
        id: widget.id,
        orderLineId: widget.orderLineId,
        text: _textController.text,
      );
      await ref
          .read(orderLineNotesProvider((widget.orderId, widget.orderLineId))
              .notifier)
          .updateEntity(entity);
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
    final asyncItem = ref.watch(orderLineNoteDetailProvider(
        (widget.id, widget.orderId, widget.orderLineId)));
    asyncItem.whenData((item) {
      if (!_prefilled) {
        _prefilled = true;
        _prefillControllers(item);
      }
    });
    final prefabTheme = PrefabTheme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Note'),
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
                controller: _textController,
                decoration: const InputDecoration(labelText: 'Text'),
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

List<RouteBase> get $parentChainRoutes => [
      GoRoute(
        path: '/orders',
        builder: (context, state) => const OrderListScreen(),
        routes: [
          GoRoute(
            path: ':orderId',
            builder: (context, state) => OrderDetailScreen(
                id: int.parse(state.pathParameters['orderId']!)),
            routes: [
              GoRoute(
                path: 'lines',
                builder: (context, state) => OrderLineListScreen(
                    orderId: int.parse(state.pathParameters['orderId']!)),
                routes: [
                  GoRoute(
                    path: 'create',
                    builder: (context, state) => OrderLineCreateScreen(
                        orderId: int.parse(state.pathParameters['orderId']!)),
                  ),
                  GoRoute(
                    path: ':orderLineId',
                    builder: (context, state) => OrderLineDetailScreen(
                        id: int.parse(state.pathParameters['orderLineId']!),
                        orderId: int.parse(state.pathParameters['orderId']!)),
                    routes: [
                      GoRoute(
                        path: 'edit',
                        builder: (context, state) => OrderLineEditScreen(
                            id: int.parse(state.pathParameters['orderLineId']!),
                            orderId:
                                int.parse(state.pathParameters['orderId']!)),
                      ),
                      GoRoute(
                        path: 'notes',
                        builder: (context, state) => OrderLineNoteListScreen(
                            orderId:
                                int.parse(state.pathParameters['orderId']!),
                            orderLineId: int.parse(
                                state.pathParameters['orderLineId']!)),
                        routes: [
                          GoRoute(
                            path: 'create',
                            builder: (context, state) =>
                                OrderLineNoteCreateScreen(
                                    orderId: int.parse(
                                        state.pathParameters['orderId']!),
                                    orderLineId: int.parse(
                                        state.pathParameters['orderLineId']!)),
                          ),
                          GoRoute(
                            path: ':id',
                            builder: (context, state) =>
                                OrderLineNoteDetailScreen(
                                    id: int.parse(state.pathParameters['id']!),
                                    orderId: int.parse(
                                        state.pathParameters['orderId']!),
                                    orderLineId: int.parse(
                                        state.pathParameters['orderLineId']!)),
                            routes: [
                              GoRoute(
                                path: 'edit',
                                builder: (context, state) =>
                                    OrderLineNoteEditScreen(
                                        id: int.parse(
                                            state.pathParameters['id']!),
                                        orderId: int.parse(
                                            state.pathParameters['orderId']!),
                                        orderLineId: int.parse(state
                                            .pathParameters['orderLineId']!)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ];
