import 'package:source_gen/source_gen.dart';

import '../../core/artifact.dart';
import '../../core/code.dart';
import '../../core/entity_context.dart';
import '../../core/feature.dart';
import '../../core/library_emitter.dart';
import '../../generators/detail_screen_generator.dart';
import '../../generators/list_screen_generator.dart';
import '../../generators/routes_generator.dart';
import '../../manifest/entity_manifest.dart';
import '../actions/action_rendering.dart';
import '../breadcrumbs/breadcrumb_items.dart';
import 'child_screen.dart';

/// Hand-written screens below an entity (`@EntityScreen`).
///
/// Adds the route of every screen under the entity's detail route (routes
/// point `detailChildRoutes`, order 10), a link tile on the detail screen
/// (`afterFields`, order 10), a menu entry per screen on each list item
/// (`itemActions`, order 40, before the `@EntityAction`s at 50, rendered like
/// them by `action_rendering.dart`) and the `{entity}Breadcrumbs` helper artifact.
/// The constructor of each screen is checked against the ids the route passes.
class EntityScreensFeature extends Feature {
  const EntityScreensFeature();

  static const _name = 'entity_screens';

  @override
  String get name => _name;

  @override
  List<ArtifactFactory> get artifacts => const [BreadcrumbsArtifact.create];

  @override
  void contribute(EntityContext entity, ArtifactSet artifacts) {
    if (entity.childScreens.isEmpty) return;
    final manifest = entity.manifest;
    _check(entity);

    final routes = artifacts.get<RoutesArtifact>(
        ArtifactKind.routes, entity.libraryManifests.first.entityName);
    final detail = artifacts.get<DetailScreenArtifact>(
        ArtifactKind.detailScreen, manifest.entityName);
    final list = artifacts.get<ListScreenArtifact>(
        ArtifactKind.listScreen, manifest.entityName);
    final classes = [for (final s in entity.childScreens) s.className];
    for (final kind in [ArtifactKind.detailScreen, ArtifactKind.listScreen]) {
      final promoted = artifacts.promotedName(kind, manifest.entityName);
      if (promoted == null) continue;
      artifacts.warn('$promoted is @Promoted, so it does not link to '
          '${classes.join(', ')} (@EntityScreen on ${manifest.entityName}). '
          'Add the link to $promoted by hand.');
    }
    for (final screen in entity.childScreens) {
      // The screen's own library is imported by the generated routes, unless
      // it is the entity's file (which every artifact imports already).
      final sameFile = screen.libraryUri.endsWith('/${entity.sourceFileName}');
      routes?.detailChildRoutes.add(
        _name,
        DetailChildRoute(
          entityName: manifest.entityName,
          path: screen.path,
          className: screen.className,
          libraryUri: sameFile ? entity.sourceFileName : screen.libraryUri,
        ),
        order: 10,
      );
      detail?.afterFields.add(
        _name,
        Code(
          '''
ListTile(
  title: const Text('${escapeDartString(screen.title)}'),
  trailing: const Icon(Icons.chevron_right),
  onTap: () => context.push('${entity.paths.itemPath(manifest, r'$id')}/${screen.path}'),
),''',
          imports: {Libs.materialUi, Libs.goRouter},
        ),
        order: 10,
      );
    }
    if (list != null) {
      final itemId = '\${${list.itemName}.${manifest.idFieldName}}';
      final base = entity.paths.itemPath(manifest, itemId);
      final items = sortActions([
        for (final s in entity.childScreens)
          ActionItem(
            label: s.title,
            call: "context.push('$base/${s.path}')",
            order: _itemOrder,
            name: s.path,
          ),
      ]);
      list.itemActions.add(
        _name,
        Code(renderMenuEntries(items), imports: {Libs.goRouter}),
        order: _itemOrder,
      );
    }
  }

  /// Order of the item menu entries; the `@EntityAction`s follow at 50.
  static const _itemOrder = 40;

  /// Fails the build, naming the screen, when its path or constructor does
  /// not fit the route.
  void _check(EntityContext entity) {
    final manifest = entity.manifest;
    final reserved = {
      'edit',
      for (final m in entity.libraryManifests)
        if (m.parentEntityName == manifest.entityName) m.path,
    };
    final seen = <String>{};
    for (final screen in entity.childScreens) {
      final where = '@EntityScreen ${screen.className} (${screen.libraryUri})';
      if (!RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(screen.path)) {
        throw InvalidGenerationSourceError(
            "$where: path '${screen.path}' must be one route segment of "
            'letters, digits, - and _.');
      }
      if (reserved.contains(screen.path)) {
        throw InvalidGenerationSourceError(
            "$where: path '${screen.path}' is already used below "
            '${manifest.entityName}.');
      }
      if (!seen.add(screen.path)) {
        throw InvalidGenerationSourceError(
            "$where: another screen already uses the path '${screen.path}' "
            'below ${manifest.entityName}.');
      }
      final problems = constructorProblems(manifest, screen);
      if (problems.isNotEmpty) {
        throw InvalidGenerationSourceError(
            '$where does not match the route of ${manifest.entityName}: '
            '${problems.join('; ')}. Its unnamed constructor must take '
            '${expectedParams(manifest)} as named parameters and no other '
            'required parameter.');
      }
    }
  }

  /// The ids the route passes: `int id, String orderId`.
  static String expectedParams(EntityManifest manifest) => [
        '${manifest.idType} id',
        for (final a in manifest.ancestors) '${a.idType} ${a.paramName}',
      ].map((p) => '`$p`').join(', ');

  /// What is wrong with the constructor of [screen]; empty when it fits.
  static List<String> constructorProblems(
      EntityManifest manifest, ChildScreen screen) {
    final expected = {
      'id': manifest.idType,
      for (final a in manifest.ancestors) a.paramName: a.idType,
    };
    final problems = <String>[];
    final byName = {for (final p in screen.params) p.name: p};
    for (final MapEntry(key: name, value: type) in expected.entries) {
      final p = byName[name];
      if (p == null) {
        problems.add('there is no parameter `$name`');
      } else if (!p.named) {
        problems.add('`$name` must be a named parameter');
      } else if (p.type != null && p.type!.replaceAll(' ', '') != type) {
        problems.add('`$name` has type ${p.type}, expected $type');
      }
    }
    for (final p in screen.params) {
      if (!expected.containsKey(p.name) && p.required) {
        problems.add('`${p.name}` is required but the route cannot pass it');
      }
    }
    return problems;
  }
}

/// `{entity}Breadcrumbs`: builds the breadcrumb bar of a hand-written screen
/// below an entity (ancestors, the entity, the screen's title), like the bar
/// of the generated screens. Generated for every entity that has an
/// `@EntityScreen`.
class BreadcrumbsArtifact extends Artifact {
  BreadcrumbsArtifact(this.entity);

  final EntityContext entity;

  static Iterable<Artifact> create(EntityContext entity) =>
      entity.childScreens.isEmpty ? const [] : [BreadcrumbsArtifact(entity)];

  @override
  ArtifactId get id =>
      ArtifactId(ArtifactKind.breadcrumbs, entity.manifest.entityName);

  @override
  String get primaryName => '${entity.manifest.entityNameLower}Breadcrumbs';

  @override
  Code emit() {
    final m = entity.manifest;
    final label = m.visibleFields
        .where((f) => f.name == m.firstLabelFieldName)
        .firstOrNull;
    final access = label?.isNullable == true
        ? '?.${m.firstLabelFieldName}?.toString()'
        : '?.${m.firstLabelFieldName}.toString()';
    final key = m.detailKeyExpr('id', (a) => a.paramName);
    final params = [
      'required String title',
      'required ${m.idType} id',
      for (final a in m.ancestors) 'required ${a.idType} ${a.paramName}',
    ].join(', ');
    final text = '''
/// The breadcrumb bar for hand-written screens of ${m.entityName}: its
/// ancestors, the ${m.entityName} and [title]. Use it as `AppBar.bottom`.
PrefabBreadcrumbBar $primaryName(BuildContext context, WidgetRef ref, {$params}) {
  return PrefabBreadcrumbBar(
    items: [
${ancestorBreadcrumbItems(m).join('\n')}
      PrefabBreadcrumb(
        label: ref.watch(${m.entityNameLower}DetailProvider($key)).valueOrNull$access ?? '…',
        onTap: () => context.go('${entity.paths.itemPath(m, r'$id')}'),
      ),
      PrefabBreadcrumb(label: title),
    ],
  );
}''';
    return Code(text, imports: {
      Libs.materialUi,
      Libs.riverpod,
      Libs.goRouter,
      Libs.widgets,
      ...ancestorImports([m]),
      for (final a in m.ancestors)
        if (!a.inSameLibrary)
          a.libraryUri.replaceFirst(RegExp(r'\.dart$'), '.prefab.dart'),
    });
  }
}
