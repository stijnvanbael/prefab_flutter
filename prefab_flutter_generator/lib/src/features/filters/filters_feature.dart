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

/// Filters of the list (`@Field.filterable`).
///
/// The list notifier keeps the filter values next to search and sort, the API
/// client sends them through `PrefabBackend.queryParameters` and the list
/// screen shows one control per filterable field, chosen from its type. Text
/// filters get suggestions from the backend's autocomplete endpoint
/// (`PrefabBackend.autocompletePath`). Orders used on the shared extension
/// points: 25 (between sort and descending), 10 / 20 for the screen.
class FiltersFeature extends Feature {
  const FiltersFeature();

  static const _name = 'filters';

  @override
  String get name => _name;

  @override
  void contribute(EntityContext entity, ArtifactSet artifacts) {
    final manifest = entity.manifest;
    if (!manifest.hasFilters) return;
    final id = manifest.entityName;

    final client =
        artifacts.get<ApiClientArtifact>(ArtifactKind.apiClient, id);
    if (client != null) _apiClient(client, manifest);

    final provider =
        artifacts.get<ListProviderArtifact>(ArtifactKind.listProvider, id);
    if (provider != null) _notifier(provider, manifest);

    final screen =
        artifacts.get<ListScreenArtifact>(ArtifactKind.listScreen, id);
    if (screen != null) _screen(screen, manifest);
  }

  void _apiClient(ApiClientArtifact client, EntityManifest m) {
    client.listQueryParameters.add(
      _name,
      const QueryParameter('filters', 'Map<String, Object?>',
          defaultValue: 'const {}'),
      order: 25,
    );
    if (!m.hasTextFilters) return;
    client.methods.addLazy(
      _name,
      () => Code(
        [
          '/// Suggestions for the text filter on [field]; empty when the',
          '/// backend adapter has no autocomplete endpoint.',
          'Future<List<String>> autocomplete(String field, String text${client.parentParamTrailing}) async {',
          "  final path = _adapter.autocompleteUrl('${client.urlBase}');",
          '  if (path == null) return const [];',
          '  final response = await _dio.get(',
          '    path,',
          '    queryParameters: _adapter.autocompleteQueryParameters(field, text),',
          '  );',
          '  return _adapter.parseSuggestions(response.data);',
          '}',
        ].join('\n'),
      ),
      order: 40,
    );
  }

  void _notifier(ListProviderArtifact provider, EntityManifest m) {
    provider.fetchArguments
        .add(_name, const NamedArgument('filters', '_filters'), order: 25);
    provider.state.add(
      _name,
      const Code(
        '''
final Map<String, Object?> _filters = {};

/// The filter values currently applied, by JSON field name.
Map<String, Object?> get filters => Map.unmodifiable(_filters);''',
      ),
      order: 20,
    );
    provider.methods.add(
      _name,
      const Code(
        '''
/// Sets the filter on [field] (a JSON field name; `null` or an empty text
/// clears it), returns to the first page and reloads.
Future<void> setFilter(String field, Object? value) {
  if (value == null || value == '') {
    _filters.remove(field);
  } else {
    _filters[field] = value;
  }
  _page = 0;
  return _load();
}

/// Clears every filter and reloads.
Future<void> clearFilters() {
  _filters.clear();
  _page = 0;
  return _load();
}''',
      ),
      order: 15,
    );
    if (m.hasTextFilters) {
      provider.methods.addLazy(
        _name,
        () => Code(
          [
            '/// Suggestions for the text filter on [field] from the backend.',
            'Future<List<String>> suggest(String field, String text) =>',
            '    _client.autocomplete(field, text${provider.clientTrailing});',
          ].join('\n'),
        ),
        order: 16,
      );
    }
  }

  void _screen(ListScreenArtifact screen, EntityManifest m) {
    screen.buildStatements.add(
      _name,
      Code(
          'final filterNotifier = ref.read(${ListScreenArtifact.providerRef}.notifier);'),
      order: 20,
    );
    final controls = [for (final f in m.filterableFields) ..._control(f, m)];
    screen.aboveList.add(
      _name,
      Code(
        [
          'Padding(',
          '  padding: const EdgeInsets.symmetric(horizontal: 8),',
          '  child: Wrap(',
          '    spacing: 16,',
          '    runSpacing: 8,',
          '    crossAxisAlignment: WrapCrossAlignment.center,',
          '    children: [',
          for (final line in controls) '      $line',
          '    ],',
          '  ),',
          '),',
        ].join('\n'),
        imports: {Libs.materialUi, Libs.widgets},
      ),
      order: 20,
    );
  }

  List<String> _control(FieldManifest f, EntityManifest m) {
    final key = "'${_escape(f.jsonName)}'";
    final label = "'${_escape(f.label)}'";
    final current = 'filterNotifier.filters[$key]';
    if (f.isEnum) {
      final type = f.dartType.replaceAll('?', '');
      return [
        'PrefabEnumFilter(',
        '  label: $label,',
        '  options: [',
        '    for (final v in $type.values)',
        '      PrefabFilterOption(value: v.name, label: v.name),',
        '  ],',
        '  selected: $current as String?,',
        '  onChanged: (value) => filterNotifier.setFilter($key, value),',
        '),',
      ];
    }
    switch (f.dartType.replaceAll('?', '')) {
      case 'bool':
        return [
          'PrefabBoolFilter(',
          '  label: $label,',
          '  value: $current as bool?,',
          '  onChanged: (value) => filterNotifier.setFilter($key, value),',
          '),',
        ];
      case 'DateTime':
        return [
          'PrefabDateRangeFilter(',
          '  label: $label,',
          '  value: $current as PrefabDateRange?,',
          '  onChanged: (value) => filterNotifier.setFilter($key, value),',
          '),',
        ];
      default:
        return [
          'PrefabTextFilter(',
          '  label: $label,',
          "  initialValue: ($current as String?) ?? '',",
          '  onChanged: (value) => filterNotifier.setFilter($key, value),',
          if (f.dartType.replaceAll('?', '') == 'String')
            '  suggest: (text) => filterNotifier.suggest($key, text),',
          '),',
        ];
    }
  }

  static String _escape(String value) => value
      .replaceAll(r'\', r'\\')
      .replaceAll("'", r"\'")
      .replaceAll(r'$', r'\$');
}

/// What only the filters feature needs to know about an entity.
extension FiltersManifest on EntityManifest {
  /// Visible fields that get a filter control.
  List<FieldManifest> get filterableFields =>
      visibleFields.where((f) => f.filterable).toList();

  /// Whether the list screen shows filters.
  bool get hasFilters => filterableFields.isNotEmpty;

  /// Whether a filter is a text field with suggestions (`String` fields).
  bool get hasTextFilters => filterableFields.any((f) =>
      !f.isEnum && f.dartType.replaceAll('?', '') == 'String');
}
