import '../core/artifact.dart';
import '../core/artifact_generator.dart';
import '../core/code.dart';
import '../core/entity_context.dart';
import '../core/extension_point.dart';
import '../features/features.dart';
import '../manifest/entity_manifest.dart';

/// Generates GoRouter [GoRoute] declarations for every class annotated with
/// [@View] in a source library.
///
/// Entities nested with [@Parent] (to any depth) are emitted inside their
/// parent's detail route, each level with its own path parameter
/// (`:orderId`, `:orderLineId`, ...).
///
/// For each entity the following route tree is emitted:
/// ```
/// GoRoute(
///   path: '/{path}',
///   builder: … → {Entity}ListScreen,
///   routes: [
///     GoRoute(
///       path: ':id',
///       builder: … → {Entity}DetailScreen,
///       routes: [
///         GoRoute(path: 'edit', …)  // only when @Update is present
///       ],
///     ),
///     GoRoute(path: 'create', …)    // only when @Create is present
///   ],
/// )
/// ```
///
/// All entity routes from the same source file are collected into a single
/// top-level getter named after the source file (`product.dart` ->
/// `$productRoutes`, `user_account.dart` -> `$userAccountRoutes`) so they can
/// be registered with [GoRouter] in one place and several route files can be
/// imported side by side without name clashes:
///
/// ```dart
/// GoRouter(routes: $productRoutes)
/// ```
class RoutesGenerator extends ArtifactGenerator {
  RoutesGenerator()
      : super('RoutesGenerator', const [RoutesArtifact.create],
            features: registeredFeatures, kinds: {ArtifactKind.routes});
}

/// The `$<file>Routes` list of one source file (one artifact per library).
class RoutesArtifact extends Artifact {
  RoutesArtifact(this.entity);

  /// The first entity of the library.
  final EntityContext entity;

  /// Screens below the list route of an entity, before its detail route (one
  /// value per screen; the template places them by entity name). Orders in
  /// use: 10 create.
  final listChildRoutes = ValuePoint<ListChildRoute>('routes.listChildRoutes');

  /// Screens below the detail route of an entity (one value per screen; the
  /// template places them by entity name). Orders in use: 5 update (edit), 10
  /// entity screens.
  final detailChildRoutes =
      ValuePoint<DetailChildRoute>('routes.detailChildRoutes');

  /// Top-level routes of entities that have a `@Parent` (nested resources):
  /// without a contribution such an entity has no route of its own.
  final routes = ValuePoint<RouteSpec>('routes.routes');

  /// The routes nested in the detail route of a parent entity.
  final childRoutes =
      ValuePoint<List<RouteSpec> Function(EntityManifest parent)>(
          'routes.childRoutes');

  /// Extra arguments of the screens of an entity (`name: value` pairs, empty
  /// for none), e.g. the ancestor ids read from the path parameters.
  final screenArguments =
      ValuePoint<String Function(EntityManifest entity)>('routes.screenArguments');

  static Iterable<Artifact> create(EntityContext entity) =>
      entity.manifest == entity.libraryManifests.first
          ? [RoutesArtifact(entity)]
          : const [];

  @override
  ArtifactId get id =>
      ArtifactId(ArtifactKind.routes, entity.manifest.entityName);

  @override
  String get primaryName => routesGetterName(entity.sourceFileName);

  @override
  Code emit() {
    final buffer = StringBuffer();
    _writeRoutesList(entity.libraryManifests, primaryName, buffer);
    return Code(buffer.toString().trim(), imports: {
      Libs.goRouter,
      for (final r in detailChildRoutes.values)
        if (r.libraryUri.isNotEmpty) r.libraryUri,
    });
  }

  // ---------------------------------------------------------------------------
  // Routes getter
  // ---------------------------------------------------------------------------

  /// Derives the getter name from the source file name, e.g.
  /// `user_account.dart` -> `$userAccountRoutes`.
  static String routesGetterName(String sourceFileName) {
    final base = sourceFileName.replaceFirst(RegExp(r'\.dart$'), '');
    final parts = base
        .split(RegExp(r'[^A-Za-z0-9]+'))
        .where((p) => p.isNotEmpty)
        .toList();
    final camel = [
      for (var i = 0; i < parts.length; i++)
        i == 0 ? parts[i] : parts[i][0].toUpperCase() + parts[i].substring(1),
    ].join();
    final name = camel.isEmpty ? 'prefab' : camel;
    final safe = RegExp(r'^[0-9]').hasMatch(name) ? '_$name' : name;
    return '\$${safe}Routes';
  }

  void _writeRoutesList(
    List<EntityManifest> manifests,
    String getterName,
    StringBuffer buffer,
  ) {
    final extra = {for (final s in routes.values) s.manifest: s};
    buffer.writeln('List<RouteBase> get $getterName => [');
    for (final manifest in manifests) {
      // An entity without parent has a root route; any other gets a
      // top-level route only when a feature supplies one (`routes`).
      final spec = manifest.hasParent
          ? extra[manifest]
          : RouteSpec(manifest, path: '/${manifest.path}');
      if (spec != null) _writeEntityRoute(spec, buffer);
    }
    buffer.writeln('];');
  }

  /// Extra arguments of the screens of [manifest] (e.g. the ids of its
  /// ancestors), as `name: value` pairs separated by commas.
  String _screenArguments(EntityManifest manifest) => [
        for (final f in screenArguments.values) f(manifest),
      ].where((a) => a.isNotEmpty).join(', ');

  List<RouteSpec> _childRoutes(EntityManifest manifest) => [
        for (final f in childRoutes.values) ...f(manifest),
      ];

  // Writes the route tree of one entity: list, create, detail and edit, with
  // the routes of its children inside the detail route.
  void _writeEntityRoute(RouteSpec spec, StringBuffer buffer) {
    final manifest = spec.manifest;
    final entity = manifest.entityName;
    final args = _screenArguments(manifest);
    final constant = args.isEmpty ? 'const ' : '';
    String screenArgs(String id) =>
        [id, args].where((a) => a.isNotEmpty).join(', ');

    final children = _childRoutes(manifest);
    // When this entity is a parent of others, use a named id param to avoid
    // collisions with the nested :id params (GoRouter requires unique names).
    final idParam =
        children.isNotEmpty ? '${manifest.entityNameLower}Id' : 'id';
    final id = manifest.parseId("state.pathParameters['$idParam']!");

    buffer.writeln('GoRoute(');
    buffer.writeln("  path: '${spec.path}',");
    buffer.writeln(
        '  builder: (context, state) => $constant${entity}ListScreen($args),');
    buffer.writeln('  routes: [');

    // The create route (from the create feature) must precede ':id' so
    // '/create' is not parsed as an id.
    for (final r in listChildRoutes.values) {
      if (r.entityName != manifest.entityName) continue;
      buffer.writeln('GoRoute(');
      buffer.writeln("  path: '${r.path}',");
      buffer.writeln(
          '  builder: (context, state) => $constant${r.className}($args),');
      buffer.writeln('),');
    }

    // Detail route
    buffer.writeln('GoRoute(');
    buffer.writeln("  path: ':$idParam',");
    buffer.writeln(
        '  builder: (context, state) => ${entity}DetailScreen(${screenArgs('id: $id')}),');
    final screens = [
      for (final r in detailChildRoutes.values)
        if (r.entityName == manifest.entityName) r,
    ];
    if (children.isNotEmpty || screens.isNotEmpty) {
      buffer.writeln('  routes: [');
      for (final r in screens) {
        buffer.writeln('GoRoute(');
        buffer.writeln("  path: '${r.path}',");
        buffer.writeln(
            '  builder: (context, state) => ${r.className}(${screenArgs('id: $id')}),');
        buffer.writeln('),');
      }
      for (final child in children) {
        _writeEntityRoute(child, buffer);
      }
      buffer.writeln('  ],');
    }
    buffer.writeln('),');

    buffer.writeln('  ],');
    buffer.writeln('),');
  }
}

/// A route tree of one entity: [path] is the `GoRoute.path` of its list route
/// (absolute for a top-level route, relative inside its parent's detail
/// route).
class RouteSpec {
  const RouteSpec(this.manifest, {required this.path});

  final EntityManifest manifest;
  final String path;
}

/// A screen below the list route of an entity, before its detail route
/// (e.g. the create screen). It gets the extra screen arguments of the entity.
class ListChildRoute {
  const ListChildRoute(
      {required this.entityName, required this.path, required this.className});

  final String entityName;
  final String path;
  final String className;
}

/// A screen below the detail route of an entity (the edit screen, a
/// hand-written `@EntityScreen`); it gets `id` and the extra screen arguments.
class DetailChildRoute {
  const DetailChildRoute(
      {required this.entityName,
      required this.path,
      required this.className,
      required this.libraryUri});

  final String entityName;
  final String path;
  final String className;

  /// Library the generated routes import to reach [className]; empty when the
  /// screen is generated into the same library.
  final String libraryUri;
}
