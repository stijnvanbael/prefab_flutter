import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:prefab_flutter/prefab_flutter.dart';
import 'package:source_gen/source_gen.dart';

import '../manifest/entity_manifest.dart';
import '../manifest/field_manifest.dart';

/// Generates a read-only `{Entity}DetailScreen` [ConsumerWidget] for every
/// class annotated with [@View].
///
/// The generated screen:
/// - watches `{entity}DetailProvider(id)` from Riverpod,
/// - shows all non-hidden [@FormField] fields as labelled [ListTile]s,
/// - sets the AppBar title from [@View.title],
/// - adds an **Edit** AppBar action when [@Update] is present,
/// - adds a **Delete** AppBar action (with confirmation dialog) when
///   [@Delete] is present.
class DetailScreenGenerator extends GeneratorForAnnotation<View> {
  @override
  String generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    if (element is! ClassElement) {
      throw InvalidGenerationSourceError(
        '@View can only be applied to classes.',
        element: element,
      );
    }

    final manifest = EntityManifest.from(element, annotation);

    // Derive a relative import for the entity source file.
    final inputPath = buildStep.inputId.path; // e.g. lib/src/product.dart
    final sourceFileName = inputPath.split('/').last; // e.g. product.dart

    return _generate(manifest, sourceFileName);
  }

  String _generate(EntityManifest manifest, String sourceFileName) {
    final buffer = StringBuffer();

    _writeHeader(buffer);
    _writeImports(manifest, sourceFileName, buffer);
    buffer.writeln();
    _writeDetailScreenClass(manifest, buffer);

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
    EntityManifest manifest,
    String sourceFileName,
    StringBuffer buffer,
  ) {
    buffer.writeln("import 'package:flutter/material.dart';");
    buffer.writeln("import 'package:flutter_riverpod/flutter_riverpod.dart';");

    if (manifest.hasUpdate || manifest.hasDelete) {
      buffer.writeln("import 'package:go_router/go_router.dart';");
    }

    if (manifest.hasDelete) {
      buffer
          .writeln("import 'package:prefab_flutter_widgets/prefab_flutter_widgets.dart';");
    }

    // Relative import for the entity file.
    buffer.writeln("import '$sourceFileName';");
  }

  // ---------------------------------------------------------------------------
  // Detail screen class
  // ---------------------------------------------------------------------------

  void _writeDetailScreenClass(EntityManifest manifest, StringBuffer buffer) {
    final entity = manifest.entityName;
    final entityLower = manifest.entityNameLower;
    final hasParent = manifest.hasParent;
    final parentParamName = manifest.parentParamName;
    final parentParamType =
        hasParent ? manifest.parentField!.dartType : null;

    buffer.writeln('class ${entity}DetailScreen extends ConsumerWidget {');
    buffer.writeln('  final Object id;');
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
    buffer.writeln(
        '  Widget build(BuildContext context, WidgetRef ref) {');
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

    _writeAppBarActions(manifest, buffer);

    buffer.writeln('      ),');

    _writeBody(manifest, buffer);

    buffer.writeln('    );');
    buffer.writeln('  }');
    buffer.writeln('}');
  }

  // ---------------------------------------------------------------------------
  // AppBar actions
  // ---------------------------------------------------------------------------

  void _writeAppBarActions(EntityManifest manifest, StringBuffer buffer) {
    if (!manifest.hasUpdate && !manifest.hasDelete) return;

    final entityLower = manifest.entityNameLower;

    buffer.writeln('        actions: [');

    if (manifest.hasUpdate) {
      buffer.writeln('          IconButton(');
      buffer.writeln('            icon: const Icon(Icons.edit),');
      buffer.writeln("            tooltip: 'Edit',");
      buffer.writeln(
          "            onPressed: () => context.push('/${manifest.path}/\$id/edit'),");
      buffer.writeln('          ),');
    }

    if (manifest.hasDelete) {
      buffer.writeln('          IconButton(');
      buffer.writeln('            icon: const Icon(Icons.delete),');
      buffer.writeln("            tooltip: 'Delete',");
      buffer.writeln(
          '            onPressed: ${entityLower}Async.hasValue');
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
          '                      onDelete: () => ref.read(${entityLower}sProvider.notifier).delete($entityLower),');
      buffer.writeln('                    );');
      buffer.writeln(
          '                    if (confirmed && context.mounted) {');
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
    buffer.writeln(
        '        data: ($entityLower) => ListView(');
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
    buffer.writeln(
        '              subtitle: Text($entityLower.${field.name}.toString()),');
    buffer.writeln('            ),');
  }
}
