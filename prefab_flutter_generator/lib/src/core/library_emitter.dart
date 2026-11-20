import 'artifact.dart';
import 'code.dart';
import 'entity_context.dart';
import 'feature.dart';

/// Creates the artifacts of one kind for an entity (none when the entity does
/// not have that artifact, e.g. no edit screen without `@Update`).
typedef ArtifactFactory = Iterable<Artifact> Function(EntityContext entity);

/// A hand-written declaration (annotated with `@Promoted`) that replaces a
/// generated artifact.
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

  /// The primary names of all artifacts of [entities], promoted or not.
  List<String> artifactNames(List<EntityContext> entities) => [
        for (final factory in [
          ...artifactFactories,
          for (final f in features) ...f.artifacts,
        ])
          for (final entity in entities)
            for (final artifact in factory(entity)) artifact.primaryName,
      ];

  /// Emits every artifact separately, by primary name, with the libraries it
  /// needs. Used by the `promote` command; `@Promoted` declarations are not
  /// taken into account.
  Map<String, Code> emitArtifacts(List<EntityContext> entities) {
    final artifacts = ArtifactSet([
      for (final factory in [
        ...artifactFactories,
        for (final f in features) ...f.artifacts,
      ])
        for (final entity in entities) ...factory(entity),
    ]);
    for (final entity in entities) {
      for (final feature in features) {
        feature.contribute(entity, artifacts);
      }
    }
    return {for (final a in artifacts.all) a.primaryName: a.emit()};
  }

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
