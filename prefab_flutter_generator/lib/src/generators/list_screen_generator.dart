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
    final hasSearchable = manifest.hasSearchable;
    final hasSortable = manifest.hasSortable;
    final needsState = hasSearchable || hasSortable;

    if (needsState) {
      _writeStatefulListScreenClass(manifest, parentManifest, buffer);
    } else {
      _writeStatelessListScreenClass(manifest, parentManifest, buffer);
    }
  }

  // ---------------------------------------------------------------------------
  // Stateless list screen (no search/sort)
  // ---------------------------------------------------------------------------

  void _writeStatelessListScreenClass(
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

    final parentPath =
        parentManifest?.path ?? '${manifest.parentEntityNameLower}s';
    final itemPath = hasParent
        ? '/$parentPath/\$$parentParamName/${manifest.path}/\${$entityLower.id}'
        : '/${manifest.path}/\${$entityLower.id}';

    buffer.writeln('class ${entity}ListScreen extends ConsumerWidget {');
    if (hasParent) {
      buffer.writeln('  final $parentParamType $parentParamName;');
      buffer.writeln();
      buffer.writeln(
          '  const ${entity}ListScreen({super.key, required this.$parentParamName});');
    } else {
      buffer.writeln('  const ${entity}ListScreen({super.key});');
    }
    buffer.writeln();
    buffer.writeln('  @override');
    buffer.writeln('  Widget build(BuildContext context, WidgetRef ref) {');

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
    buffer.writeln('      body: ${entityLower}sAsync.when(');
    buffer.writeln(
        '        data: (${entityLower}s) => ListView.builder(');
    buffer.writeln('          itemCount: ${entityLower}s.length,');
    buffer.writeln('          itemBuilder: (context, index) {');
    buffer.writeln('            final $entityLower = ${entityLower}s[index];');
    buffer.writeln('            return ListTile(');
    if (manifest.visibleFields.isNotEmpty) {
      buffer.writeln(
          '              title: Text($entityLower.${manifest.firstLabelFieldName}.toString()),');
    }
    buffer.writeln("              onTap: () => context.push('$itemPath'),");
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

  // ---------------------------------------------------------------------------
  // Stateful list screen (with search bar and/or sort controls)
  // ---------------------------------------------------------------------------

  void _writeStatefulListScreenClass(
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
    final hasSearchable = manifest.hasSearchable;
    final hasSortable = manifest.hasSortable;
    final searchableFields = manifest.searchableFields;
    final sortableFields = manifest.sortableFields;

    final parentPath =
        parentManifest?.path ?? '${manifest.parentEntityNameLower}s';
    final itemPath = hasParent
        ? '/$parentPath/\$$parentParamName/${manifest.path}/\${$entityLower.id}'
        : '/${manifest.path}/\${$entityLower.id}';

    // Widget class declaration
    buffer.writeln(
        'class ${entity}ListScreen extends ConsumerStatefulWidget {');
    if (hasParent) {
      buffer.writeln('  final $parentParamType $parentParamName;');
      buffer.writeln();
      buffer.writeln(
          '  const ${entity}ListScreen({super.key, required this.$parentParamName});');
    } else {
      buffer.writeln('  const ${entity}ListScreen({super.key});');
    }
    buffer.writeln();
    buffer.writeln('  @override');
    buffer.writeln(
        '  ConsumerState<${entity}ListScreen> createState() => _${entity}ListScreenState();');
    buffer.writeln('}');
    buffer.writeln();

    // State class
    buffer.writeln(
        'class _${entity}ListScreenState extends ConsumerState<${entity}ListScreen> {');
    if (hasSearchable) {
      buffer.writeln("  String _searchQuery = '';");
    }
    if (hasSortable) {
      buffer.writeln('  String? _sortColumn;');
    }
    buffer.writeln();
    buffer.writeln('  @override');
    buffer.writeln('  Widget build(BuildContext context) {');

    if (hasParent) {
      buffer.writeln(
          '    final ${entityLower}sAsync = ref.watch(${entityLower}sProvider(widget.$parentParamName));');
    } else {
      buffer.writeln(
          '    final ${entityLower}sAsync = ref.watch(${entityLower}sProvider);');
    }

    buffer.writeln('    return Scaffold(');
    buffer.writeln('      appBar: AppBar(');
    buffer.writeln("        title: const Text('${manifest.title}'),");
    buffer.writeln('      ),');
    buffer.writeln('      body: Column(');
    buffer.writeln('        children: [');

    // Search bar
    if (hasSearchable) {
      buffer.writeln('          TextField(');
      buffer.writeln('            decoration: const InputDecoration(');
      buffer.writeln("              labelText: 'Search',");
      buffer.writeln('              prefixIcon: Icon(Icons.search),');
      buffer.writeln('            ),');
      buffer.writeln(
          '            onChanged: (value) => setState(() => _searchQuery = value),');
      buffer.writeln('          ),');
    }

    // Sort controls
    if (hasSortable) {
      buffer.writeln('          DropdownButton<String>(');
      buffer.writeln('            value: _sortColumn,');
      buffer.writeln("            hint: const Text('Sort by'),");
      buffer.writeln('            items: const [');
      for (final field in sortableFields) {
        buffer.writeln(
            "              DropdownMenuItem(value: '${field.name}', child: Text('${field.label}')),");
      }
      buffer.writeln('            ],');
      buffer.writeln(
          '            onChanged: (v) => setState(() => _sortColumn = v),');
      buffer.writeln('          ),');
    }

    // List
    buffer.writeln('          Expanded(');
    buffer.writeln('            child: ${entityLower}sAsync.when(');
    buffer.writeln('              data: (${entityLower}s) {');
    buffer.writeln('                var filtered = ${entityLower}s;');

    // Apply search filter
    if (hasSearchable) {
      buffer.writeln(
          '                if (_searchQuery.isNotEmpty) {');
      final searchConditions = searchableFields
          .map((f) =>
              '$entityLower.${f.name}.toString().toLowerCase().contains(_searchQuery.toLowerCase())')
          .join(' ||\n                    ');
      buffer.writeln(
          '                  filtered = filtered.where(($entityLower) =>');
      buffer.writeln('                    $searchConditions).toList();');
      buffer.writeln('                }');
    }

    // Apply sort
    if (hasSortable) {
      buffer.writeln('                if (_sortColumn != null) {');
      buffer.writeln(
          '                  filtered = List.from(filtered)..sort((a, b) {');
      buffer.writeln('                    return switch (_sortColumn) {');
      for (final field in sortableFields) {
        buffer.writeln(
            "                      '${field.name}' => a.${field.name}.toString().compareTo(b.${field.name}.toString()),");
      }
      buffer.writeln('                      _ => 0,');
      buffer.writeln('                    };');
      buffer.writeln('                  });');
      buffer.writeln('                }');
    }

    buffer.writeln('                return ListView.builder(');
    buffer.writeln('                  itemCount: filtered.length,');
    buffer.writeln('                  itemBuilder: (context, index) {');
    buffer.writeln(
        '                    final $entityLower = filtered[index];');
    buffer.writeln('                    return ListTile(');
    if (manifest.visibleFields.isNotEmpty) {
      buffer.writeln(
          '                      title: Text($entityLower.${manifest.firstLabelFieldName}.toString()),');
    }
    buffer.writeln(
        "                      onTap: () => context.push('$itemPath'),");
    buffer.writeln('                    );');
    buffer.writeln('                  },');
    buffer.writeln('                );');
    buffer.writeln('              },');
    buffer.writeln(
        '              loading: () => const Center(child: CircularProgressIndicator()),');
    buffer.writeln(
        "              error: (error, stackTrace) => Center(child: Text('Error: \$error')),");
    buffer.writeln('            ),');
    buffer.writeln('          ),');
    buffer.writeln('        ],');
    buffer.writeln('      ),');
    buffer.writeln('    );');
    buffer.writeln('  }');
    buffer.writeln('}');
  }
}
