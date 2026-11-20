import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:path/path.dart' as p;
import 'package:source_gen/source_gen.dart';

import '../core/artifact_generator.dart';
import '../core/code.dart';
import '../core/entity_context.dart';
import '../core/format.dart';
import '../core/library_emitter.dart';
import '../features/actions/action_scanner.dart';
import '../features/entity_screens/child_screen.dart';
import '../features/features.dart';
import '../generators/prefab_generator.dart';

/// A source library with `@Entity` classes: its element and its path relative
/// to the package root (e.g. `lib/product.dart`).
class PromoteSource {
  const PromoteSource(this.library, this.path);

  final LibraryElement library;
  final String path;
}

/// The file the `promote` command writes.
class PromotedFile {
  const PromotedFile(this.path, this.content);

  /// Path relative to the package root (e.g. `lib/product_detail_screen.dart`).
  final String path;
  final String content;
}

/// Thrown for a usage error (unknown name, bad target); the message is
/// printed as is.
class PromoteException implements Exception {
  const PromoteException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Renders the generated code of the artifact [name] as a file of its own:
/// the artifact's imports, the import of the `.prefab.dart` library, the
/// `@Promoted()` annotation and the formatted code.
///
/// [actions] and [childScreens] are the `@EntityAction` functions and
/// `@EntityScreen` classes of the package (see [scanPackageContributions]):
/// the written screen contains them, so it behaves like the generated one.
/// [packageName] lets an action declared in the entity's own file be reached
/// without an import.
///
/// The file goes to [to] (relative to the package root) or, by default, to
/// `<folder of the entity's source file>/<snake_name>.dart`.
PromotedFile promoteArtifact(
  String name,
  List<PromoteSource> sources, {
  String? to,
  List<ActionDeclaration> actions = const [],
  List<ChildScreen> childScreens = const [],
  String? packageName,
}) {
  final emitter = LibraryEmitter(
    artifactFactories: prefabArtifactFactories,
    features: registeredFeatures,
  );
  final known = <String>{};
  for (final source in sources) {
    final fileName = p.posix.basename(source.path);
    final self = packageName == null
        ? null
        : 'package:$packageName/${p.posix.relative(source.path, from: 'lib')}';
    final entities = EntityContext.readAll(
      LibraryReader(source.library),
      fileName,
      actions: [for (final a in actions) a.uri == self ? a.inSameLibrary() : a],
      childScreens: childScreens,
    );
    final artifacts = emitter.emitArtifacts(entities);
    known.addAll(artifacts.keys);
    final code = artifacts[name];
    if (code == null) continue;
    return _render(name, code, source.path, fileName, to);
  }
  final closest = closestName(name, known);
  throw PromoteException(
    '$name is not a generated artifact'
    '${closest == null ? '' : '; did you mean $closest?'}',
  );
}

/// The `@EntityAction` functions and `@EntityScreen` classes in the Dart
/// [files] of a package (path relative to the package root, content), with
/// the `package:` uris generated code imports them by.
({List<ActionDeclaration> actions, List<ChildScreen> childScreens})
scanPackageContributions(String packageName, Map<String, String> files) {
  final actions = <ActionDeclaration>[];
  final screens = <ChildScreen>[];
  final paths = files.keys.toList()..sort();
  for (final path in paths) {
    if (!path.startsWith('lib/') ||
        path.endsWith('.prefab.dart') ||
        path.endsWith('.g.dart')) {
      continue;
    }
    final source = files[path]!;
    final uri = 'package:$packageName/${path.substring(4)}';
    try {
      if (source.contains('EntityAction')) {
        actions.addAll(scanActions(source, uri));
      }
      if (source.contains('EntityScreen')) {
        screens.addAll(scanChildScreens(source, uri));
      }
    } on ActionException catch (e) {
      throw PromoteException(e.message);
    } on ChildScreenException catch (e) {
      throw PromoteException(e.message);
    }
  }
  return (actions: actions, childScreens: screens);
}

PromotedFile _render(
  String name,
  Code code,
  String sourcePath,
  String sourceFile,
  String? to,
) {
  final target =
      to ??
      p.posix.join(p.posix.dirname(sourcePath), '${_snakeCase(name)}.dart');
  if (!target.endsWith('.dart')) {
    throw PromoteException('--to must be a path to a .dart file: $target');
  }
  final targetDir = p.posix.dirname(target);
  final sourceDir = p.posix.dirname(sourcePath);
  final imports = Imports()
    ..add('package:prefab_flutter/prefab_flutter.dart')
    ..add(
      _relative(
        targetDir,
        sourceDir,
        sourceFile.replaceAll(RegExp(r'\.dart$'), '.prefab.dart'),
      ),
    );
  for (final uri in code.imports) {
    imports.add(uri.contains(':') ? uri : _relative(targetDir, sourceDir, uri));
  }
  final text = _annotate(name, code.text);
  final source = '${imports.render()}\n\n$text\n';
  return PromotedFile(target, formatGenerated(source, target));
}

String _relative(String fromDir, String toDir, String file) =>
    p.posix.relative(p.posix.join(toDir, file), from: fromDir);

/// Puts `@Promoted()` in front of the declaration called [name].
String _annotate(String name, String text) {
  final unit = parseString(content: text, throwIfDiagnostics: false).unit;
  for (final d in unit.declarations) {
    final names = d is NamedCompilationUnitMember
        ? [d.name.lexeme]
        : d is TopLevelVariableDeclaration
        ? [for (final v in d.variables.variables) v.name.lexeme]
        : <String>[];
    if (names.contains(name)) {
      return '${text.substring(0, d.offset)}@Promoted()\n'
          '${text.substring(d.offset)}';
    }
  }
  throw StateError('The code generated for $name does not declare it.');
}

/// `ProductDetailScreen` -> `product_detail_screen`, `productsProvider` ->
/// `products_provider`, `$productRoutes` -> `product_routes`.
String _snakeCase(String name) => name
    .replaceAll(r'$', '')
    .replaceAllMapped(RegExp('(?<=[a-z0-9])[A-Z]'), (m) => '_${m[0]}')
    .toLowerCase();
