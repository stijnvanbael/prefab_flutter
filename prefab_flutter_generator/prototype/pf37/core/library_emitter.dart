// PF-37 prototype - not part of the published generator.

import 'artifact.dart';
import 'code.dart';
import 'entity_context.dart';
import 'feature.dart';

/// A hand-written declaration that replaces a generated artifact.
class PromotedDeclaration {
  const PromotedDeclaration(this.name, this.libraryUri);

  /// Top-level name, equal to the artifact's [Artifact.primaryName].
  final String name;

  /// Library generated code imports to reach it.
  final String libraryUri;
}

/// Creates the artifacts of one kind for an entity (empty when the entity
/// does not have that artifact, e.g. no edit screen without `@Update`).
typedef ArtifactFactory = Iterable<Artifact> Function(EntityContext entity);

/// Assembles one generated library from artifacts and feature contributions.
class LibraryEmitter {
  const LibraryEmitter({
    required this.artifactFactories,
    required this.features,
    this.promoted = const [],
  });

  final List<ArtifactFactory> artifactFactories;
  final List<Feature> features;
  final List<PromotedDeclaration> promoted;

  String emit(List<EntityContext> entities, {required String header}) {
    final promotedByName = {for (final p in promoted) p.name: p};
    final imports = Imports();

    // 1. Create artifacts kind-major (all detail screens, then all list
    //    screens, ...), the order of today's output. Promoted artifacts are
    //    dropped; their hand-written replacement is imported (for the other
    //    artifacts here) and re-exported (for libraries importing this one).
    final created = <Artifact>[];
    var replaced = 0;
    for (final factory in artifactFactories) {
      for (final entity in entities) {
        for (final artifact in factory(entity)) {
          final replacement = promotedByName[artifact.primaryName];
          if (replacement != null) {
            imports.add(replacement.libraryUri);
            imports.export(replacement.libraryUri, replacement.name);
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

    // 3. Emit each artifact separately; collect imports in the core.
    final bodies = <String>[];
    for (final artifact in created) {
      final code = artifact.emit();
      imports.addAll(code.imports);
      bodies.add(code.text);
    }
    if (bodies.isEmpty && replaced == 0) return '';
    return [header, imports.render(), for (final b in bodies) '\n$b']
        .join('\n');
  }
}
