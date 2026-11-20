// PF-37 prototype - not part of the published generator.

import 'package:prefab_flutter_generator/src/manifest/entity_manifest.dart';
import 'package:prefab_flutter_generator/src/manifest/entity_paths.dart';

import 'artifact.dart';

/// What a feature module or artifact template knows about one entity: the
/// manifest (all annotation reading happens there) plus file-level facts.
class EntityContext {
  const EntityContext({
    required this.manifest,
    required this.paths,
    required this.sourceFileName,
  });

  final EntityManifest manifest;
  final EntityPaths paths;

  /// File name of the annotated source, imported by every artifact.
  final String sourceFileName;
}

/// The artifacts that are generated for one library, after promoted ones
/// were removed. Feature modules look artifacts up here; a lookup returns
/// `null` when the artifact is not generated (e.g. no `@Update`) or promoted,
/// so a feature never contributes to a hand-written class.
class ArtifactSet {
  ArtifactSet(Iterable<Artifact> artifacts)
      : _byId = {for (final a in artifacts) a.id: a};

  final Map<ArtifactId, Artifact> _byId;

  Iterable<Artifact> get all => _byId.values;

  T? get<T extends Artifact>(ArtifactKind kind, String entity) =>
      _byId[ArtifactId(kind, entity)] as T?;
}
