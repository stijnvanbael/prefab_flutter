import '../core/artifact.dart';
import '../core/artifact_generator.dart';
import '../core/code.dart';
import '../core/entity_context.dart';
import '../core/extension_point.dart';
import '../core/field_registries.dart';
import '../manifest/entity_manifest.dart';
import '../manifest/entity_paths.dart';
import '../features/features.dart';
import 'breadcrumbs.dart';

/// Generates a `{Entity}ListScreen` [ConsumerWidget] for every class annotated
/// with [@View].
///
/// When the entity carries a [@Parent]-annotated field the generated list
/// screen:
/// - accepts the parent ID as a required constructor parameter (the value is
///   provided by the router via [state.pathParameters]),
/// - passes the parent ID to the Riverpod list provider so the provider can
///   scope its API call to the correct parent resource.
class ListScreenGenerator extends ArtifactGenerator {
  ListScreenGenerator()
      : super('ListScreenGenerator', const [ListScreenArtifact.create],
            features: registeredFeatures);
}

/// The `{Entity}ListScreen` widget of one entity.
class ListScreenArtifact extends Artifact {
  ListScreenArtifact(this.entity);

  final EntityContext entity;

  /// Statements at the start of `build`, after the list is watched (indent 4).
  final buildStatements = ExtensionPoint('listScreen.buildStatements');

  /// Widgets of the app bar `actions` (indent 10). Orders in use: 10 sort.
  final appBarActions = ExtensionPoint('listScreen.appBarActions');

  /// Widgets in the body column above the list (indent 10). Orders: 10 search.
  final aboveList = ExtensionPoint('listScreen.aboveList');

  /// Widgets in the body column below the list (indent 10). Orders: 10 paging.
  final belowList = ExtensionPoint('listScreen.belowList');

  /// Dart expression reading the list provider, e.g. `postsProvider(postId)`.
  String get providerRef {
    final m = entity.manifest;
    return m.hasParent
        ? '${m.entityNameLower}sProvider(${m.parentKeyExpr((a) => a.paramName)})'
        : '${m.entityNameLower}sProvider';
  }

  /// Name of the local variable holding the watched `AsyncValue` of the page.
  String get asyncName => '${entity.manifest.entityNameLower}sAsync';

  static Iterable<Artifact> create(EntityContext entity) =>
      [ListScreenArtifact(entity)];

  @override
  ArtifactId get id =>
      ArtifactId(ArtifactKind.listScreen, entity.manifest.entityName);

  @override
  String get primaryName => '${entity.manifest.entityName}ListScreen';

  @override
  Code emit() {
    final buffer = StringBuffer();
    _writeListScreenClass(entity.manifest, entity.paths, buffer);
    return Code(
      buffer.toString().trim(),
      imports: {
        ...buildStatements.imports,
        ...appBarActions.imports,
        ...aboveList.imports,
        ...belowList.imports,
        Libs.materialUi,
        Libs.riverpod,
        Libs.goRouter,
        Libs.widgets,
        entity.sourceFileName,
        ...ancestorImports([entity.manifest]),
      },
    );
  }

  // ---------------------------------------------------------------------------
  // List screen class
  // ---------------------------------------------------------------------------

  void _writeListScreenClass(
    EntityManifest manifest,
    EntityPaths paths,
    StringBuffer buffer,
  ) {
    final entity = manifest.entityName;
    final entityLower = manifest.entityNameLower;
    final hasParent = manifest.hasParent;
    final parentKey =
        hasParent ? manifest.parentKeyExpr((a) => a.paramName) : '';

    final itemPath =
        paths.itemPath(manifest, '\${$entityLower.${manifest.idFieldName}}');

    final createPath = paths.createPath(manifest);
    final providerRef = hasParent
        ? '${entityLower}sProvider($parentKey)'
        : '${entityLower}sProvider';

    buffer.writeln('class ${entity}ListScreen extends ConsumerWidget {');
    if (hasParent) {
      for (final a in manifest.ancestors) {
        buffer.writeln('  final ${a.idType} ${a.paramName};');
      }
      buffer.writeln();
      buffer.writeln(
          '  const ${entity}ListScreen({super.key, ${manifest.ancestors.map((a) => 'required this.${a.paramName}').join(', ')}});');
    } else {
      buffer.writeln('  const ${entity}ListScreen({super.key});');
    }
    buffer.writeln();
    buffer.writeln('  @override');
    buffer.writeln('  Widget build(BuildContext context, WidgetRef ref) {');

    // Watch the correct provider variant.
    if (hasParent) {
      buffer.writeln(
          '    final ${entityLower}sAsync = ref.watch(${entityLower}sProvider($parentKey));');
    } else {
      buffer.writeln(
          '    final ${entityLower}sAsync = ref.watch(${entityLower}sProvider);');
    }

    if (!buildStatements.isEmpty) buffer.writeln(buildStatements.render(4));
    buffer.writeln('    return Scaffold(');
    buffer.writeln('      appBar: AppBar(');
    buffer.writeln("        title: const Text('${manifest.title}'),");
    if (manifest.hasBreadcrumbs) {
      buffer.writeln(breadcrumbBottom(manifest, '        '));
    }
    if (!appBarActions.isEmpty) {
      buffer.writeln('        actions: [');
      buffer.writeln(appBarActions.render(10));
      buffer.writeln('        ],');
    }
    buffer.writeln('      ),');
    if (manifest.hasCreate) {
      buffer.writeln('      floatingActionButton: FloatingActionButton(');
      buffer.writeln("        tooltip: 'Create ${manifest.title}',");
      buffer.writeln('        onPressed: () async {');
      buffer.writeln("          await context.push('$createPath');");
      buffer.writeln('          ref.invalidate($providerRef);');
      buffer.writeln('        },');
      buffer.writeln('        child: const Icon(Icons.add),');
      buffer.writeln('      ),');
    }
    buffer.writeln('      body: Column(');
    buffer.writeln('        children: [');
    if (!aboveList.isEmpty) buffer.writeln(aboveList.render(10));
    buffer.writeln('          Expanded(');
    buffer.writeln('            child: ${entityLower}sAsync.when(');
    buffer.writeln('        skipLoadingOnReload: true,');
    buffer.writeln('        data: (page) => page.items.isEmpty');
    buffer.writeln("            ? const Center(child: Text('No items found'))");
    buffer.writeln('            : ListView.builder(');
    buffer.writeln('          itemCount: page.items.length,');
    buffer.writeln('          itemBuilder: (context, index) {');
    buffer.writeln('            final $entityLower = page.items[index];');
    buffer.writeln('            return ListTile(');
    // Without any declared views only the first field is shown (title).
    final slots = manifest.hasViews
        ? manifest.fieldsForView('list').take(3).toList()
        : manifest.visibleFields.take(1).toList();
    const slotNames = ['title', 'subtitle', 'trailing'];
    for (var i = 0; i < slots.length; i++) {
      final f = slots[i];
      final value = fieldDisplays.resolve(f).text(f, entityLower);
      buffer.writeln('              ${slotNames[i]}: Text($value),');
    }
    buffer.writeln("              onTap: () => context.push('$itemPath'),");
    buffer.writeln('            );');
    buffer.writeln('          },');
    buffer.writeln('        ),');
    buffer.writeln(
        '        loading: () => const Center(child: CircularProgressIndicator()),');
    buffer.writeln(
        "        error: (error, stackTrace) => Center(child: Text('Error: \$error')),");
    buffer.writeln('            ),');
    buffer.writeln('          ),');
    if (!belowList.isEmpty) buffer.writeln(belowList.render(10));
    buffer.writeln('        ],');
    buffer.writeln('      ),');
    buffer.writeln('    );');
    buffer.writeln('  }');
    buffer.writeln('}');
  }
}
