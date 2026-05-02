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
/// top-level `$prefabRoutes` getter so they can be registered with [GoRouter]
/// in one place:
///
/// ```dart
/// GoRouter(routes: $prefabRoutes)
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
    _writePrefabRoutesList(manifests, buffer);

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
  // $prefabRoutes getter
  // ---------------------------------------------------------------------------

  void _writePrefabRoutesList(
    List<EntityManifest> manifests,
    StringBuffer buffer,
  ) {
    buffer.writeln('List<RouteBase> get \$prefabRoutes => [');
    for (final manifest in manifests) {
      _writeEntityRoute(manifest, buffer);
    }
    buffer.writeln('];');
  }

  void _writeEntityRoute(EntityManifest manifest, StringBuffer buffer) {
    final entity = manifest.entityName;
    final path = manifest.path;

    buffer.writeln('  GoRoute(');
    buffer.writeln("    path: '/$path',");
    buffer.writeln(
        '    builder: (context, state) => const ${entity}ListScreen(),');
    buffer.writeln('    routes: [');

    // Detail route (with optional edit sub-route)
    buffer.writeln('      GoRoute(');
    buffer.writeln("        path: ':id',");
    buffer.writeln(
        "        builder: (context, state) => ${entity}DetailScreen(id: state.pathParameters['id']!),");
    if (manifest.hasUpdate) {
      buffer.writeln('        routes: [');
      buffer.writeln('          GoRoute(');
      buffer.writeln("            path: 'edit',");
      buffer.writeln(
          "            builder: (context, state) => ${entity}EditScreen(id: state.pathParameters['id']!),");
      buffer.writeln('          ),');
      buffer.writeln('        ],');
    }
    buffer.writeln('      ),');

    // Create route (only when @Update is present)
    if (manifest.hasUpdate) {
      buffer.writeln('      GoRoute(');
      buffer.writeln("        path: 'create',");
      buffer.writeln(
          '        builder: (context, state) => const ${entity}CreateScreen(),');
      buffer.writeln('      ),');
    }

    buffer.writeln('    ],');
    buffer.writeln('  ),');
  }
}
