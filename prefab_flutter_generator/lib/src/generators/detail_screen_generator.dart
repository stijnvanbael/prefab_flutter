import '../core/artifact.dart';
import '../core/artifact_generator.dart';
import '../core/code.dart';
import '../core/entity_context.dart';
import '../core/extension_point.dart';
import '../core/family_key.dart';
import '../core/field_registries.dart';
import '../features/features.dart';
import '../manifest/entity_manifest.dart';
import '../manifest/entity_paths.dart';
import '../manifest/field_manifest.dart';

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
            features: registeredFeatures,
            kinds: {ArtifactKind.detailScreen});
}

/// The `{Entity}DetailScreen` widget of one entity.
class DetailScreenArtifact extends Artifact {
  DetailScreenArtifact(this.entity);

  final EntityContext entity;

  /// Widgets of the AppBar `actions` (indent 10). Orders in use: 10 update
  /// (Edit), 20 delete, 50 actions. Contribute with `addLazy` when the code
  /// uses [key].
  final appBarActions = ExtensionPoint('detailScreen.appBarActions');

  /// The `bottom:` argument of the app bar (indent 8). Single-valued.
  final appBarBottom = ExtensionPoint('detailScreen.appBarBottom',
      maxContributions: 1);

  /// The ids of the owning resources, outermost first (nested resources):
  /// constructor fields, the detail provider key and the list provider key
  /// of the delete action.
  final familyKey = ValuePoint<FamilyId>('detailScreen.familyKey');

  /// The ids of [familyKey] and the snippets built from them.
  FamilyKey get key => FamilyKey(familyKey.values);

  /// Name of the local variable holding the watched `AsyncValue` of the
  /// entity.
  String get asyncName => '${entity.manifest.entityNameLower}Async';

  /// How a field value is shown in its tile. Orders in use: 10 nullable
  /// fields.
  final fieldValue = ValuePoint<FieldValue>('detailScreen.fieldValue');

  /// Fields shown as tiles, in order. Orders in use: 10 views.
  final detailFields = ValuePoint<FieldManifest>('detailScreen.detailFields');

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
        ...appBarBottom.imports,
        ...appBarActions.imports,
        entity.sourceFileName,
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
    final key = FamilyKey(familyKey.values);
    final hasParent = !key.isEmpty;

    buffer.writeln('class ${entity}DetailScreen extends ConsumerWidget {');
    buffer.writeln('  final ${manifest.idType} id;');
    for (final a in key.ids) {
      buffer.writeln('  final ${a.type} ${a.name};');
    }
    buffer.writeln();
    if (hasParent) {
      buffer.writeln(
          '  const ${entity}DetailScreen({super.key, required this.id, ${key.requiredThis}});');
    } else {
      buffer.writeln(
          '  const ${entity}DetailScreen({super.key, required this.id});');
    }
    buffer.writeln();
    buffer.writeln('  @override');
    buffer.writeln('  Widget build(BuildContext context, WidgetRef ref) {');
    buffer.writeln(
        '    final ${entityLower}Async = ref.watch(${entityLower}DetailProvider(${key.detailExpr('id', (a) => a.name)}));');
    buffer.writeln('    return Scaffold(');
    buffer.writeln('      appBar: AppBar(');
    buffer.writeln("        title: const Text('${manifest.title}'),");
    if (!appBarBottom.isEmpty) buffer.writeln(appBarBottom.render(8));

    _writeAppBarActions(buffer);

    buffer.writeln('      ),');

    _writeBody(manifest, buffer);

    buffer.writeln('    );');
    buffer.writeln('  }');
    buffer.writeln('}');
  }

  // ---------------------------------------------------------------------------
  // AppBar actions
  // ---------------------------------------------------------------------------

  void _writeAppBarActions(StringBuffer buffer) {
    if (appBarActions.isEmpty) return;
    buffer.writeln('        actions: [');
    buffer.writeln(appBarActions.render(10));
    buffer.writeln('        ],');
  }

  // ---------------------------------------------------------------------------
  // Body
  // ---------------------------------------------------------------------------

  void _writeBody(EntityManifest manifest, StringBuffer buffer) {
    final entityLower = manifest.entityNameLower;
    final visibleFields = detailFields.values;

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
    final value = fieldValueWidget(fieldValue, field, entityLower);
    _imports.addAll(value.imports);
    buffer.writeln('              subtitle: ${value.text},');
    buffer.writeln('            ),');
  }
}
