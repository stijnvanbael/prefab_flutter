import '../core/artifact.dart';
import '../core/artifact_generator.dart';
import '../core/code.dart';
import '../core/entity_context.dart';
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
      : super('RoutesGenerator', const [RoutesArtifact.create]);
}

/// The `$<file>Routes` list of one source file (one artifact per library).
class RoutesArtifact extends Artifact {
  RoutesArtifact(this.entity);

  /// The first entity of the library.
  final EntityContext entity;

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
    return Code(buffer.toString().trim(), imports: {Libs.goRouter});
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
    // Map: parentEntityNameLower → child manifests
    final childrenByParent = <String, List<EntityManifest>>{};
    for (final m in manifests) {
      final parentName = m.parentEntityNameLower;
      // Children of a parent declared in another file cannot be nested inside
      // that file's route tree; they become top-level routes instead.
      if (parentName != null && m.parentInSameLibrary) {
        childrenByParent.putIfAbsent(parentName, () => []).add(m);
      }
    }

    buffer.writeln('List<RouteBase> get $getterName => [');
    for (final manifest in manifests) {
      if (!manifest.hasParent) {
        _writeEntityRoute(manifest, childrenByParent, buffer, level: 1);
      } else if (!manifest.parentInSameLibrary) {
        _writeNestedEntityRoute(
          manifest,
          childrenByParent: childrenByParent,
          buffer: buffer,
          level: 1,
          absolutePrefix: [
            for (final a in manifest.ancestors) '/${a.path}/:${a.routeParam}',
            '/',
          ].join(),
        );
      }
    }
    buffer.writeln('];');
  }

  // Writes a root-level entity route (no @Parent).
  void _writeEntityRoute(
    EntityManifest manifest,
    Map<String, List<EntityManifest>> childrenByParent,
    StringBuffer buffer, {
    required int level,
  }) {
    final entity = manifest.entityName;
    final entityLower = manifest.entityNameLower;
    final path = manifest.path;

    final children = childrenByParent[entityLower] ?? [];
    // When this entity is a parent of others, use a named id param to avoid
    // collisions with the nested :id params (GoRouter requires unique names).
    final idParam = children.isNotEmpty ? '${entityLower}Id' : 'id';

    final i = _i(level);

    buffer.writeln('${i}GoRoute(');
    buffer.writeln("$i  path: '/$path',");
    buffer.writeln(
        '$i  builder: (context, state) => const ${entity}ListScreen(),');
    buffer.writeln('$i  routes: [');

    // The create route (only with @Create) must precede ':id' so '/create' is
    // not parsed as an id.
    if (manifest.hasCreate) {
      buffer.writeln('$i    GoRoute(');
      buffer.writeln("$i      path: 'create',");
      buffer.writeln(
          '$i      builder: (context, state) => const ${entity}CreateScreen(),');
      buffer.writeln('$i    ),');
    }

    // Detail route
    buffer.writeln('$i    GoRoute(');
    buffer.writeln("$i      path: ':$idParam',");
    buffer.writeln(
        "        builder: (context, state) => ${entity}DetailScreen(id: ${manifest.parseId("state.pathParameters['$idParam']!")}),");

    final hasSubRoutes = manifest.hasUpdate || children.isNotEmpty;
    if (hasSubRoutes) {
      buffer.writeln('$i      routes: [');
      if (manifest.hasUpdate) {
        buffer.writeln('$i        GoRoute(');
        buffer.writeln("$i          path: 'edit',");
        buffer.writeln(
            "          builder: (context, state) => ${entity}EditScreen(id: ${manifest.parseId("state.pathParameters['$idParam']!")}),");
        buffer.writeln('$i        ),');
      }
      // Nested child entity routes
      for (final child in children) {
        _writeNestedEntityRoute(
          child,
          childrenByParent: childrenByParent,
          buffer: buffer,
          level: level + 4,
        );
      }
      buffer.writeln('$i      ],');
    }

    buffer.writeln('$i    ),');

    buffer.writeln('$i  ],');
    buffer.writeln('$i),');
  }

  // Writes a nested entity route (entity has @Parent).
  void _writeNestedEntityRoute(
    EntityManifest manifest, {
    required Map<String, List<EntityManifest>> childrenByParent,
    required StringBuffer buffer,
    required int level,
    String absolutePrefix = '',
  }) {
    final entity = manifest.entityName;
    final entityLower = manifest.entityNameLower;
    final path = '$absolutePrefix${manifest.path}';
    // Every ancestor id comes from the path parameters of the enclosing
    // routes (named after the ancestor, so they are unique per level).
    final ancestorArgs = manifest.ancestors
        .map((a) =>
            "${a.paramName}: ${a.parse("state.pathParameters['${a.routeParam}']!")}")
        .join(', ');

    final children = childrenByParent[entityLower] ?? [];
    final idParam = children.isNotEmpty ? '${entityLower}Id' : 'id';

    final i = _i(level);

    buffer.writeln('${i}GoRoute(');
    buffer.writeln("$i  path: '$path',");
    buffer.writeln(
        "$i  builder: (context, state) => ${entity}ListScreen($ancestorArgs),");
    buffer.writeln('$i  routes: [');

    // The create route (only with @Create) must precede ':id' so '/create' is
    // not parsed as an id.
    if (manifest.hasCreate) {
      buffer.writeln('$i    GoRoute(');
      buffer.writeln("$i      path: 'create',");
      buffer.writeln(
          "$i      builder: (context, state) => ${entity}CreateScreen($ancestorArgs),");
      buffer.writeln('$i    ),');
    }

    // Detail route
    buffer.writeln('$i    GoRoute(');
    buffer.writeln("$i      path: ':$idParam',");
    buffer.writeln(
        "        builder: (context, state) => ${entity}DetailScreen(id: ${manifest.parseId("state.pathParameters['$idParam']!")}, $ancestorArgs),");

    final hasSubRoutes = manifest.hasUpdate || children.isNotEmpty;
    if (hasSubRoutes) {
      buffer.writeln('$i      routes: [');
      if (manifest.hasUpdate) {
        buffer.writeln('$i        GoRoute(');
        buffer.writeln("$i          path: 'edit',");
        buffer.writeln(
            "          builder: (context, state) => ${entity}EditScreen(id: ${manifest.parseId("state.pathParameters['$idParam']!")}, $ancestorArgs),");
        buffer.writeln('$i        ),');
      }
      for (final child in children) {
        _writeNestedEntityRoute(
          child,
          childrenByParent: childrenByParent,
          buffer: buffer,
          level: level + 4,
        );
      }
      buffer.writeln('$i      ],');
    }

    buffer.writeln('$i    ),');

    buffer.writeln('$i  ],');
    buffer.writeln('$i),');
  }

  static String _i(int level) => '  ' * level;
}
