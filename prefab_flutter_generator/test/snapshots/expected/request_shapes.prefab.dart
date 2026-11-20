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
import 'request_shapes.dart';

class TicketApiClient {
  final Dio _dio;
  final PrefabBackend _adapter;

  TicketApiClient(this._dio, [this._adapter = const PrefabBackend()]);

  Future<PrefabPage<Ticket>> list(
      {String? search,
      String? sort,
      bool descending = false,
      int page = 0,
      int? pageSize}) async {
    final response = await _dio.get(
      '/tickets',
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
      Ticket.fromJson,
      page: page,
      pageSize: pageSize,
    );
  }

  Future<Ticket> getById(int id) async {
    final response = await _dio.get('/tickets/${_adapter.encodeId(id)}');
    return Ticket.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Ticket> create(Ticket ticket) async {
    final response = await _dio.post('/tickets', data: _createBody(ticket));
    return Ticket.fromJson(response.data as Map<String, dynamic>);
  }

  /// Only the fields of the create form (and the parent id).
  Map<String, dynamic> _createBody(Ticket ticket) => {
        for (final e in ticket.toJson().entries)
          if (const <String>{'title', 'reporter'}.contains(e.key))
            e.key: e.value,
      };

  Future<Ticket> update(Ticket ticket) async {
    final response = await _dio.put('/tickets/${_adapter.encodeId(ticket.id)}',
        data: _updateBody(ticket));
    return Ticket.fromJson(response.data as Map<String, dynamic>);
  }

  /// Everything but the read-only and create-only fields.
  Map<String, dynamic> _updateBody(Ticket ticket) => {
        for (final e in ticket.toJson().entries)
          if (!const <String>{'reporter', 'created', 'state'}.contains(e.key))
            e.key: e.value,
      };

  Future<void> delete(Ticket ticket) async {
    await _dio.delete('/tickets/${_adapter.encodeId(ticket.id)}');
  }
}

final ticketDetailProvider = FutureProvider.autoDispose.family<Ticket, int>(
    (ref, id) => ref.watch(ticketApiClientProvider).getById(id));

final ticketsProvider =
    AsyncNotifierProvider.autoDispose<TicketsNotifier, PrefabPage<Ticket>>(
        TicketsNotifier.new);

class TicketsNotifier extends AutoDisposeAsyncNotifier<PrefabPage<Ticket>> {
  TicketApiClient get _client => ref.read(ticketApiClientProvider);

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
  Future<PrefabPage<Ticket>> build() {
    ref.onDispose(() => _searchDebounce?.cancel());
    return _client.list(
        search: _search,
        sort: _sort,
        descending: _descending,
        page: _page,
        pageSize: _pageSize);
  }

  Future<void> _load() async {
    state = const AsyncLoading<PrefabPage<Ticket>>().copyWithPrevious(state);
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

  Future<void> create(Ticket ticket) async {
    await _client.create(ticket);
    await _load();
  }

  Future<void> updateEntity(Ticket ticket) async {
    await _client.update(ticket);
    ref.invalidate(ticketDetailProvider(ticket.id!));
    await _load();
  }
}

final ticketApiClientProvider = Provider.autoDispose<TicketApiClient>((ref) =>
    TicketApiClient(
        ref.watch(prefabDioProvider), ref.watch(prefabBackendProvider)));

class TicketDetailScreen extends ConsumerWidget {
  final int id;

  const TicketDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ticketAsync = ref.watch(ticketDetailProvider(id));
    final prefabTheme = PrefabTheme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ticket'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit',
            onPressed: () => context.push('/tickets/$id/edit'),
          ),
        ],
      ),
      body: ticketAsync.when(
        data: (ticket) => ListView(
          padding: prefabTheme.detailPadding,
          children: [
            prefabTheme.detailFieldBuilder(
              context,
              'Title',
              Text(ticket.title.toString()),
            ),
            prefabTheme.detailFieldBuilder(
              context,
              'Reporter',
              Text(ticket.reporter.toString()),
            ),
            prefabTheme.detailFieldBuilder(
              context,
              'Resolution',
              Text(ticket.resolution?.toString() ?? '—'),
            ),
            prefabTheme.detailFieldBuilder(
              context,
              'Created',
              Text(ticket.created.toString()),
            ),
            prefabTheme.detailFieldBuilder(
              context,
              'State',
              Text(ticket.state.toString()),
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

class TicketListScreen extends ConsumerWidget {
  const TicketListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ticketsAsync = ref.watch(ticketsProvider);
    final notifier = ref.read(ticketsProvider.notifier);
    final prefabTheme = PrefabTheme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ticket'),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Create Ticket',
        onPressed: () async {
          await context.push('/tickets/create');
          ref.invalidate(ticketsProvider);
        },
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Expanded(
            child: ticketsAsync.when(
              skipLoadingOnReload: true,
              data: (page) => page.items.isEmpty
                  ? prefabTheme.emptyBuilder(context)
                  : ListView.builder(
                      padding: prefabTheme.listPadding,
                      itemCount: page.items.length,
                      itemBuilder: (context, index) {
                        final ticket = page.items[index];
                        return prefabTheme.listItemBuilder(
                          context,
                          title: Text(ticket.title.toString()),
                          subtitle: null,
                          trailing: null,
                          actions: const [],
                          onTap: () => context.push('/tickets/${ticket.id}'),
                        );
                      },
                    ),
              loading: () => prefabTheme.loadingBuilder(context),
              error: (error, stackTrace) =>
                  prefabTheme.errorBuilder(context, error, stackTrace),
            ),
          ),
          PrefabPaginationBar.controlled(
            page: ticketsAsync.valueOrNull?.page ?? 0,
            totalPages: ticketsAsync.valueOrNull?.totalPages ?? 0,
            onPageChanged: notifier.goToPage,
          ),
        ],
      ),
    );
  }
}

class TicketCreateScreen extends ConsumerStatefulWidget {
  const TicketCreateScreen({super.key});

  @override
  ConsumerState<TicketCreateScreen> createState() => _TicketCreateScreenState();
}

class _TicketCreateScreenState extends ConsumerState<TicketCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;
  final _titleController = TextEditingController();
  final _reporterController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _reporterController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    // Keep the (auto-dispose) provider alive while the request runs.
    final subscription = ref.listenManual(ticketsProvider, (_, __) {});
    try {
      final entity = Ticket(
        title: _titleController.text,
        reporter: _reporterController.text,
        created: DateTime.fromMillisecondsSinceEpoch(0),
        state: TicketState.values.first,
      );
      await ref.read(ticketsProvider.notifier).create(entity);
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
        title: const Text('Ticket'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: prefabTheme.formPadding,
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Required';
                return null;
              },
            ),
            TextFormField(
              controller: _reporterController,
              decoration: const InputDecoration(labelText: 'Reporter'),
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

class TicketEditScreen extends ConsumerStatefulWidget {
  final int id;

  const TicketEditScreen({super.key, required this.id});

  @override
  ConsumerState<TicketEditScreen> createState() => _TicketEditScreenState();
}

class _TicketEditScreenState extends ConsumerState<TicketEditScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;
  bool _prefilled = false;
  // ignore: unused_field
  Ticket? _item;
  final _titleController = TextEditingController();
  final _resolutionController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _resolutionController.dispose();
    super.dispose();
  }

  void _prefillControllers(Ticket item) {
    _item = item;
    _titleController.text = item.title;
    _resolutionController.text = item.resolution ?? '';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    // Keep the (auto-dispose) provider alive while the request runs.
    final subscription = ref.listenManual(ticketsProvider, (_, __) {});
    try {
      final entity = Ticket(
        id: widget.id,
        title: _titleController.text,
        reporter: _item!.reporter,
        resolution: _resolutionController.text.isEmpty
            ? null
            : _resolutionController.text,
        created: _item!.created,
        state: _item!.state,
      );
      await ref.read(ticketsProvider.notifier).updateEntity(entity);
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
    final asyncItem = ref.watch(ticketDetailProvider(widget.id));
    asyncItem.whenData((item) {
      if (!_prefilled) {
        _prefilled = true;
        _prefillControllers(item);
      }
    });
    final prefabTheme = PrefabTheme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ticket'),
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
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  return null;
                },
              ),
              TextFormField(
                controller: _resolutionController,
                decoration: const InputDecoration(labelText: 'Resolution'),
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

List<RouteBase> get $requestShapesRoutes => [
      GoRoute(
        path: '/tickets',
        builder: (context, state) => const TicketListScreen(),
        routes: [
          GoRoute(
            path: 'create',
            builder: (context, state) => const TicketCreateScreen(),
          ),
          GoRoute(
            path: ':id',
            builder: (context, state) =>
                TicketDetailScreen(id: int.parse(state.pathParameters['id']!)),
            routes: [
              GoRoute(
                path: 'edit',
                builder: (context, state) => TicketEditScreen(
                    id: int.parse(state.pathParameters['id']!)),
              ),
            ],
          ),
        ],
      ),
    ];
