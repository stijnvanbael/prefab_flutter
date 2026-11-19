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
/// the parent ID and threads it through to the API client:
/// - `{entity}DetailProvider` becomes a `family` keyed on `(idType id, parentType parentId)`.
/// - `{entity}sProvider` becomes a `family` (`AutoDisposeFamilyAsyncNotifier`) keyed on the `parentType parentId`.
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
    final parentParamName = manifest.parentParamName;
    final parentParamType = hasParent ? manifest.parentField!.dartType : null;

    if (hasParent) {
      // Detail provider keyed on (idType id, parentType parentId).
      buffer.writeln(
          'final ${entityLower}DetailProvider = FutureProvider.autoDispose'
          '.family<$entity, (${manifest.idType}, $parentParamType)>((ref, args) =>');
      buffer.writeln(
          '    ref.watch(${entityLower}ApiClientProvider).getById(args.\$1, $parentParamName: args.\$2));');
      buffer.writeln();

      // List provider keyed on parentType parentId.
      buffer.writeln(
          'final ${entityLower}sProvider = AsyncNotifierProvider.autoDispose'
          '.family<${entity}sNotifier, List<$entity>, $parentParamType>(');
      buffer.writeln('  ${entity}sNotifier.new);');
      buffer.writeln();

      // Family notifier; the family argument is the parent id.
      buffer.writeln(
          'class ${entity}sNotifier extends AutoDisposeFamilyAsyncNotifier<List<$entity>, $parentParamType> {');
      buffer.writeln(
          '  ${entity}ApiClient get _client => ref.read(${entityLower}ApiClientProvider);');
      buffer.writeln('  $parentParamType get $parentParamName => arg;');
      buffer.writeln();
      buffer.writeln('  @override');
      buffer.writeln('  Future<List<$entity>> build($parentParamType arg) =>');
      buffer.writeln(
          '      ref.read(${entityLower}ApiClientProvider).list($parentParamName: arg);');
      buffer.writeln();
      buffer.writeln('  Future<void> _load() async {');
      buffer.writeln('    state = const AsyncLoading();');
      buffer.writeln(
          '    state = await AsyncValue.guard(() => _client.list($parentParamName: $parentParamName));');
      buffer.writeln('  }');
      buffer.writeln();
      buffer.writeln('  Future<void> create($entity $entityLower) async {');
      buffer.writeln(
          '    await _client.create($entityLower, $parentParamName: $parentParamName);');
      buffer.writeln('    await _load();');
      buffer.writeln('  }');
      if (manifest.hasUpdate) {
        buffer.writeln();
        buffer.writeln(
            '  Future<void> updateEntity($entity $entityLower) async {');
        buffer.writeln(
            '    await _client.update($entityLower, $parentParamName: $parentParamName);');
        buffer.writeln(
            '    ref.invalidate(${entityLower}DetailProvider(($entityLower.${manifest.idFieldName}${manifest.idBang}, $parentParamName)));');
        buffer.writeln('    await _load();');
        buffer.writeln('  }');
      }
      if (manifest.hasDelete) {
        buffer.writeln();
        buffer.writeln('  Future<void> delete($entity $entityLower) async {');
        buffer.writeln(
            '    await _client.delete($entityLower, $parentParamName: $parentParamName);');
        buffer.writeln(
            '    ref.invalidate(${entityLower}DetailProvider(($entityLower.${manifest.idFieldName}${manifest.idBang}, $parentParamName)));');
        buffer.writeln('    await _load();');
        buffer.writeln('  }');
      }
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
          '<${entity}sNotifier, List<$entity>>(${entity}sNotifier.new);');
      buffer.writeln();

      // AsyncNotifier.
      buffer.writeln(
          'class ${entity}sNotifier extends AutoDisposeAsyncNotifier<List<$entity>> {');
      buffer.writeln(
          '  ${entity}ApiClient get _client => ref.read(${entityLower}ApiClientProvider);');
      buffer.writeln();
      buffer.writeln('  @override');
      buffer.writeln('  Future<List<$entity>> build() =>');
      buffer.writeln('      ref.read(${entityLower}ApiClientProvider).list();');
      buffer.writeln();
      buffer.writeln('  Future<void> _load() async {');
      buffer.writeln('    state = const AsyncLoading();');
      buffer
          .writeln('    state = await AsyncValue.guard(() => _client.list());');
      buffer.writeln('  }');
      buffer.writeln();
      buffer.writeln('  Future<void> create($entity $entityLower) async {');
      buffer.writeln('    await _client.create($entityLower);');
      buffer.writeln('    await _load();');
      buffer.writeln('  }');
      if (manifest.hasUpdate) {
        buffer.writeln();
        buffer.writeln(
            '  Future<void> updateEntity($entity $entityLower) async {');
        buffer.writeln('    await _client.update($entityLower);');
        buffer.writeln(
            '    ref.invalidate(${entityLower}DetailProvider($entityLower.${manifest.idFieldName}${manifest.idBang}));');
        buffer.writeln('    await _load();');
        buffer.writeln('  }');
      }
      if (manifest.hasDelete) {
        buffer.writeln();
        buffer.writeln('  Future<void> delete($entity $entityLower) async {');
        buffer.writeln('    await _client.delete($entityLower);');
        buffer.writeln(
            '    ref.invalidate(${entityLower}DetailProvider($entityLower.${manifest.idFieldName}${manifest.idBang}));');
        buffer.writeln('    await _load();');
        buffer.writeln('  }');
      }
      buffer.writeln('}');
    }

    buffer.writeln();
    buffer.writeln(
        'final ${entityLower}ApiClientProvider = Provider.autoDispose<${entity}ApiClient>(');
    buffer.writeln(
        '  (ref) => ${entity}ApiClient(ref.watch(prefabDioProvider)));');
  }
}
