import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:prefab_flutter/prefab_flutter.dart';
import 'package:source_gen/source_gen.dart';

import '../manifest/entity_manifest.dart';

const _viewChecker = TypeChecker.fromRuntime(View);

/// Generates GoRouter [GoRoute] declarations for every class annotated with
/// [@View] in a source library.
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
///     GoRoute(path: 'create', …)    // only when @Update is present
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
class RoutesGenerator extends Generator {
  @override
  String generate(LibraryReader library, BuildStep buildStep) {
    final annotated = library.annotatedWith(_viewChecker).toList();
    if (annotated.isEmpty) return '';

    final manifests = <EntityManifest>[];
    for (final a in annotated) {
      final element = a.element;
      if (element is! ClassElement) {
        throw InvalidGenerationSourceError(
          '@View can only be applied to classes.',
          element: element,
        );
      }
      manifests.add(EntityManifest.from(element, a.annotation));
    }

    final sourceFileName = buildStep.inputId.path.split('/').last;
    final buffer = StringBuffer();

    _writeHeader(buffer);
    _writeImports(manifests, sourceFileName, buffer);
    buffer.writeln();
    _writeRoutesList(manifests, routesGetterName(sourceFileName), buffer);

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
    buffer.writeln('// RoutesGenerator');
    buffer.writeln(sep);
    buffer.writeln();
  }

  // ---------------------------------------------------------------------------
  // Imports
  // ---------------------------------------------------------------------------

  void _writeImports(
    List<EntityManifest> manifests,
    String sourceFileName,
    StringBuffer buffer,
  ) {
    buffer.writeln("import 'package:go_router/go_router.dart';");
    buffer.writeln();

    final base = sourceFileName.replaceFirst(RegExp(r'\.dart$'), '');
    buffer.writeln("import '$base.detail_screen.dart';");
    buffer.writeln("import '$base.list_screen.dart';");
    if (manifests.any((m) => m.hasUpdate)) {
      buffer.writeln("import '$base.form_screen.dart';");
    }
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
          parentIdParam: manifest.parentParamName!,
          childrenByParent: childrenByParent,
          buffer: buffer,
          level: 1,
          absolutePrefix: '/${manifest.parentPath}/:${manifest.parentParamName}/',
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
          parentIdParam: idParam,
          childrenByParent: childrenByParent,
          buffer: buffer,
          level: level + 4,
        );
      }
      buffer.writeln('$i      ],');
    }

    buffer.writeln('$i    ),');

    // Create route (only when @Update is present)
    if (manifest.hasUpdate) {
      buffer.writeln('$i    GoRoute(');
      buffer.writeln("$i      path: 'create',");
      buffer.writeln(
          '$i      builder: (context, state) => const ${entity}CreateScreen(),');
      buffer.writeln('$i    ),');
    }

    buffer.writeln('$i  ],');
    buffer.writeln('$i),');
  }

  // Writes a nested entity route (entity has @Parent).
  void _writeNestedEntityRoute(
    EntityManifest manifest, {
    required String parentIdParam,
    required Map<String, List<EntityManifest>> childrenByParent,
    required StringBuffer buffer,
    required int level,
    String absolutePrefix = '',
  }) {
    final entity = manifest.entityName;
    final entityLower = manifest.entityNameLower;
    final path = '$absolutePrefix${manifest.path}';
    final parentParamName = manifest.parentParamName!;

    final children = childrenByParent[entityLower] ?? [];
    final idParam = children.isNotEmpty ? '${entityLower}Id' : 'id';

    final i = _i(level);

    buffer.writeln('${i}GoRoute(');
    buffer.writeln("$i  path: '$path',");
    buffer.writeln(
        "$i  builder: (context, state) => ${entity}ListScreen($parentParamName: ${manifest.parseParentId("state.pathParameters['$parentIdParam']!")}),");
    buffer.writeln('$i  routes: [');

    // Detail route
    buffer.writeln('$i    GoRoute(');
    buffer.writeln("$i      path: ':$idParam',");
    buffer.writeln(
        "        builder: (context, state) => ${entity}DetailScreen(id: ${manifest.parseId("state.pathParameters['$idParam']!")}, $parentParamName: ${manifest.parseParentId("state.pathParameters['$parentIdParam']!")}),");

    final hasSubRoutes = manifest.hasUpdate || children.isNotEmpty;
    if (hasSubRoutes) {
      buffer.writeln('$i      routes: [');
      if (manifest.hasUpdate) {
        buffer.writeln('$i        GoRoute(');
        buffer.writeln("$i          path: 'edit',");
        buffer.writeln(
            "          builder: (context, state) => ${entity}EditScreen(id: ${manifest.parseId("state.pathParameters['$idParam']!")}, $parentParamName: ${manifest.parseParentId("state.pathParameters['$parentIdParam']!")}),");
        buffer.writeln('$i        ),');
      }
      for (final child in children) {
        _writeNestedEntityRoute(
          child,
          parentIdParam: idParam,
          childrenByParent: childrenByParent,
          buffer: buffer,
          level: level + 4,
        );
      }
      buffer.writeln('$i      ],');
    }

    buffer.writeln('$i    ),');

    if (manifest.hasUpdate) {
      buffer.writeln('$i    GoRoute(');
      buffer.writeln("$i      path: 'create',");
      buffer.writeln(
          "$i      builder: (context, state) => ${entity}CreateScreen($parentParamName: ${manifest.parseParentId("state.pathParameters['$parentIdParam']!")}),");
      buffer.writeln('$i    ),');
    }

    buffer.writeln('$i  ],');
    buffer.writeln('$i),');
  }

  static String _i(int level) => '  ' * level;
}
