// PF-37 prototype - not part of the published generator.

import '../artifacts/detail_screen.dart';
import '../core/artifact.dart';
import '../core/code.dart';
import '../core/entity_context.dart';
import '../core/feature.dart';

/// `@Delete`: a Delete action with a confirmation dialog on the detail
/// screen.
class DeleteActionFeature extends Feature {
  const DeleteActionFeature();

  @override
  String get name => 'delete';

  @override
  void contribute(EntityContext entity, ArtifactSet artifacts) {
    final m = entity.manifest;
    if (!m.hasDelete) return;
    final e = m.entityNameLower;
    final listArg =
        m.hasParent ? '(${m.parentKeyExpr((a) => a.paramName)})' : '';
    artifacts
        .get<DetailScreenArtifact>(ArtifactKind.detailScreen, m.entityName)
        ?.appBarActions
        .add(
          name,
          order: 20,
          Code(
            '''
IconButton(
  icon: const Icon(Icons.delete),
  tooltip: 'Delete',
  onPressed: ${e}Async.hasValue
      ? () async {
          final $e = ${e}Async.value!;
          final confirmed = await showPrefabDeleteDialog(
            context: context,
            item: $e,
            itemLabel: $e.${m.firstLabelFieldName}.toString(),
            onDelete: () => ref.read(${e}sProvider$listArg.notifier).delete($e),
          );
          if (confirmed && context.mounted) {
            context.pop();
          }
        }
      : null,
),''',
            imports: {Libs.goRouter, Libs.widgets},
          ),
        );
  }
}
