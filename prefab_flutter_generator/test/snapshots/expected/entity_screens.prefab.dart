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

import 'package:a/order_line_picking_screen.dart';
import 'package:a/order_live_screen.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:prefab_flutter_widgets/prefab_flutter_widgets.dart';

import 'dart:async';
import 'entity_screens.dart';

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

  Future<Order> update(Order order) async {
    final response =
        await _dio.put('/orders/${order.id}', data: order.toJson());
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

  Future<void> delete(OrderLine orderLine, {required int orderId}) async {
    await _dio.delete('/orders/$orderId/lines/${orderLine.id}');
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

  Future<void> updateEntity(Order order) async {
    await _client.update(order);
    ref.invalidate(orderDetailProvider(order.id));
    await _load();
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
}

final orderLineApiClientProvider = Provider.autoDispose<OrderLineApiClient>(
    (ref) => OrderLineApiClient(
        ref.watch(prefabDioProvider), ref.watch(prefabListAdapterProvider)));

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
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit',
            onPressed: () => context.push('/orders/$id/edit'),
          ),
        ],
      ),
      body: orderAsync.when(
        data: (order) => ListView(
          padding: prefabTheme.detailPadding,
          children: [
            prefabTheme.detailFieldBuilder(
              context,
              'Number',
              Text(order.number?.toString() ?? '—'),
            ),
            ListTile(
              title: const Text('Live'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/orders/$id/live'),
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
            ListTile(
              title: const Text('Picking list'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/orders/$orderId/lines/$id/picking'),
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
                        return prefabTheme.listItemBuilder(
                          context,
                          title: Text(order.number?.toString() ?? '—'),
                          subtitle: null,
                          trailing: null,
                          actions: [
                            PopupMenuItem<void>(
                              onTap: () =>
                                  context.push('/orders/${order.id}/live'),
                              child: const Text('Live'),
                            ),
                          ],
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
                        return prefabTheme.listItemBuilder(
                          context,
                          title: Text(orderLine.product.toString()),
                          subtitle: null,
                          trailing: null,
                          actions: [
                            PopupMenuItem<void>(
                              onTap: () => context.push(
                                  '/orders/$orderId/lines/${orderLine.id}/picking'),
                              child: const Text('Picking list'),
                            ),
                          ],
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

class OrderEditScreen extends ConsumerStatefulWidget {
  final int id;

  const OrderEditScreen({super.key, required this.id});

  @override
  ConsumerState<OrderEditScreen> createState() => _OrderEditScreenState();
}

class _OrderEditScreenState extends ConsumerState<OrderEditScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;
  bool _prefilled = false;
  // ignore: unused_field
  Order? _item;
  final _numberController = TextEditingController();

  @override
  void dispose() {
    _numberController.dispose();
    super.dispose();
  }

  void _prefillControllers(Order item) {
    _item = item;
    _numberController.text = item.number ?? '';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    // Keep the (auto-dispose) provider alive while the request runs.
    final subscription = ref.listenManual(ordersProvider, (_, __) {});
    try {
      final entity = Order(
        id: widget.id,
        number: _numberController.text.isEmpty ? null : _numberController.text,
      );
      await ref.read(ordersProvider.notifier).updateEntity(entity);
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
    final asyncItem = ref.watch(orderDetailProvider(widget.id));
    asyncItem.whenData((item) {
      if (!_prefilled) {
        _prefilled = true;
        _prefillControllers(item);
      }
    });
    final prefabTheme = PrefabTheme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order'),
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
                controller: _numberController,
                decoration: const InputDecoration(labelText: 'Number'),
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

List<RouteBase> get $entityScreensRoutes => [
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
                path: 'edit',
                builder: (context, state) => OrderEditScreen(
                    id: int.parse(state.pathParameters['orderId']!)),
              ),
              GoRoute(
                path: 'live',
                builder: (context, state) => OrderLiveScreen(
                    id: int.parse(state.pathParameters['orderId']!)),
              ),
              GoRoute(
                path: 'lines',
                builder: (context, state) => OrderLineListScreen(
                    orderId: int.parse(state.pathParameters['orderId']!)),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (context, state) => OrderLineDetailScreen(
                        id: int.parse(state.pathParameters['id']!),
                        orderId: int.parse(state.pathParameters['orderId']!)),
                    routes: [
                      GoRoute(
                        path: 'picking',
                        builder: (context, state) => OrderLinePickingScreen(
                            id: int.parse(state.pathParameters['id']!),
                            orderId:
                                int.parse(state.pathParameters['orderId']!)),
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

/// The breadcrumb bar for hand-written screens of Order: its
/// ancestors, the Order and [title]. Use it as `AppBar.bottom`.
PrefabBreadcrumbBar orderBreadcrumbs(BuildContext context, WidgetRef ref,
    {required String title, required int id}) {
  return PrefabBreadcrumbBar(
    items: [
      PrefabBreadcrumb(
        label: ref
                .watch(orderDetailProvider(id))
                .valueOrNull
                ?.number
                ?.toString() ??
            '…',
        onTap: () => context.go('/orders/$id'),
      ),
      PrefabBreadcrumb(label: title),
    ],
  );
}

/// The breadcrumb bar for hand-written screens of OrderLine: its
/// ancestors, the OrderLine and [title]. Use it as `AppBar.bottom`.
PrefabBreadcrumbBar orderLineBreadcrumbs(BuildContext context, WidgetRef ref,
    {required String title, required int id, required int orderId}) {
  return PrefabBreadcrumbBar(
    items: [
      PrefabBreadcrumb(
        label: ref
                .watch(orderDetailProvider(orderId))
                .valueOrNull
                ?.number
                ?.toString() ??
            '…',
        onTap: () => context.go('/orders/$orderId'),
      ),
      PrefabBreadcrumb(
        label: ref
                .watch(orderLineDetailProvider((id, orderId)))
                .valueOrNull
                ?.product
                .toString() ??
            '…',
        onTap: () => context.go('/orders/$orderId/lines/$id'),
      ),
      PrefabBreadcrumb(label: title),
    ],
  );
}
