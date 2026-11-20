import '../core/artifact.dart';
import '../core/artifact_generator.dart';
import '../core/code.dart';
import '../core/entity_context.dart';
import '../core/extension_point.dart';
import '../core/family_key.dart';
import '../core/field_registries.dart';
import '../manifest/entity_manifest.dart';
import '../manifest/entity_paths.dart';
import '../manifest/field_manifest.dart';
import '../features/features.dart';

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
            features: registeredFeatures,
            kinds: {ArtifactKind.listScreen});
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

  /// Entries of the trailing menu of every list item (indent 14): expressions
  /// of type `PopupMenuEntry<void>` separated by commas, written with the
  /// item in the local variable named [itemName]. Orders in use: 50 actions.
  final itemActions = ExtensionPoint('listScreen.itemActions');

  /// Fields shown in the list tile slots, in the order title, subtitle,
  /// trailing (at most three are used). Orders in use: 10 views.
  final itemTile = ValuePoint<FieldManifest>('listScreen.itemTile');

  /// Name of the local variable holding the list item in `itemBuilder`.
  String get itemName => entity.manifest.entityNameLower;

  /// How a field value is shown in a list tile. Orders in use: 10 nullable
  /// fields.
  final fieldValue = ValuePoint<FieldValue>('listScreen.fieldValue');

  /// The `floatingActionButton` of the scaffold (indent 6): one widget
  /// expression ending in a comma. Orders in use: 10 create.
  final floatingActionButton =
      ExtensionPoint('listScreen.floatingActionButton', maxContributions: 1);

  /// The `bottom:` argument of the app bar (indent 8). Single-valued.
  final appBarBottom = ExtensionPoint('listScreen.appBarBottom',
      maxContributions: 1);

  /// The ids of the owning resources, outermost first (nested resources):
  /// constructor fields and the key of the list provider.
  final familyKey = ValuePoint<FamilyId>('listScreen.familyKey');

  /// Placeholder for the expression reading the list provider (e.g.
  /// `postsProvider(postId)`), for fragments written before every feature
  /// has contributed; replaced when the screen is emitted.
  static const providerRef = '{{providerRef}}';

  String get _providerRef {
    final m = entity.manifest;
    final key = FamilyKey(familyKey.values);
    return key.isEmpty
        ? '${m.entityNameLower}sProvider'
        : '${m.entityNameLower}sProvider(${key.listExpr((a) => a.name)})';
  }

  /// Libraries of the custom display widgets written so far (PF-65).
  final _displayImports = <String>{};

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
        ...appBarBottom.imports,
        ...appBarActions.imports,
        ...aboveList.imports,
        ...belowList.imports,
        ...itemActions.imports,
        ...floatingActionButton.imports,
        ..._displayImports,
        Libs.materialUi,
        Libs.riverpod,
        Libs.goRouter,
        Libs.widgets,
        entity.sourceFileName,
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
    final key = FamilyKey(familyKey.values);
    final hasParent = !key.isEmpty;

    final itemPath =
        paths.itemPath(manifest, '\${$entityLower.${manifest.idFieldName}}');

    final providerRef = _providerRef;

    buffer.writeln('class ${entity}ListScreen extends ConsumerWidget {');
    if (hasParent) {
      for (final a in key.ids) {
        buffer.writeln('  final ${a.type} ${a.name};');
      }
      buffer.writeln();
      buffer.writeln(
          '  const ${entity}ListScreen({super.key, ${key.requiredThis}});');
    } else {
      buffer.writeln('  const ${entity}ListScreen({super.key});');
    }
    buffer.writeln();
    buffer.writeln('  @override');
    buffer.writeln('  Widget build(BuildContext context, WidgetRef ref) {');

    // Watch the correct provider variant.
    buffer.writeln(
        '    final ${entityLower}sAsync = ref.watch($providerRef);');

    if (!buildStatements.isEmpty) {
      buffer.writeln(buildStatements
          .render(4)
          .replaceAll(ListScreenArtifact.providerRef, providerRef));
    }
    buffer.writeln('    final prefabTheme = PrefabTheme.of(context);');
    buffer.writeln('    return Scaffold(');
    buffer.writeln('      appBar: AppBar(');
    buffer.writeln("        title: const Text('${manifest.title}'),");
    if (!appBarBottom.isEmpty) buffer.writeln(appBarBottom.render(8));
    if (!appBarActions.isEmpty) {
      buffer.writeln('        actions: [');
      buffer.writeln(appBarActions.render(10));
      buffer.writeln('        ],');
    }
    buffer.writeln('      ),');
    if (!floatingActionButton.isEmpty) {
      buffer.write('      floatingActionButton: ');
      buffer.writeln(floatingActionButton
          .render(6)
          .trimLeft()
          .replaceAll(ListScreenArtifact.providerRef, providerRef));
    }
    buffer.writeln('      body: Column(');
    buffer.writeln('        children: [');
    if (!aboveList.isEmpty) buffer.writeln(aboveList.render(10));
    buffer.writeln('          Expanded(');
    buffer.writeln('            child: ${entityLower}sAsync.when(');
    buffer.writeln('        skipLoadingOnReload: true,');
    buffer.writeln('        data: (page) => page.items.isEmpty');
    buffer.writeln("            ? prefabTheme.emptyBuilder(context)");
    buffer.writeln('            : ListView.builder(');
    buffer.writeln('          padding: prefabTheme.listPadding,');
    buffer.writeln('          itemCount: page.items.length,');
    buffer.writeln('          itemBuilder: (context, index) {');
    buffer.writeln('            final $entityLower = page.items[index];');
    buffer.writeln('            return ListTile(');
    final slots = itemTile.values;
    const slotNames = ['title', 'subtitle', 'trailing'];
    for (var i = 0; i < slots.length; i++) {
      final f = slots[i];
      final value = fieldValueWidget(fieldValue, f, entityLower);
      _displayImports.addAll(value.imports);
      if (slotNames[i] == 'trailing' && !itemActions.isEmpty) continue;
      buffer.writeln('              ${slotNames[i]}: ${value.text},');
    }
    if (!itemActions.isEmpty) {
      final trailing = slots.length > 2
          ? fieldValueWidget(fieldValue, slots[2], entityLower).text
          : null;
      buffer.writeln('              trailing: Row(');
      buffer.writeln('                mainAxisSize: MainAxisSize.min,');
      buffer.writeln('                children: [');
      if (trailing != null) buffer.writeln('                  $trailing,');
      buffer.writeln('                  PopupMenuButton<void>(');
      buffer.writeln('                    itemBuilder: (_) => [');
      buffer.writeln(itemActions.render(14));
      buffer.writeln('                    ],');
      buffer.writeln('                  ),');
      buffer.writeln('                ],');
      buffer.writeln('              ),');
    }
    buffer.writeln("              onTap: () => context.push('$itemPath'),");
    buffer.writeln('            );');
    buffer.writeln('          },');
    buffer.writeln('        ),');
    buffer.writeln(
        '        loading: () => prefabTheme.loadingBuilder(context),');
    buffer.writeln(
        '        error: (error, stackTrace) =>\n'
        '            prefabTheme.errorBuilder(context, error, stackTrace),');
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
