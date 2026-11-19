import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:prefab_flutter/prefab_flutter.dart';
import 'package:source_gen/source_gen.dart';

import '../manifest/entity_manifest.dart';
import '../manifest/entity_paths.dart';
import '../manifest/field_manifest.dart';

const _viewChecker = TypeChecker.fromRuntime(View);

/// Generates a read-only `{Entity}DetailScreen` [ConsumerWidget] for every
/// class annotated with [@View].
///
/// The generated screen:
/// - watches `{entity}DetailProvider(id)` from Riverpod,
/// - shows all non-hidden [@Field] fields as labelled [ListTile]s,
/// - sets the AppBar title from [@View.title],
/// - adds an **Edit** AppBar action when [@Update] is present,
/// - adds a **Delete** AppBar action (with confirmation dialog) when
///   [@Delete] is present.
class DetailScreenGenerator extends Generator {
  @override
  String generate(LibraryReader library, BuildStep buildStep) {
    final annotated = library.annotatedWith(_viewChecker).toList();
    if (annotated.isEmpty) return '';

    final manifests = <EntityManifest>[];
    for (final a in annotated) {
      final element = a.element;
      if (element is! ClassElement) {
        throw InvalidGenerationSourceError(
          '@View can only be applied to classes.',
          element: element,
        );
      }
      manifests.add(EntityManifest.from(element, a.annotation));
    }

    final sourceFileName = buildStep.inputId.path.split('/').last;
    final paths = EntityPaths(manifests);

    final buffer = StringBuffer();
    _writeHeader(buffer);
    _writeImports(manifests, sourceFileName, buffer);
    for (final manifest in manifests) {
      buffer.writeln();
      _writeDetailScreenClass(manifest, paths, buffer);
    }
    return buffer.toString();
  }

  // ---------------------------------------------------------------------------
  // Header
  // ---------------------------------------------------------------------------

  void _writeHeader(StringBuffer buffer) {
    const separator =
        '// **************************************************************************';
    buffer.writeln('// GENERATED CODE - DO NOT MODIFY BY HAND');
    buffer.writeln('//');
    buffer.writeln(separator);
    buffer.writeln('// DetailScreenGenerator');
    buffer.writeln(separator);
    buffer.writeln();
  }

  // ---------------------------------------------------------------------------
  // Imports
  // ---------------------------------------------------------------------------

  void _writeImports(
    List<EntityManifest> manifests,
    String sourceFileName,
    StringBuffer buffer,
  ) {
    buffer.writeln("import 'package:material_ui/material_ui.dart';");
    buffer.writeln("import 'package:flutter_riverpod/flutter_riverpod.dart';");

    if (manifests.any((m) => m.hasUpdate || m.hasDelete)) {
      buffer.writeln("import 'package:go_router/go_router.dart';");
    }

    if (manifests.any((m) => m.hasDelete)) {
      buffer.writeln(
          "import 'package:prefab_flutter_widgets/prefab_flutter_widgets.dart';");
    }

    // Relative import for the entity file.
    buffer.writeln("import '$sourceFileName';");
  }

  // ---------------------------------------------------------------------------
  // Detail screen class
  // ---------------------------------------------------------------------------

  void _writeDetailScreenClass(
      EntityManifest manifest, EntityPaths paths, StringBuffer buffer) {
    final entity = manifest.entityName;
    final entityLower = manifest.entityNameLower;
    final hasParent = manifest.hasParent;
    final parentParamName = manifest.parentParamName;
    final parentParamType = hasParent ? manifest.parentField!.dartType : null;

    buffer.writeln('class ${entity}DetailScreen extends ConsumerWidget {');
    buffer.writeln('  final ${manifest.idType} id;');
    if (hasParent) {
      buffer.writeln('  final $parentParamType $parentParamName;');
    }
    buffer.writeln();
    if (hasParent) {
      buffer.writeln(
          '  const ${entity}DetailScreen({super.key, required this.id, required this.$parentParamName});');
    } else {
      buffer.writeln(
          '  const ${entity}DetailScreen({super.key, required this.id});');
    }
    buffer.writeln();
    buffer.writeln('  @override');
    buffer.writeln('  Widget build(BuildContext context, WidgetRef ref) {');
    if (hasParent) {
      buffer.writeln(
          '    final ${entityLower}Async = ref.watch(${entityLower}DetailProvider((id, $parentParamName)));');
    } else {
      buffer.writeln(
          '    final ${entityLower}Async = ref.watch(${entityLower}DetailProvider(id));');
    }
    buffer.writeln('    return Scaffold(');
    buffer.writeln('      appBar: AppBar(');
    buffer.writeln("        title: const Text('${manifest.title}'),");

    _writeAppBarActions(manifest, paths, buffer);

    buffer.writeln('      ),');

    _writeBody(manifest, buffer);

    buffer.writeln('    );');
    buffer.writeln('  }');
    buffer.writeln('}');
  }

  // ---------------------------------------------------------------------------
  // AppBar actions
  // ---------------------------------------------------------------------------

  void _writeAppBarActions(
      EntityManifest manifest, EntityPaths paths, StringBuffer buffer) {
    if (!manifest.hasUpdate && !manifest.hasDelete) return;

    final entityLower = manifest.entityNameLower;
    final listProviderArg =
        manifest.hasParent ? '(${manifest.parentParamName})' : '';

    buffer.writeln('        actions: [');

    if (manifest.hasUpdate) {
      buffer.writeln('          IconButton(');
      buffer.writeln('            icon: const Icon(Icons.edit),');
      buffer.writeln("            tooltip: 'Edit',");
      buffer.writeln(
          "            onPressed: () => context.push('${paths.editPath(manifest, r'$id')}'),");
      buffer.writeln('          ),');
    }

    if (manifest.hasDelete) {
      buffer.writeln('          IconButton(');
      buffer.writeln('            icon: const Icon(Icons.delete),');
      buffer.writeln("            tooltip: 'Delete',");
      buffer.writeln('            onPressed: ${entityLower}Async.hasValue');
      buffer.writeln('                ? () async {');
      buffer.writeln(
          '                    final $entityLower = ${entityLower}Async.value!;');
      buffer.writeln(
          '                    final confirmed = await showPrefabDeleteDialog(');
      buffer.writeln('                      context: context,');
      buffer.writeln('                      item: $entityLower,');
      buffer.writeln(
          '                      itemLabel: $entityLower.${manifest.firstLabelFieldName}.toString(),');
      buffer.writeln(
          '                      onDelete: () => ref.read(${entityLower}sProvider$listProviderArg.notifier).delete($entityLower),');
      buffer.writeln('                    );');
      buffer.writeln('                    if (confirmed && context.mounted) {');
      buffer.writeln('                      context.pop();');
      buffer.writeln('                    }');
      buffer.writeln('                  }');
      buffer.writeln('                : null,');
      buffer.writeln('          ),');
    }

    buffer.writeln('        ],');
  }

  // ---------------------------------------------------------------------------
  // Body
  // ---------------------------------------------------------------------------

  void _writeBody(EntityManifest manifest, StringBuffer buffer) {
    final entityLower = manifest.entityNameLower;
    final visibleFields = manifest.visibleFields;

    buffer.writeln('      body: ${entityLower}Async.when(');
    buffer.writeln('        data: ($entityLower) => ListView(');
    buffer.writeln('          padding: const EdgeInsets.all(16),');
    buffer.writeln('          children: [');

    for (final field in visibleFields) {
      _writeFieldTile(field, entityLower, buffer);
    }

    buffer.writeln('          ],');
    buffer.writeln('        ),');
    buffer.writeln(
        '        loading: () => const Center(child: CircularProgressIndicator()),');
    buffer.writeln(
        "        error: (error, stackTrace) => Center(child: Text('Error: \$error')),");
    buffer.writeln('      ),');
  }

  void _writeFieldTile(
    FieldManifest field,
    String entityLower,
    StringBuffer buffer,
  ) {
    buffer.writeln('            ListTile(');
    buffer.writeln("              title: const Text('${field.label}'),");
    final value = field.isNullable
        ? "$entityLower.${field.name}?.toString() ?? '\u2014'"
        : '$entityLower.${field.name}.toString()';
    buffer.writeln('              subtitle: Text($value),');
    buffer.writeln('            ),');
  }
}
