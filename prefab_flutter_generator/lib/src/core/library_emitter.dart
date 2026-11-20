import 'artifact.dart';
import 'code.dart';
import 'entity_context.dart';
import 'feature.dart';

/// Creates the artifacts of one kind for an entity (none when the entity does
/// not have that artifact, e.g. no edit screen without `@Update`).
typedef ArtifactFactory = Iterable<Artifact> Function(EntityContext entity);

/// A hand-written declaration that replaces a generated artifact. Not yet
/// user-facing: promotion is planned in PF-42.
class PromotedDeclaration {
  const PromotedDeclaration(this.name, this.libraryUri);

  /// Top-level name, equal to the artifact's [Artifact.primaryName].
  final String name;

  /// Library generated code imports to reach it.
  final String libraryUri;
}

/// Assembles one generated library from artifacts and feature contributions.
class LibraryEmitter {
  const LibraryEmitter({
    required this.artifactFactories,
    this.features = const [],
    this.promoted = const [],
  });

  final List<ArtifactFactory> artifactFactories;
  final List<Feature> features;

  /// Artifacts to skip, by primary name. The replacing library is imported
  /// and re-exported so the other artifacts keep compiling.
  final List<PromotedDeclaration> promoted;

  /// Returns the whole library, or `''` when nothing is generated.
  String emit(List<EntityContext> entities, {required String header}) {
    final promotedByName = {for (final p in promoted) p.name: p};
    final imports = Imports();

    // 1. Create the artifacts kind-major (all API clients, then all
    //    providers, ...). A skipped artifact is dropped; its replacement is
    //    imported and re-exported.
    final created = <Artifact>[];
    var replaced = 0;
    final factories = [
      ...artifactFactories,
      for (final f in features) ...f.artifacts,
    ];
    for (final factory in factories) {
      for (final entity in entities) {
        for (final artifact in factory(entity)) {
          final replacement = [
            for (final name in artifact.declaredNames) promotedByName[name],
          ].whereType<PromotedDeclaration>().firstOrNull;
          if (replacement != null) {
            imports.add(replacement.libraryUri);
            for (final name in artifact.declaredNames) {
              final p = promotedByName[name];
              if (p != null) imports.export(p.libraryUri, p.name);
            }
            replaced++;
          } else {
            created.add(artifact);
          }
        }
      }
    }
    final artifacts = ArtifactSet(created);

    // 2. Let every feature contribute to the remaining artifacts.
    for (final entity in entities) {
      for (final feature in features) {
        feature.contribute(entity, artifacts);
      }
    }

    // 3. Emit each artifact separately and collect its imports.
    final bodies = <String>[];
    for (final artifact in created) {
      final code = artifact.emit();
      imports.addAll(code.imports);
      bodies.add(code.text);
    }
    if (bodies.isEmpty && replaced == 0) return '';
    return '${[
      header,
      imports.render(),
      for (final b in bodies) '\n$b',
    ].join('\n')}\n';
  }
}
