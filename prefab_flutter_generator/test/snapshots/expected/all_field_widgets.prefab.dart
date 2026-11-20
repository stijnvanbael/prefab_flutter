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

import 'all_field_widgets.dart';
import 'dart:async';

class WidgetDemoApiClient {
  final Dio _dio;
  final PrefabListAdapter _adapter;

  WidgetDemoApiClient(this._dio, [this._adapter = const PrefabListAdapter()]);

  Future<PrefabPage<WidgetDemo>> list(
      {String? search,
      String? sort,
      bool descending = false,
      int page = 0,
      int? pageSize}) async {
    final response = await _dio.get(
      '/widget-demos',
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
      WidgetDemo.fromJson,
      page: page,
      pageSize: pageSize,
    );
  }

  Future<WidgetDemo> getById(int id) async {
    final response = await _dio.get('/widget-demos/$id');
    return WidgetDemo.fromJson(response.data as Map<String, dynamic>);
  }

  Future<WidgetDemo> create(WidgetDemo widgetDemo) async {
    final response =
        await _dio.post('/widget-demos', data: widgetDemo.toJson());
    return WidgetDemo.fromJson(response.data as Map<String, dynamic>);
  }

  Future<WidgetDemo> update(WidgetDemo widgetDemo) async {
    final response = await _dio.put('/widget-demos/${widgetDemo.id}',
        data: widgetDemo.toJson());
    return WidgetDemo.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> delete(WidgetDemo widgetDemo) async {
    await _dio.delete('/widget-demos/${widgetDemo.id}');
  }
}

final widgetDemoDetailProvider = FutureProvider.autoDispose
    .family<WidgetDemo, int>(
        (ref, id) => ref.watch(widgetDemoApiClientProvider).getById(id));

final widgetDemosProvider = AsyncNotifierProvider.autoDispose<
    WidgetDemosNotifier, PrefabPage<WidgetDemo>>(WidgetDemosNotifier.new);

class WidgetDemosNotifier
    extends AutoDisposeAsyncNotifier<PrefabPage<WidgetDemo>> {
  WidgetDemoApiClient get _client => ref.read(widgetDemoApiClientProvider);

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
  Future<PrefabPage<WidgetDemo>> build() {
    ref.onDispose(() => _searchDebounce?.cancel());
    return _client.list(
        search: _search,
        sort: _sort,
        descending: _descending,
        page: _page,
        pageSize: _pageSize);
  }

  Future<void> _load() async {
    state =
        const AsyncLoading<PrefabPage<WidgetDemo>>().copyWithPrevious(state);
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

  Future<void> create(WidgetDemo widgetDemo) async {
    await _client.create(widgetDemo);
    await _load();
  }

  Future<void> updateEntity(WidgetDemo widgetDemo) async {
    await _client.update(widgetDemo);
    ref.invalidate(widgetDemoDetailProvider(widgetDemo.id!));
    await _load();
  }
}

final widgetDemoApiClientProvider = Provider.autoDispose<WidgetDemoApiClient>(
    (ref) => WidgetDemoApiClient(
        ref.watch(prefabDioProvider), ref.watch(prefabListAdapterProvider)));

class WidgetDemoDetailScreen extends ConsumerWidget {
  final int id;

  const WidgetDemoDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final widgetDemoAsync = ref.watch(widgetDemoDetailProvider(id));
    final prefabTheme = PrefabTheme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Widget Demo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit',
            onPressed: () => context.push('/widget-demos/$id/edit'),
          ),
        ],
      ),
      body: widgetDemoAsync.when(
        data: (widgetDemo) => ListView(
          padding: prefabTheme.detailPadding,
          children: [
            prefabTheme.detailFieldBuilder(
              context,
              'Auto',
              Text(widgetDemo.auto.toString()),
            ),
            prefabTheme.detailFieldBuilder(
              context,
              'Notes',
              Text(widgetDemo.notes.toString()),
            ),
            prefabTheme.detailFieldBuilder(
              context,
              'Secret',
              Text(widgetDemo.secret.toString()),
            ),
            prefabTheme.detailFieldBuilder(
              context,
              'Quantity',
              Text(widgetDemo.quantity.toString()),
            ),
            prefabTheme.detailFieldBuilder(
              context,
              'Day',
              Text(widgetDemo.day.toString()),
            ),
            prefabTheme.detailFieldBuilder(
              context,
              'At',
              Text(widgetDemo.at.toString()),
            ),
            prefabTheme.detailFieldBuilder(
              context,
              'Moment',
              Text(widgetDemo.moment.toString()),
            ),
            prefabTheme.detailFieldBuilder(
              context,
              'Status',
              Text(widgetDemo.status.toString()),
            ),
            prefabTheme.detailFieldBuilder(
              context,
              'Active',
              Text(widgetDemo.active.toString()),
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

class WidgetDemoListScreen extends ConsumerWidget {
  const WidgetDemoListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final widgetDemosAsync = ref.watch(widgetDemosProvider);
    final notifier = ref.read(widgetDemosProvider.notifier);
    final prefabTheme = PrefabTheme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Widget Demo'),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Create Widget Demo',
        onPressed: () async {
          await context.push('/widget-demos/create');
          ref.invalidate(widgetDemosProvider);
        },
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Expanded(
            child: widgetDemosAsync.when(
              skipLoadingOnReload: true,
              data: (page) => page.items.isEmpty
                  ? prefabTheme.emptyBuilder(context)
                  : ListView.builder(
                      padding: prefabTheme.listPadding,
                      itemCount: page.items.length,
                      itemBuilder: (context, index) {
                        final widgetDemo = page.items[index];
                        return prefabTheme.listItemBuilder(
                          context,
                          title: Text(widgetDemo.auto.toString()),
                          subtitle: null,
                          trailing: null,
                          actions: const [],
                          onTap: () =>
                              context.push('/widget-demos/${widgetDemo.id}'),
                        );
                      },
                    ),
              loading: () => prefabTheme.loadingBuilder(context),
              error: (error, stackTrace) =>
                  prefabTheme.errorBuilder(context, error, stackTrace),
            ),
          ),
          PrefabPaginationBar.controlled(
            page: widgetDemosAsync.valueOrNull?.page ?? 0,
            totalPages: widgetDemosAsync.valueOrNull?.totalPages ?? 0,
            onPageChanged: notifier.goToPage,
          ),
        ],
      ),
    );
  }
}

class WidgetDemoCreateScreen extends ConsumerStatefulWidget {
  const WidgetDemoCreateScreen({super.key});

  @override
  ConsumerState<WidgetDemoCreateScreen> createState() =>
      _WidgetDemoCreateScreenState();
}

class _WidgetDemoCreateScreenState
    extends ConsumerState<WidgetDemoCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;
  final _autoController = TextEditingController();
  final _notesController = TextEditingController();
  final _secretController = TextEditingController();
  final _quantityController = TextEditingController();
  final _dayController = TextEditingController();
  DateTime? _dayValue;
  final _atController = TextEditingController();
  String? _atValue;
  final _momentController = TextEditingController();
  DateTime? _momentValue;
  Status? _statusValue;
  bool _activeValue = false;

  @override
  void dispose() {
    _autoController.dispose();
    _notesController.dispose();
    _secretController.dispose();
    _quantityController.dispose();
    _dayController.dispose();
    _atController.dispose();
    _momentController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    // Keep the (auto-dispose) provider alive while the request runs.
    final subscription = ref.listenManual(widgetDemosProvider, (_, __) {});
    try {
      final entity = WidgetDemo(
        auto: _autoController.text,
        notes: _notesController.text,
        secret: _secretController.text,
        quantity: int.parse(_quantityController.text),
        day: _dayValue!,
        at: _atValue!,
        moment: _momentValue!,
        status: _statusValue!,
        active: _activeValue,
      );
      await ref.read(widgetDemosProvider.notifier).create(entity);
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
        title: const Text('Widget Demo'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: prefabTheme.formPadding,
          children: [
            TextFormField(
              controller: _autoController,
              decoration: const InputDecoration(labelText: 'Auto'),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Required';
                return null;
              },
            ),
            TextFormField(
              controller: _notesController,
              maxLines: null,
              keyboardType: TextInputType.multiline,
              decoration: const InputDecoration(labelText: 'Notes'),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Required';
                return null;
              },
            ),
            TextFormField(
              controller: _secretController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Secret'),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Required';
                return null;
              },
            ),
            TextFormField(
              controller: _quantityController,
              keyboardType: const TextInputType.numberWithOptions(signed: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^-?\d*$')),
              ],
              decoration: const InputDecoration(labelText: 'Quantity'),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Required';
                if (int.tryParse(value) == null)
                  return 'Must be a whole number';
                return null;
              },
            ),
            TextFormField(
              controller: _dayController,
              readOnly: true,
              decoration: const InputDecoration(labelText: 'Day'),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _dayValue ?? DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (picked != null && context.mounted) {
                  setState(() {
                    _dayValue = picked;
                    _dayController.text = MaterialLocalizations.of(context)
                        .formatCompactDate(picked);
                  });
                }
              },
              validator: (value) {
                if (value == null || value.isEmpty) return 'Required';
                return null;
              },
            ),
            TextFormField(
              controller: _atController,
              readOnly: true,
              decoration: const InputDecoration(labelText: 'At'),
              onTap: () async {
                final current = _atValue;
                final picked = await showTimePicker(
                  context: context,
                  initialTime: current == null
                      ? TimeOfDay.now()
                      : TimeOfDay(
                          hour: int.parse(current.split(':')[0]),
                          minute: int.parse(current.split(':')[1])),
                );
                if (picked != null && context.mounted) {
                  setState(() {
                    _atValue =
                        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                    _atController.text = MaterialLocalizations.of(context)
                        .formatTimeOfDay(TimeOfDay(
                            hour: int.parse(_atValue!.split(':')[0]),
                            minute: int.parse(_atValue!.split(':')[1])));
                  });
                }
              },
              validator: (value) {
                if (value == null || value.isEmpty) return 'Required';
                return null;
              },
            ),
            TextFormField(
              controller: _momentController,
              readOnly: true,
              decoration: const InputDecoration(labelText: 'Moment'),
              onTap: () async {
                final initial = _momentValue ?? DateTime.now();
                final date = await showDatePicker(
                  context: context,
                  initialDate: initial,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (date == null || !context.mounted) return;
                final time = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.fromDateTime(initial),
                );
                if (time == null || !context.mounted) return;
                final picked = DateTime(
                  date.year,
                  date.month,
                  date.day,
                  time.hour,
                  time.minute,
                );
                setState(() {
                  _momentValue = picked;
                  _momentController.text =
                      '${MaterialLocalizations.of(context).formatCompactDate(picked)} ${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(picked))}';
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) return 'Required';
                return null;
              },
            ),
            DropdownButtonFormField<Status>(
              value: _statusValue,
              decoration: const InputDecoration(labelText: 'Status'),
              items: [
                ...Status.values.map((v) => DropdownMenuItem<Status>(
                      value: v,
                      child: Text(v.name),
                    )),
              ],
              onChanged: (v) => setState(() => _statusValue = v),
              validator: (value) => value == null ? 'Required' : null,
            ),
            SwitchListTile(
              title: const Text('Active'),
              value: _activeValue,
              onChanged: (v) => setState(() => _activeValue = v),
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

class WidgetDemoEditScreen extends ConsumerStatefulWidget {
  final int id;

  const WidgetDemoEditScreen({super.key, required this.id});

  @override
  ConsumerState<WidgetDemoEditScreen> createState() =>
      _WidgetDemoEditScreenState();
}

class _WidgetDemoEditScreenState extends ConsumerState<WidgetDemoEditScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;
  bool _prefilled = false;
  // ignore: unused_field
  WidgetDemo? _item;
  final _autoController = TextEditingController();
  final _notesController = TextEditingController();
  final _secretController = TextEditingController();
  final _quantityController = TextEditingController();
  final _dayController = TextEditingController();
  DateTime? _dayValue;
  final _atController = TextEditingController();
  String? _atValue;
  final _momentController = TextEditingController();
  DateTime? _momentValue;
  Status? _statusValue;
  bool _activeValue = false;

  @override
  void dispose() {
    _autoController.dispose();
    _notesController.dispose();
    _secretController.dispose();
    _quantityController.dispose();
    _dayController.dispose();
    _atController.dispose();
    _momentController.dispose();
    super.dispose();
  }

  void _prefillControllers(WidgetDemo item) {
    _item = item;
    _autoController.text = item.auto;
    _notesController.text = item.notes;
    _secretController.text = item.secret;
    _quantityController.text = item.quantity.toString();
    _dayValue = item.day;
    _dayController.text =
        MaterialLocalizations.of(context).formatCompactDate(_dayValue!);
    _atValue = item.at;
    _atController.text = MaterialLocalizations.of(context).formatTimeOfDay(
        TimeOfDay(
            hour: int.parse(_atValue!.split(':')[0]),
            minute: int.parse(_atValue!.split(':')[1])));
    _momentValue = item.moment;
    _momentController.text =
        '${MaterialLocalizations.of(context).formatCompactDate(_momentValue!)} ${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(_momentValue!))}';
    _statusValue = item.status;
    _activeValue = item.active;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    // Keep the (auto-dispose) provider alive while the request runs.
    final subscription = ref.listenManual(widgetDemosProvider, (_, __) {});
    try {
      final entity = WidgetDemo(
        id: widget.id,
        auto: _autoController.text,
        notes: _notesController.text,
        secret: _secretController.text,
        quantity: int.parse(_quantityController.text),
        day: _dayValue!,
        at: _atValue!,
        moment: _momentValue!,
        status: _statusValue!,
        active: _activeValue,
      );
      await ref.read(widgetDemosProvider.notifier).updateEntity(entity);
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
    final asyncItem = ref.watch(widgetDemoDetailProvider(widget.id));
    asyncItem.whenData((item) {
      if (!_prefilled) {
        _prefilled = true;
        _prefillControllers(item);
      }
    });
    final prefabTheme = PrefabTheme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Widget Demo'),
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
                controller: _autoController,
                decoration: const InputDecoration(labelText: 'Auto'),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  return null;
                },
              ),
              TextFormField(
                controller: _notesController,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                decoration: const InputDecoration(labelText: 'Notes'),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  return null;
                },
              ),
              TextFormField(
                controller: _secretController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Secret'),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  return null;
                },
              ),
              TextFormField(
                controller: _quantityController,
                keyboardType:
                    const TextInputType.numberWithOptions(signed: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^-?\d*$')),
                ],
                decoration: const InputDecoration(labelText: 'Quantity'),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  if (int.tryParse(value) == null)
                    return 'Must be a whole number';
                  return null;
                },
              ),
              TextFormField(
                controller: _dayController,
                readOnly: true,
                decoration: const InputDecoration(labelText: 'Day'),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _dayValue ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null && context.mounted) {
                    setState(() {
                      _dayValue = picked;
                      _dayController.text = MaterialLocalizations.of(context)
                          .formatCompactDate(picked);
                    });
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  return null;
                },
              ),
              TextFormField(
                controller: _atController,
                readOnly: true,
                decoration: const InputDecoration(labelText: 'At'),
                onTap: () async {
                  final current = _atValue;
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: current == null
                        ? TimeOfDay.now()
                        : TimeOfDay(
                            hour: int.parse(current.split(':')[0]),
                            minute: int.parse(current.split(':')[1])),
                  );
                  if (picked != null && context.mounted) {
                    setState(() {
                      _atValue =
                          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                      _atController.text = MaterialLocalizations.of(context)
                          .formatTimeOfDay(TimeOfDay(
                              hour: int.parse(_atValue!.split(':')[0]),
                              minute: int.parse(_atValue!.split(':')[1])));
                    });
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  return null;
                },
              ),
              TextFormField(
                controller: _momentController,
                readOnly: true,
                decoration: const InputDecoration(labelText: 'Moment'),
                onTap: () async {
                  final initial = _momentValue ?? DateTime.now();
                  final date = await showDatePicker(
                    context: context,
                    initialDate: initial,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (date == null || !context.mounted) return;
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.fromDateTime(initial),
                  );
                  if (time == null || !context.mounted) return;
                  final picked = DateTime(
                    date.year,
                    date.month,
                    date.day,
                    time.hour,
                    time.minute,
                  );
                  setState(() {
                    _momentValue = picked;
                    _momentController.text =
                        '${MaterialLocalizations.of(context).formatCompactDate(picked)} ${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(picked))}';
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  return null;
                },
              ),
              DropdownButtonFormField<Status>(
                value: _statusValue,
                decoration: const InputDecoration(labelText: 'Status'),
                items: [
                  ...Status.values.map((v) => DropdownMenuItem<Status>(
                        value: v,
                        child: Text(v.name),
                      )),
                ],
                onChanged: (v) => setState(() => _statusValue = v),
                validator: (value) => value == null ? 'Required' : null,
              ),
              SwitchListTile(
                title: const Text('Active'),
                value: _activeValue,
                onChanged: (v) => setState(() => _activeValue = v),
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

List<RouteBase> get $allFieldWidgetsRoutes => [
      GoRoute(
        path: '/widget-demos',
        builder: (context, state) => const WidgetDemoListScreen(),
        routes: [
          GoRoute(
            path: 'create',
            builder: (context, state) => const WidgetDemoCreateScreen(),
          ),
          GoRoute(
            path: ':id',
            builder: (context, state) => WidgetDemoDetailScreen(
                id: int.parse(state.pathParameters['id']!)),
            routes: [
              GoRoute(
                path: 'edit',
                builder: (context, state) => WidgetDemoEditScreen(
                    id: int.parse(state.pathParameters['id']!)),
              ),
            ],
          ),
        ],
      ),
    ];
