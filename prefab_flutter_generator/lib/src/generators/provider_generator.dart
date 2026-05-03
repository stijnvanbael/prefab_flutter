import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:prefab_flutter/prefab_flutter.dart';
import 'package:source_gen/source_gen.dart';

import '../manifest/entity_manifest.dart';

const _viewChecker = TypeChecker.fromRuntime(View);

/// Generates Riverpod providers for every class annotated with [@View].
///
/// Produced providers include:
/// - `{entity}DetailProvider` — `FutureProvider.family` that fetches a single
///   entity by ID via the generated API client,
/// - `{entity}sProvider` — a `StateNotifierProvider` for the full list with
///   create / update / delete mutations.
///
/// When the entity carries a [@Parent]-annotated field, every provider accepts
/// the parent ID and threads it through to the API client:
/// - `{entity}DetailProvider` becomes a `family` keyed on `(Object id, parentType parentId)`.
/// - `{entity}sProvider` becomes a `family` keyed on the `parentType parentId`.
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
    buffer.writeln(
        "import 'package:flutter_riverpod/flutter_riverpod.dart';");
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
    final parentParamType =
        hasParent ? manifest.parentField!.dartType : null;

    if (hasParent) {
      // Detail provider keyed on (Object id, parentType parentId).
      buffer.writeln(
          'final ${entityLower}DetailProvider = FutureProvider.autoDispose'
          '.family<$entity, (Object, $parentParamType)>((ref, args) =>');
      buffer.writeln(
          '    ref.watch(${entityLower}ApiClientProvider).getById(args.\$1, $parentParamName: args.\$2));');
      buffer.writeln();

      // List provider keyed on parentType parentId.
      buffer.writeln(
          'final ${entityLower}sProvider = StateNotifierProvider.autoDispose'
          '.family<${entity}sNotifier, AsyncValue<List<$entity>>, $parentParamType>(');
      buffer.writeln(
          '  (ref, $parentParamName) => ${entity}sNotifier(ref.watch(${entityLower}ApiClientProvider), $parentParamName));');
      buffer.writeln();

      // StateNotifier with parentId threaded through.
      buffer.writeln(
          'class ${entity}sNotifier extends StateNotifier<AsyncValue<List<$entity>>> {');
      buffer.writeln('  final ${entity}ApiClient _client;');
      buffer.writeln('  final $parentParamType $parentParamName;');
      buffer.writeln();
      buffer.writeln(
          '  ${entity}sNotifier(this._client, this.$parentParamName)');
      buffer.writeln('      : super(const AsyncValue.loading()) {');
      buffer.writeln('    _load();');
      buffer.writeln('  }');
      buffer.writeln();
      buffer.writeln('  Future<void> _load() async {');
      buffer.writeln('    state = const AsyncValue.loading();');
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
        buffer.writeln('  Future<void> update($entity $entityLower) async {');
        buffer.writeln(
            '    await _client.update($entityLower, $parentParamName: $parentParamName);');
        buffer.writeln('    await _load();');
        buffer.writeln('  }');
      }
      if (manifest.hasDelete) {
        buffer.writeln();
        buffer.writeln('  Future<void> delete($entity $entityLower) async {');
        buffer.writeln(
            '    await _client.delete($entityLower, $parentParamName: $parentParamName);');
        buffer.writeln('    await _load();');
        buffer.writeln('  }');
      }
      buffer.writeln('}');
    } else {
      // Detail provider keyed on Object id.
      buffer.writeln(
          'final ${entityLower}DetailProvider = FutureProvider.autoDispose'
          '.family<$entity, Object>((ref, id) =>');
      buffer.writeln(
          '    ref.watch(${entityLower}ApiClientProvider).getById(id));');
      buffer.writeln();

      // List provider (no family arg).
      buffer.writeln(
          'final ${entityLower}sProvider = StateNotifierProvider.autoDispose'
          '<${entity}sNotifier, AsyncValue<List<$entity>>>(');
      buffer.writeln(
          '  (ref) => ${entity}sNotifier(ref.watch(${entityLower}ApiClientProvider)));');
      buffer.writeln();

      // StateNotifier.
      buffer.writeln(
          'class ${entity}sNotifier extends StateNotifier<AsyncValue<List<$entity>>> {');
      buffer.writeln('  final ${entity}ApiClient _client;');
      buffer.writeln();
      buffer.writeln(
          '  ${entity}sNotifier(this._client) : super(const AsyncValue.loading()) {');
      buffer.writeln('    _load();');
      buffer.writeln('  }');
      buffer.writeln();
      buffer.writeln('  Future<void> _load() async {');
      buffer.writeln('    state = const AsyncValue.loading();');
      buffer.writeln(
          '    state = await AsyncValue.guard(() => _client.list());');
      buffer.writeln('  }');
      buffer.writeln();
      buffer.writeln('  Future<void> create($entity $entityLower) async {');
      buffer.writeln('    await _client.create($entityLower);');
      buffer.writeln('    await _load();');
      buffer.writeln('  }');
      if (manifest.hasUpdate) {
        buffer.writeln();
        buffer.writeln('  Future<void> update($entity $entityLower) async {');
        buffer.writeln('    await _client.update($entityLower);');
        buffer.writeln('    await _load();');
        buffer.writeln('  }');
      }
      if (manifest.hasDelete) {
        buffer.writeln();
        buffer.writeln('  Future<void> delete($entity $entityLower) async {');
        buffer.writeln('    await _client.delete($entityLower);');
        buffer.writeln('    await _load();');
        buffer.writeln('  }');
      }
      buffer.writeln('}');
    }

    buffer.writeln();
    buffer.writeln(
        'final ${entityLower}ApiClientProvider = Provider.autoDispose<${entity}ApiClient>(');
    buffer.writeln('  (ref) => ${entity}ApiClient(ref.watch(dioProvider)));');
  }
}
