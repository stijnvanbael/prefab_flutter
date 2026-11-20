import '../core/artifact.dart';
import '../core/artifact_generator.dart';
import '../core/code.dart';
import '../core/entity_context.dart';
import '../core/extension_point.dart';
import '../core/field_registries.dart';
import '../features/features.dart';
import '../manifest/entity_manifest.dart';
import '../manifest/entity_paths.dart';
import '../manifest/field_manifest.dart';
import 'breadcrumbs.dart';

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
class DetailScreenGenerator extends ArtifactGenerator {
  DetailScreenGenerator()
      : super('DetailScreenGenerator', const [DetailScreenArtifact.create],
            features: registeredFeatures);
}

/// The `{Entity}DetailScreen` widget of one entity.
class DetailScreenArtifact extends Artifact {
  DetailScreenArtifact(this.entity);

  final EntityContext entity;

  /// Widgets appended to the AppBar `actions`, after Edit and Delete
  /// (indent 10). Orders in use: 50 actions.
  final appBarActions = ExtensionPoint('detailScreen.appBarActions');

  /// Name of the local variable holding the watched `AsyncValue` of the
  /// entity.
  String get asyncName => '${entity.manifest.entityNameLower}Async';

  /// How a field value is shown in its tile. Orders in use: 10 nullable
  /// fields.
  final fieldValue = ValuePoint<FieldValue>('detailScreen.fieldValue');

  /// Tiles after the field tiles (indent 12): links to hand-written child
  /// screens. Orders in use: 10 entity screens.
  final afterFields = ExtensionPoint('detailScreen.afterFields');

  static Iterable<Artifact> create(EntityContext entity) =>
      [DetailScreenArtifact(entity)];

  /// The libraries the fragments written so far need.
  final _imports = <String>{Libs.materialUi, Libs.riverpod};

  @override
  ArtifactId get id =>
      ArtifactId(ArtifactKind.detailScreen, entity.manifest.entityName);

  @override
  String get primaryName => '${entity.manifest.entityName}DetailScreen';

  @override
  Code emit() {
    final buffer = StringBuffer();
    _writeDetailScreenClass(entity.manifest, entity.paths, buffer);
    return Code(
      buffer.toString().trim(),
      imports: {
        ..._imports,
        ...appBarActions.imports,
        entity.sourceFileName,
        ...ancestorImports([entity.manifest]),
        ...afterFields.imports,
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Detail screen class
  // ---------------------------------------------------------------------------

  void _writeDetailScreenClass(
      EntityManifest manifest, EntityPaths paths, StringBuffer buffer) {
    final entity = manifest.entityName;
    final entityLower = manifest.entityNameLower;
    final hasParent = manifest.hasParent;

    buffer.writeln('class ${entity}DetailScreen extends ConsumerWidget {');
    buffer.writeln('  final ${manifest.idType} id;');
    if (hasParent) {
      for (final a in manifest.ancestors) {
        buffer.writeln('  final ${a.idType} ${a.paramName};');
      }
    }
    buffer.writeln();
    if (hasParent) {
      buffer.writeln(
          '  const ${entity}DetailScreen({super.key, required this.id, ${manifest.ancestors.map((a) => 'required this.${a.paramName}').join(', ')}});');
    } else {
      buffer.writeln(
          '  const ${entity}DetailScreen({super.key, required this.id});');
    }
    buffer.writeln();
    buffer.writeln('  @override');
    buffer.writeln('  Widget build(BuildContext context, WidgetRef ref) {');
    if (hasParent) {
      buffer.writeln(
          '    final ${entityLower}Async = ref.watch(${entityLower}DetailProvider(${manifest.detailKeyExpr('id', (a) => a.paramName)}));');
    } else {
      buffer.writeln(
          '    final ${entityLower}Async = ref.watch(${entityLower}DetailProvider(id));');
    }
    buffer.writeln('    return Scaffold(');
    buffer.writeln('      appBar: AppBar(');
    buffer.writeln("        title: const Text('${manifest.title}'),");
    if (manifest.hasBreadcrumbs) {
      _imports.addAll({Libs.goRouter, Libs.widgets});
      buffer.writeln(breadcrumbBottom(manifest, '        '));
    }

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
    if (!manifest.hasUpdate && !manifest.hasDelete && appBarActions.isEmpty) {
      return;
    }

    final entityLower = manifest.entityNameLower;
    final listProviderArg = manifest.hasParent
        ? '(${manifest.parentKeyExpr((a) => a.paramName)})'
        : '';

    buffer.writeln('        actions: [');

    if (manifest.hasUpdate) {
      _imports.add(Libs.goRouter);
      buffer.writeln('          IconButton(');
      buffer.writeln('            icon: const Icon(Icons.edit),');
      buffer.writeln("            tooltip: 'Edit',");
      buffer.writeln(
          "            onPressed: () => context.push('${paths.editPath(manifest, r'$id')}'),");
      buffer.writeln('          ),');
    }

    if (manifest.hasDelete) {
      _imports.addAll({Libs.goRouter, Libs.widgets});
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

    if (!appBarActions.isEmpty) buffer.writeln(appBarActions.render(10));

    buffer.writeln('        ],');
  }

  // ---------------------------------------------------------------------------
  // Body
  // ---------------------------------------------------------------------------

  void _writeBody(EntityManifest manifest, StringBuffer buffer) {
    final entityLower = manifest.entityNameLower;
    final detailFields = manifest.fieldsForView('detail');
    final visibleFields =
        detailFields.isEmpty ? manifest.visibleFields : detailFields;

    buffer.writeln('      body: ${entityLower}Async.when(');
    buffer.writeln('        data: ($entityLower) => ListView(');
    buffer.writeln('          padding: const EdgeInsets.all(16),');
    buffer.writeln('          children: [');

    for (final field in visibleFields) {
      _writeFieldTile(field, entityLower, buffer);
    }
    if (!afterFields.isEmpty) buffer.writeln(afterFields.render(12));

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
    final value = fieldValueText(fieldValue, field, entityLower);
    buffer.writeln('              subtitle: Text($value),');
    buffer.writeln('            ),');
  }
}
