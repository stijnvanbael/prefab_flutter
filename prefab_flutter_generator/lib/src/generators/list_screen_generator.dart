import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:prefab_flutter/prefab_flutter.dart';
import 'package:source_gen/source_gen.dart';

import '../manifest/entity_manifest.dart';

const _viewChecker = TypeChecker.fromRuntime(View);

/// Generates a `{Entity}ListScreen` [ConsumerWidget] for every class annotated
/// with [@View].
///
/// When the entity carries a [@Parent]-annotated field the generated list
/// screen:
/// - accepts the parent ID as a required constructor parameter (the value is
///   provided by the router via [state.pathParameters]),
/// - passes the parent ID to the Riverpod list provider so the provider can
///   scope its API call to the correct parent resource.
class ListScreenGenerator extends Generator {
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
    // Map entityNameLower → manifest for parent path look-up.
    final byName = {for (final m in manifests) m.entityNameLower: m};

    final buffer = StringBuffer();
    _writeHeader(buffer);
    _writeImports(sourceFileName, buffer);
    buffer.writeln();

    for (final manifest in manifests) {
      final parentName = manifest.parentEntityNameLower;
      EntityManifest? parentManifest;
      if (parentName != null) {
        parentManifest = byName[parentName];
        if (parentManifest == null) {
          throw InvalidGenerationSourceError(
            'Entity "${manifest.entityName}" has a @Parent field referencing '
            '"$parentName", but no @View-annotated class with that name was '
            'found in the same source file. Define the parent entity in the '
            'same source file as its children.',
            element: null,
          );
        }
      }
      _writeListScreenClass(manifest, parentManifest, buffer);
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
    buffer.writeln('// ListScreenGenerator');
    buffer.writeln(sep);
    buffer.writeln();
  }

  // ---------------------------------------------------------------------------
  // Imports
  // ---------------------------------------------------------------------------

  void _writeImports(String sourceFileName, StringBuffer buffer) {
    buffer.writeln("import 'package:flutter/material.dart';");
    buffer.writeln("import 'package:flutter_riverpod/flutter_riverpod.dart';");
    buffer.writeln("import 'package:go_router/go_router.dart';");
    buffer.writeln();
    final base = sourceFileName.replaceFirst(RegExp(r'\.dart$'), '');
    buffer.writeln("import '$base.dart';");
    buffer.writeln("import '$base.provider.dart';");
  }

  // ---------------------------------------------------------------------------
  // List screen class
  // ---------------------------------------------------------------------------

  void _writeListScreenClass(
    EntityManifest manifest,
    EntityManifest? parentManifest,
    StringBuffer buffer,
  ) {
    final entity = manifest.entityName;
    final entityLower = manifest.entityNameLower;
    final hasParent = manifest.hasParent;
    final parentParamName = manifest.parentParamName;
    final parentParamType =
        hasParent ? manifest.parentField!.dartType : null;

    // Navigation target for tapping an item.
    final parentPath =
        parentManifest?.path ?? '${manifest.parentEntityNameLower}s';
    final itemPath = hasParent
        ? '/$parentPath/\$$parentParamName/${manifest.path}/\${${entityLower}.id}'
        : '/${manifest.path}/\${${entityLower}.id}';

    buffer.writeln('class ${entity}ListScreen extends ConsumerWidget {');
    if (hasParent) {
      buffer.writeln('  final $parentParamType $parentParamName;');
      buffer.writeln();
      buffer.writeln(
          '  const ${entity}ListScreen({super.key, required this.$parentParamName});');
    } else {
      buffer.writeln(
          '  const ${entity}ListScreen({super.key});');
    }
    buffer.writeln();
    buffer.writeln('  @override');
    buffer.writeln(
        '  Widget build(BuildContext context, WidgetRef ref) {');

    // Watch the correct provider variant.
    if (hasParent) {
      buffer.writeln(
          '    final ${entityLower}sAsync = ref.watch(${entityLower}sProvider($parentParamName));');
    } else {
      buffer.writeln(
          '    final ${entityLower}sAsync = ref.watch(${entityLower}sProvider);');
    }

    buffer.writeln('    return Scaffold(');
    buffer.writeln('      appBar: AppBar(');
    buffer.writeln("        title: const Text('${manifest.title}'),");
    buffer.writeln('      ),');
    buffer.writeln(
        '      body: ${entityLower}sAsync.when(');
    buffer.writeln(
        '        data: (${entityLower}s) => ListView.builder(');
    buffer.writeln('          itemCount: ${entityLower}s.length,');
    buffer.writeln(
        '          itemBuilder: (context, index) {');
    buffer.writeln(
        '            final $entityLower = ${entityLower}s[index];');
    buffer.writeln('            return ListTile(');
    if (manifest.visibleFields.isNotEmpty) {
      buffer.writeln(
          '              title: Text($entityLower.${manifest.firstLabelFieldName}.toString()),');
    }
    buffer.writeln(
        "              onTap: () => context.push('$itemPath'),");
    buffer.writeln('            );');
    buffer.writeln('          },');
    buffer.writeln('        ),');
    buffer.writeln(
        '        loading: () => const Center(child: CircularProgressIndicator()),');
    buffer.writeln(
        "        error: (error, stackTrace) => Center(child: Text('Error: \$error')),");
    buffer.writeln('      ),');
    buffer.writeln('    );');
    buffer.writeln('  }');
    buffer.writeln('}');
  }
}
