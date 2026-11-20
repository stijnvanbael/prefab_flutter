import '../../core/artifact.dart';
import '../../core/code.dart';
import '../../core/entity_context.dart';
import '../../core/extension_point.dart';
import '../../core/feature.dart';
import '../../generators/api_client_generator.dart';
import '../../generators/list_screen_generator.dart';
import '../../generators/provider_generator.dart';
import '../../manifest/entity_manifest.dart';
import '../../manifest/field_manifest.dart';

/// Search, sort and pagination of the list (`@Field.searchable`,
/// `@Field.sortable`, `@View.paged`).
///
/// The list notifier keeps the query state and exposes the setters; the API
/// client sends it as query parameters; the list screen shows a search bar,
/// a sort menu and a pagination bar. Orders used on the shared extension
/// points: 10 search, 20 sort, 30 descending, 40 page, 50 page size.
class ListQueryFeature extends Feature {
  const ListQueryFeature();

  static const _name = 'list_query';

  @override
  String get name => _name;

  @override
  void contribute(EntityContext entity, ArtifactSet artifacts) {
    final id = entity.manifest.entityName;
    final manifest = entity.manifest;

    final client =
        artifacts.get<ApiClientArtifact>(ArtifactKind.apiClient, id);
    if (client != null) _apiClient(client.listQueryParameters, manifest);

    final provider =
        artifacts.get<ListProviderArtifact>(ArtifactKind.listProvider, id);
    if (provider != null) _notifier(provider, manifest);

    final screen = artifacts.get<ListScreenArtifact>(ArtifactKind.listScreen, id);
    if (screen != null) _screen(screen, manifest);
  }

  void _apiClient(ValuePoint<QueryParameter> point, EntityManifest m) {
    point.add(_name, const QueryParameter('search', 'String?'), order: 10);
    point.add(_name, const QueryParameter('sort', 'String?'), order: 20);
    point.add(
        _name, const QueryParameter('descending', 'bool', defaultValue: 'false'),
        order: 30);
    point.add(
        _name,
        QueryParameter('page', 'int',
            defaultValue: '0', query: m.paged, parse: m.paged),
        order: 40);
    point.add(
        _name, QueryParameter('pageSize', 'int?', query: m.paged, parse: m.paged),
        order: 50);
  }

  void _notifier(ListProviderArtifact provider, EntityManifest m) {
    provider.fetchArguments
      ..add(_name, const NamedArgument('search', '_search'), order: 10)
      ..add(_name, const NamedArgument('sort', '_sort'), order: 20)
      ..add(_name, const NamedArgument('descending', '_descending'), order: 30);
    if (m.paged) {
      provider.fetchArguments
        ..add(_name, const NamedArgument('page', '_page'), order: 40)
        ..add(_name, const NamedArgument('pageSize', '_pageSize'), order: 50);
    }
    provider.state.add(
      _name,
      Code(
        [
          "String _search = '';",
          'String? _sort;',
          'bool _descending = false;',
          'int _page = 0;',
          if (m.paged) 'int? _pageSize;',
          'Timer? _searchDebounce;',
          '',
          '/// The search text currently applied to the list.',
          'String get search => _search;',
          '',
          '/// The field the list is sorted by, or `null`.',
          'String? get sort => _sort;',
          '',
          '/// Whether the list is sorted descending.',
          'bool get descending => _descending;',
          '',
          '/// Zero-based index of the current page.',
          'int get page => _page;',
        ].join('\n'),
        imports: {Libs.dartAsync},
      ),
      order: 10,
    );
    provider.onBuild.add(
      _name,
      const Code('ref.onDispose(() => _searchDebounce?.cancel());'),
      order: 10,
    );
    provider.methods.add(
      _name,
      Code(
        [
          '/// Applies [query] after a short pause in typing and',
          '/// returns to the first page.',
          'void setSearch(String query) {',
          '  _searchDebounce?.cancel();',
          '  _searchDebounce = Timer(const Duration(milliseconds: 300), () {',
          '    if (query == _search) return;',
          '    _search = query;',
          '    _page = 0;',
          '    _load();',
          '  });',
          '}',
          '',
          '/// Sorts by [field] (`null` clears the sort) and reloads.',
          'Future<void> setSort(String? field, {bool descending = false}) {',
          '  _sort = field;',
          '  _descending = descending;',
          '  _page = 0;',
          '  return _load();',
          '}',
          if (m.paged) ...[
            '',
            '/// Loads the zero-based page [page].',
            'Future<void> goToPage(int page) {',
            '  _page = page;',
            '  return _load();',
            '}',
            '',
            '/// Changes the page size and returns to the first page.',
            'Future<void> setPageSize(int pageSize) {',
            '  _pageSize = pageSize;',
            '  _page = 0;',
            '  return _load();',
            '}',
          ],
        ].join('\n'),
        imports: {Libs.dartAsync},
      ),
      order: 10,
    );
  }

  void _screen(ListScreenArtifact screen, EntityManifest m) {
    if (m.hasSearch || m.hasSort || m.paged) {
      screen.buildStatements.add(
        _name,
        Code('final notifier = ref.read(${screen.providerRef}.notifier);'),
      );
    }
    if (m.hasSort) {
      screen.appBarActions.add(
        _name,
        Code(
          [
            'PrefabSortMenu<${m.entityName}>(',
            '  options: const [',
            for (final f in m.sortableFields) ...[
              "    PrefabSortOption(id: '${f.jsonName}', label: '${_escape(f.label)} ↑', icon: Icons.arrow_upward),",
              "    PrefabSortOption(id: '-${f.jsonName}', label: '${_escape(f.label)} ↓', icon: Icons.arrow_downward),",
            ],
            '  ],',
            "  selectedId: notifier.sort == null ? null : '\${notifier.descending ? '-' : ''}\${notifier.sort}',",
            '  onSortChanged: (option) => notifier.setSort(',
            "    option.id.replaceFirst('-', ''),",
            "    descending: option.id.startsWith('-'),",
            '  ),',
            '),',
          ].join('\n'),
          imports: {Libs.materialUi, Libs.widgets},
        ),
        order: 10,
      );
    }
    if (m.hasSearch) {
      screen.aboveList.add(
        _name,
        const Code(
          '''
Padding(
  padding: const EdgeInsets.all(8),
  child: PrefabSearchBar(
    initialValue: notifier.search,
    onChanged: notifier.setSearch,
  ),
),''',
          imports: {Libs.materialUi, Libs.widgets},
        ),
        order: 10,
      );
    }
    if (m.paged) {
      screen.belowList.add(
        _name,
        Code(
          '''
PrefabPaginationBar.controlled(
  page: ${screen.asyncName}.valueOrNull?.page ?? 0,
  totalPages: ${screen.asyncName}.valueOrNull?.totalPages ?? 0,
  onPageChanged: notifier.goToPage,
),''',
          imports: {Libs.widgets},
        ),
        order: 10,
      );
    }
  }

  static String _escape(String value) => value
      .replaceAll(r'\', r'\\')
      .replaceAll("'", r"\'")
      .replaceAll(r'$', r'\$');
}

/// What only the list query feature needs to know about an entity.
extension ListQueryManifest on EntityManifest {
  /// Visible fields that take part in the list search.
  List<FieldManifest> get searchableFields =>
      visibleFields.where((f) => f.searchable).toList();

  /// Visible fields offered in the list sort menu.
  List<FieldManifest> get sortableFields =>
      visibleFields.where((f) => f.sortable).toList();

  /// Whether the list screen shows a search bar.
  bool get hasSearch => searchableFields.isNotEmpty;

  /// Whether the list screen shows a sort menu.
  bool get hasSort => sortableFields.isNotEmpty;
}
