import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:prefab_flutter/prefab_flutter.dart';
import 'package:source_gen/source_gen.dart';

import '../manifest/entity_manifest.dart';

const _viewChecker = TypeChecker.fromRuntime(View);

/// Generates Riverpod providers for every class annotated with [@View].
///
/// Produced providers include:
/// - `{entity}DetailProvider` — `FutureProvider.autoDispose.family` that fetches a single
///   entity by ID via the generated API client,
/// - `{entity}sProvider` — an `AsyncNotifierProvider.autoDispose` (`AutoDisposeAsyncNotifier`) for the full list with
///   create / update / delete mutations.
///
/// When the entity carries a [@Parent]-annotated field, every provider accepts
/// the ids of its whole ancestor chain (outermost first) and threads them
/// through to the API client:
/// - `{entity}DetailProvider` becomes a `family` keyed on `(id, ancestor ids...)`.
/// - `{entity}sProvider` becomes a `family` (`AutoDisposeFamilyAsyncNotifier`)
///   keyed on the parent id, or on a record of the ancestor ids when the
///   entity is nested more than one level deep.
class ProviderGenerator extends Generator {
  @override
  String generate(LibraryReader library, BuildStep buildStep) {
    final annotated = library.annotatedWith(_viewChecker).toList();
    if (annotated.isEmpty) return '';

    final manifests = <EntityManifest>[];
    for (final a in annotated) {
      final element = a.element;
      if (element is! ClassElement) continue;
      manifests.add(EntityManifest.from(element, a.annotation));
    }

    final sourceFileName = buildStep.inputId.path.split('/').last;

    final buffer = StringBuffer();
    _writeHeader(buffer);
    _writeImports(sourceFileName, buffer);
    buffer.writeln();

    for (final manifest in manifests) {
      _writeProviders(manifest, buffer);
      buffer.writeln();
    }

    return buffer.toString();
  }

  // ---------------------------------------------------------------------------
  // Header
  // ---------------------------------------------------------------------------

  void _writeHeader(StringBuffer buffer) {
    const sep =
        '// **************************************************************************';
    buffer.writeln('// GENERATED CODE - DO NOT MODIFY BY HAND');
    buffer.writeln('//');
    buffer.writeln(sep);
    buffer.writeln('// ProviderGenerator');
    buffer.writeln(sep);
    buffer.writeln();
  }

  // ---------------------------------------------------------------------------
  // Imports
  // ---------------------------------------------------------------------------

  void _writeImports(String sourceFileName, StringBuffer buffer) {
    buffer.writeln("import 'dart:async';");
    buffer.writeln();
    buffer.writeln("import 'package:flutter_riverpod/flutter_riverpod.dart';");
    buffer.writeln(
        "import 'package:prefab_flutter_widgets/prefab_flutter_widgets.dart';");
    buffer.writeln();
    final base = sourceFileName.replaceFirst(RegExp(r'\.dart$'), '');
    buffer.writeln("import '$base.dart';");
    buffer.writeln("import '$base.api_client.dart';");
  }

  // ---------------------------------------------------------------------------
  // Provider declarations
  // ---------------------------------------------------------------------------

  void _writeProviders(EntityManifest manifest, StringBuffer buffer) {
    final entity = manifest.entityName;
    final entityLower = manifest.entityNameLower;
    final hasParent = manifest.hasParent;
    final parentParamType = hasParent ? manifest.parentKeyType : null;

    if (hasParent) {
      // Detail provider keyed on (id, ancestor ids...), outermost first.
      final named = [
        for (var i = 0; i < manifest.ancestors.length; i++)
          '${manifest.ancestors[i].paramName}: args.\$${i + 2}',
      ].join(', ');
      buffer.writeln(
          'final ${entityLower}DetailProvider = FutureProvider.autoDispose'
          '.family<$entity, ${manifest.detailKeyType}>((ref, args) =>');
      buffer.writeln(
          '    ref.watch(${entityLower}ApiClientProvider).getById(args.\$1, $named));');
      buffer.writeln();

      // List provider keyed on parentType parentId.
      buffer.writeln(
          'final ${entityLower}sProvider = AsyncNotifierProvider.autoDispose'
          '.family<${entity}sNotifier, PrefabPage<$entity>, $parentParamType>(');
      buffer.writeln('  ${entity}sNotifier.new);');
      buffer.writeln();

      // Family notifier; the family argument is the parent id.
      buffer.writeln(
          'class ${entity}sNotifier extends AutoDisposeFamilyAsyncNotifier<PrefabPage<$entity>, $parentParamType> {');
      for (var i = 0; i < manifest.ancestors.length; i++) {
        final a = manifest.ancestors[i];
        final access = manifest.depth == 1 ? 'arg' : 'arg.\$${i + 1}';
        buffer.writeln('  ${a.idType} get ${a.paramName} => $access;');
      }
      buffer.writeln();
      _writeNotifierBody(manifest, buffer,
          buildSignature: '$parentParamType arg',
          parentArg: manifest.ancestorNamedArgs());
      buffer.writeln('}');
    } else {
      // Detail provider keyed on the typed id.
      buffer.writeln(
          'final ${entityLower}DetailProvider = FutureProvider.autoDispose'
          '.family<$entity, ${manifest.idType}>((ref, id) =>');
      buffer.writeln(
          '    ref.watch(${entityLower}ApiClientProvider).getById(id));');
      buffer.writeln();

      // List provider (no family arg).
      buffer.writeln(
          'final ${entityLower}sProvider = AsyncNotifierProvider.autoDispose'
          '<${entity}sNotifier, PrefabPage<$entity>>(${entity}sNotifier.new);');
      buffer.writeln();

      // AsyncNotifier.
      buffer.writeln(
          'class ${entity}sNotifier extends AutoDisposeAsyncNotifier<PrefabPage<$entity>> {');
      _writeNotifierBody(manifest, buffer, buildSignature: '', parentArg: '');
      buffer.writeln('}');
    }

    buffer.writeln();
    buffer.writeln(
        'final ${entityLower}ApiClientProvider = Provider.autoDispose<${entity}ApiClient>(');
    buffer.writeln(
        '  (ref) => ${entity}ApiClient(ref.watch(prefabDioProvider), ref.watch(prefabListAdapterProvider)));');
  }

  /// Writes the members shared by the plain and the family list notifier:
  /// the list query state (search, sort, page), `build`, `_load`, the query
  /// setters and the create / update / delete mutations.
  ///
  /// [buildSignature] is the parameter list of `build` (`'int arg'` for a
  /// family notifier, empty otherwise); [parentArg] is the named parent
  /// argument passed to the API client (`'postId: postId'`, or empty).
  void _writeNotifierBody(
    EntityManifest manifest,
    StringBuffer buffer, {
    required String buildSignature,
    required String parentArg,
  }) {
    final entity = manifest.entityName;
    final entityLower = manifest.entityNameLower;
    final hasParent = manifest.hasParent;
    final listArgs = [
      if (hasParent) parentArg,
      'search: _search',
      'sort: _sort',
      'descending: _descending',
      if (manifest.paged) ...['page: _page', 'pageSize: _pageSize'],
    ].join(', ');
    final clientTrailing = hasParent ? ', $parentArg' : '';
    final detailKeyArgs = manifest.detailKeyExpr(
        '$entityLower.${manifest.idFieldName}${manifest.idBang}',
        (a) => a.paramName);

    buffer.writeln(
        '  ${entity}ApiClient get _client => ref.read(${entityLower}ApiClientProvider);');
    buffer.writeln();
    buffer.writeln('  String _search = \'\';');
    buffer.writeln('  String? _sort;');
    buffer.writeln('  bool _descending = false;');
    buffer.writeln('  int _page = 0;');
    if (manifest.paged) buffer.writeln('  int? _pageSize;');
    buffer.writeln('  Timer? _searchDebounce;');
    buffer.writeln();
    buffer.writeln('  /// The search text currently applied to the list.');
    buffer.writeln('  String get search => _search;');
    buffer.writeln();
    buffer.writeln('  /// The field the list is sorted by, or `null`.');
    buffer.writeln('  String? get sort => _sort;');
    buffer.writeln();
    buffer.writeln('  /// Whether the list is sorted descending.');
    buffer.writeln('  bool get descending => _descending;');
    buffer.writeln();
    buffer.writeln('  /// Zero-based index of the current page.');
    buffer.writeln('  int get page => _page;');
    buffer.writeln();
    buffer.writeln('  @override');
    buffer.writeln('  Future<PrefabPage<$entity>> build($buildSignature) {');
    buffer.writeln('    ref.onDispose(() => _searchDebounce?.cancel());');
    buffer.writeln('    return _client.list($listArgs);');
    buffer.writeln('  }');
    buffer.writeln();
    buffer.writeln('  Future<void> _load() async {');
    buffer.writeln(
        '    state = const AsyncLoading<PrefabPage<$entity>>().copyWithPrevious(state);');
    buffer.writeln(
        '    state = await AsyncValue.guard(() => _client.list($listArgs));');
    buffer.writeln('  }');
    buffer.writeln();
    buffer.writeln('  /// Applies [query] after a short pause in typing and');
    buffer.writeln('  /// returns to the first page.');
    buffer.writeln('  void setSearch(String query) {');
    buffer.writeln('    _searchDebounce?.cancel();');
    buffer.writeln(
        '    _searchDebounce = Timer(const Duration(milliseconds: 300), () {');
    buffer.writeln('      if (query == _search) return;');
    buffer.writeln('      _search = query;');
    buffer.writeln('      _page = 0;');
    buffer.writeln('      _load();');
    buffer.writeln('    });');
    buffer.writeln('  }');
    buffer.writeln();
    buffer.writeln(
        '  /// Sorts by [field] (`null` clears the sort) and reloads.');
    buffer.writeln(
        '  Future<void> setSort(String? field, {bool descending = false}) {');
    buffer.writeln('    _sort = field;');
    buffer.writeln('    _descending = descending;');
    buffer.writeln('    _page = 0;');
    buffer.writeln('    return _load();');
    buffer.writeln('  }');
    if (manifest.paged) {
      buffer.writeln();
      buffer.writeln('  /// Loads the zero-based page [page].');
      buffer.writeln('  Future<void> goToPage(int page) {');
      buffer.writeln('    _page = page;');
      buffer.writeln('    return _load();');
      buffer.writeln('  }');
      buffer.writeln();
      buffer.writeln(
          '  /// Changes the page size and returns to the first page.');
      buffer.writeln('  Future<void> setPageSize(int pageSize) {');
      buffer.writeln('    _pageSize = pageSize;');
      buffer.writeln('    _page = 0;');
      buffer.writeln('    return _load();');
      buffer.writeln('  }');
    }
    if (manifest.hasCreate) {
      buffer.writeln();
      buffer.writeln('  Future<void> create($entity $entityLower) async {');
      buffer.writeln('    await _client.create($entityLower$clientTrailing);');
      buffer.writeln('    await _load();');
      buffer.writeln('  }');
    }
    if (manifest.hasUpdate) {
      buffer.writeln();
      buffer
          .writeln('  Future<void> updateEntity($entity $entityLower) async {');
      buffer.writeln('    await _client.update($entityLower$clientTrailing);');
      buffer.writeln(
          '    ref.invalidate(${entityLower}DetailProvider($detailKeyArgs));');
      buffer.writeln('    await _load();');
      buffer.writeln('  }');
    }
    if (manifest.hasDelete) {
      buffer.writeln();
      buffer.writeln('  Future<void> delete($entity $entityLower) async {');
      buffer.writeln('    await _client.delete($entityLower$clientTrailing);');
      buffer.writeln(
          '    ref.invalidate(${entityLower}DetailProvider($detailKeyArgs));');
      buffer.writeln('    await _load();');
      buffer.writeln('  }');
    }
  }
}
