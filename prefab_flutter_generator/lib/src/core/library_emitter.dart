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
    this.featureKinds,
    this.promoted = const [],
  });

  final List<ArtifactFactory> artifactFactories;
  final List<Feature> features;

  /// When set, only artifacts of these kinds are taken from the features'
  /// [Feature.artifacts] (see `ArtifactGenerator.kinds`).
  final Set<ArtifactKind>? featureKinds;

  /// Artifacts to skip, by primary name. The replacing library is imported
  /// and re-exported so the other artifacts keep compiling.
  final List<PromotedDeclaration> promoted;

  /// The artifacts of every factory for [entities], factory-major, with the
  /// features' artifacts filtered by [featureKinds].
  Iterable<(int, Artifact)> _create(List<EntityContext> entities) sync* {
    final factories = [
      (artifactFactories, false),
      ([for (final f in features) ...f.artifacts], true),
    ];
    for (final (list, fromFeatures) in factories) {
      for (final factory in list) {
        for (var i = 0; i < entities.length; i++) {
          for (final artifact in factory(entities[i])) {
            if (fromFeatures &&
                featureKinds != null &&
                !featureKinds!.contains(artifact.id.kind)) {
              continue;
            }
            yield (i, artifact);
          }
        }
      }
    }
  }

  /// The artifacts in output order: grouped by kind (all API clients, then
  /// all providers, ...), an entity's artifacts of a group together. The
  /// features' artifacts take their place in the groups, not after them.
  List<Artifact> _ordered(List<EntityContext> entities) {
    final indexed = _create(entities).toList();
    final order = [
      for (var i = 0; i < indexed.length; i++) (i, indexed[i]),
    ]..sort((a, b) {
        final byGroup = _group(a.$2.$2.id.kind).compareTo(_group(b.$2.$2.id.kind));
        if (byGroup != 0) return byGroup;
        final byEntity = a.$2.$1.compareTo(b.$2.$1);
        return byEntity != 0 ? byEntity : a.$1.compareTo(b.$1);
      });
    return [for (final e in order) e.$2.$2];
  }

  static int _group(ArtifactKind kind) => switch (kind) {
        ArtifactKind.apiClient => 0,
        ArtifactKind.detailProvider ||
        ArtifactKind.listProvider ||
        ArtifactKind.apiClientProvider =>
          1,
        ArtifactKind.detailScreen => 2,
        ArtifactKind.listScreen => 3,
        ArtifactKind.createScreen || ArtifactKind.editScreen => 4,
        ArtifactKind.routes => 5,
        ArtifactKind.breadcrumbs => 6,
      };

  /// The primary names of all artifacts of [entities], promoted or not.
  List<String> artifactNames(List<EntityContext> entities) =>
      [for (final (_, a) in _create(entities)) a.primaryName];

  /// Emits every artifact separately, by primary name, with the libraries it
  /// needs. Used by the `promote` command; `@Promoted` declarations are not
  /// taken into account.
  Map<String, Code> emitArtifacts(List<EntityContext> entities) {
    final artifacts = ArtifactSet(_ordered(entities));
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
    for (final artifact in _ordered(entities)) {
      final replacement = promotedByName[artifact.primaryName];
      if (replacement != null) {
        imports.add(replacement.libraryUri);
        imports.export(replacement.libraryUri, replacement.name);
        replaced++;
      } else {
        created.add(artifact);
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
