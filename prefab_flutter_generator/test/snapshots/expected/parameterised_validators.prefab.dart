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
import 'parameterised_validators.dart';

class AccountApiClient {
  final Dio _dio;
  final PrefabListAdapter _adapter;

  AccountApiClient(this._dio, [this._adapter = const PrefabListAdapter()]);

  Future<PrefabPage<Account>> list(
      {String? search,
      String? sort,
      bool descending = false,
      int page = 0,
      int? pageSize}) async {
    final response = await _dio.get(
      '/accounts',
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
      Account.fromJson,
      page: page,
      pageSize: pageSize,
    );
  }

  Future<Account> getById(int id) async {
    final response = await _dio.get('/accounts/$id');
    return Account.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Account> create(Account account) async {
    final response = await _dio.post('/accounts', data: account.toJson());
    return Account.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Account> update(Account account) async {
    final response =
        await _dio.put('/accounts/${account.id}', data: account.toJson());
    return Account.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> delete(Account account) async {
    await _dio.delete('/accounts/${account.id}');
  }
}

final accountDetailProvider = FutureProvider.autoDispose.family<Account, int>(
    (ref, id) => ref.watch(accountApiClientProvider).getById(id));

final accountsProvider =
    AsyncNotifierProvider.autoDispose<AccountsNotifier, PrefabPage<Account>>(
        AccountsNotifier.new);

class AccountsNotifier extends AutoDisposeAsyncNotifier<PrefabPage<Account>> {
  AccountApiClient get _client => ref.read(accountApiClientProvider);

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
  Future<PrefabPage<Account>> build() {
    ref.onDispose(() => _searchDebounce?.cancel());
    return _client.list(
        search: _search,
        sort: _sort,
        descending: _descending,
        page: _page,
        pageSize: _pageSize);
  }

  Future<void> _load() async {
    state = const AsyncLoading<PrefabPage<Account>>().copyWithPrevious(state);
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

  Future<void> create(Account account) async {
    await _client.create(account);
    await _load();
  }

  Future<void> updateEntity(Account account) async {
    await _client.update(account);
    ref.invalidate(accountDetailProvider(account.id!));
    await _load();
  }
}

final accountApiClientProvider = Provider.autoDispose<AccountApiClient>((ref) =>
    AccountApiClient(
        ref.watch(prefabDioProvider), ref.watch(prefabListAdapterProvider)));

class AccountDetailScreen extends ConsumerWidget {
  final int id;

  const AccountDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountAsync = ref.watch(accountDetailProvider(id));
    final prefabTheme = PrefabTheme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit',
            onPressed: () => context.push('/accounts/$id/edit'),
          ),
        ],
      ),
      body: accountAsync.when(
        data: (account) => ListView(
          padding: prefabTheme.detailPadding,
          children: [
            prefabTheme.detailFieldBuilder(
              context,
              'Email',
              account.email.toString(),
            ),
            prefabTheme.detailFieldBuilder(
              context,
              'Username',
              account.username.toString(),
            ),
            prefabTheme.detailFieldBuilder(
              context,
              'Code',
              account.code.toString(),
            ),
            prefabTheme.detailFieldBuilder(
              context,
              'Age',
              account.age.toString(),
            ),
            prefabTheme.detailFieldBuilder(
              context,
              'Website',
              account.website?.toString() ?? '—',
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

class AccountListScreen extends ConsumerWidget {
  const AccountListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(accountsProvider);
    final notifier = ref.read(accountsProvider.notifier);
    final prefabTheme = PrefabTheme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account'),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Create Account',
        onPressed: () async {
          await context.push('/accounts/create');
          ref.invalidate(accountsProvider);
        },
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Expanded(
            child: accountsAsync.when(
              skipLoadingOnReload: true,
              data: (page) => page.items.isEmpty
                  ? prefabTheme.emptyBuilder(context)
                  : ListView.builder(
                      padding: prefabTheme.listPadding,
                      itemCount: page.items.length,
                      itemBuilder: (context, index) {
                        final account = page.items[index];
                        return ListTile(
                          title: Text(account.email.toString()),
                          onTap: () => context.push('/accounts/${account.id}'),
                        );
                      },
                    ),
              loading: () => prefabTheme.loadingBuilder(context),
              error: (error, stackTrace) =>
                  prefabTheme.errorBuilder(context, error, stackTrace),
            ),
          ),
          PrefabPaginationBar.controlled(
            page: accountsAsync.valueOrNull?.page ?? 0,
            totalPages: accountsAsync.valueOrNull?.totalPages ?? 0,
            onPageChanged: notifier.goToPage,
          ),
        ],
      ),
    );
  }
}

class AccountCreateScreen extends ConsumerStatefulWidget {
  const AccountCreateScreen({super.key});

  @override
  ConsumerState<AccountCreateScreen> createState() =>
      _AccountCreateScreenState();
}

class _AccountCreateScreenState extends ConsumerState<AccountCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _codeController = TextEditingController();
  final _ageController = TextEditingController();
  final _websiteController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _codeController.dispose();
    _ageController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    // Keep the (auto-dispose) provider alive while the request runs.
    final subscription = ref.listenManual(accountsProvider, (_, __) {});
    try {
      final entity = Account(
        email: _emailController.text,
        username: _usernameController.text,
        code: _codeController.text,
        age: int.parse(_ageController.text),
        website:
            _websiteController.text.isEmpty ? null : _websiteController.text,
      );
      await ref.read(accountsProvider.notifier).create(entity);
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
        title: const Text('Account'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: prefabTheme.formPadding,
          children: [
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Required';
                if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value))
                  return 'Invalid email address';
                return null;
              },
            ),
            TextFormField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: 'Username'),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Required';
                if (value.length < 3) return 'Must be at least 3 characters';
                if (value.length > 20) return 'Too long';
                return null;
              },
            ),
            TextFormField(
              controller: _codeController,
              decoration: const InputDecoration(labelText: 'Code'),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Required';
                if (!RegExp('^[A-Z]+\$').hasMatch(value))
                  return 'Invalid format';
                return null;
              },
            ),
            TextFormField(
              controller: _ageController,
              keyboardType: const TextInputType.numberWithOptions(signed: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^-?\d*$')),
              ],
              decoration: const InputDecoration(labelText: 'Age'),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Required';
                if (int.tryParse(value) == null)
                  return 'Must be a whole number';
                {
                  final n = double.tryParse(value);
                  if (n == null || n < 1) return 'Can\'t be < 1';
                }
                {
                  final n = double.tryParse(value);
                  if (n == null || n > 99) return 'Must be at most 99';
                }
                return null;
              },
            ),
            TextFormField(
              controller: _websiteController,
              decoration: const InputDecoration(labelText: 'Website'),
              validator: (value) {
                if (value == null || value.isEmpty) return null;
                {
                  final uri = Uri.tryParse(value);
                  if (uri == null || !uri.isAbsolute) return 'Invalid URL';
                }
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

class AccountEditScreen extends ConsumerStatefulWidget {
  final int id;

  const AccountEditScreen({super.key, required this.id});

  @override
  ConsumerState<AccountEditScreen> createState() => _AccountEditScreenState();
}

class _AccountEditScreenState extends ConsumerState<AccountEditScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;
  bool _prefilled = false;
  // ignore: unused_field
  Account? _item;
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _codeController = TextEditingController();
  final _ageController = TextEditingController();
  final _websiteController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _codeController.dispose();
    _ageController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  void _prefillControllers(Account item) {
    _item = item;
    _emailController.text = item.email;
    _usernameController.text = item.username;
    _codeController.text = item.code;
    _ageController.text = item.age.toString();
    _websiteController.text = item.website ?? '';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    // Keep the (auto-dispose) provider alive while the request runs.
    final subscription = ref.listenManual(accountsProvider, (_, __) {});
    try {
      final entity = Account(
        id: widget.id,
        email: _emailController.text,
        username: _usernameController.text,
        code: _codeController.text,
        age: int.parse(_ageController.text),
        website:
            _websiteController.text.isEmpty ? null : _websiteController.text,
      );
      await ref.read(accountsProvider.notifier).updateEntity(entity);
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
    final asyncItem = ref.watch(accountDetailProvider(widget.id));
    asyncItem.whenData((item) {
      if (!_prefilled) {
        _prefilled = true;
        _prefillControllers(item);
      }
    });
    final prefabTheme = PrefabTheme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account'),
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
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value))
                    return 'Invalid email address';
                  return null;
                },
              ),
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'Username'),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  if (value.length < 3) return 'Must be at least 3 characters';
                  if (value.length > 20) return 'Too long';
                  return null;
                },
              ),
              TextFormField(
                controller: _codeController,
                decoration: const InputDecoration(labelText: 'Code'),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  if (!RegExp('^[A-Z]+\$').hasMatch(value))
                    return 'Invalid format';
                  return null;
                },
              ),
              TextFormField(
                controller: _ageController,
                keyboardType:
                    const TextInputType.numberWithOptions(signed: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^-?\d*$')),
                ],
                decoration: const InputDecoration(labelText: 'Age'),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  if (int.tryParse(value) == null)
                    return 'Must be a whole number';
                  {
                    final n = double.tryParse(value);
                    if (n == null || n < 1) return 'Can\'t be < 1';
                  }
                  {
                    final n = double.tryParse(value);
                    if (n == null || n > 99) return 'Must be at most 99';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _websiteController,
                decoration: const InputDecoration(labelText: 'Website'),
                validator: (value) {
                  if (value == null || value.isEmpty) return null;
                  {
                    final uri = Uri.tryParse(value);
                    if (uri == null || !uri.isAbsolute) return 'Invalid URL';
                  }
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

List<RouteBase> get $parameterisedValidatorsRoutes => [
      GoRoute(
        path: '/accounts',
        builder: (context, state) => const AccountListScreen(),
        routes: [
          GoRoute(
            path: 'create',
            builder: (context, state) => const AccountCreateScreen(),
          ),
          GoRoute(
            path: ':id',
            builder: (context, state) =>
                AccountDetailScreen(id: int.parse(state.pathParameters['id']!)),
            routes: [
              GoRoute(
                path: 'edit',
                builder: (context, state) => AccountEditScreen(
                    id: int.parse(state.pathParameters['id']!)),
              ),
            ],
          ),
        ],
      ),
    ];
