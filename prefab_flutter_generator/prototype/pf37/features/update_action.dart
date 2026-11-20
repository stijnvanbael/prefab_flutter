// PF-37 prototype - not part of the published generator.

import '../artifacts/detail_screen.dart';
import '../core/artifact.dart';
import '../core/code.dart';
import '../core/entity_context.dart';
import '../core/feature.dart';

/// `@Update`: an Edit action on the detail screen. (The real module would
/// also add the edit screen artifact, the provider's `updateEntity` and the
/// API client's `update`.)
class UpdateActionFeature extends Feature {
  const UpdateActionFeature();

  @override
  String get name => 'update';

  @override
  void contribute(EntityContext entity, ArtifactSet artifacts) {
    final m = entity.manifest;
    if (!m.hasUpdate) return;
    final editPath = entity.paths.editPath(m, r'$id');
    artifacts
        .get<DetailScreenArtifact>(ArtifactKind.detailScreen, m.entityName)
        ?.appBarActions
        .add(
          name,
          order: 10,
          Code(
            '''
IconButton(
  icon: const Icon(Icons.edit),
  tooltip: 'Edit',
  onPressed: () => context.push('$editPath'),
),''',
            imports: {Libs.goRouter},
          ),
        );
  }
}
