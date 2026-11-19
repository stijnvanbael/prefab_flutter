// PF-37 prototype - not part of the published generator.

import 'package:prefab_flutter_generator/src/generators/breadcrumbs.dart';

import '../artifacts/detail_screen.dart';
import '../core/artifact.dart';
import '../core/code.dart';
import '../core/entity_context.dart';
import '../core/feature.dart';

/// Breadcrumbs (PF-19) in the AppBar of entities nested two or more levels
/// deep. Reuses today's `breadcrumbBottom` unchanged: existing emitters can
/// be wrapped as contributions before they are rewritten.
class BreadcrumbsFeature extends Feature {
  const BreadcrumbsFeature();

  @override
  String get name => 'breadcrumbs';

  @override
  void contribute(EntityContext entity, ArtifactSet artifacts) {
    final m = entity.manifest;
    if (!m.hasBreadcrumbs) return;
    artifacts
        .get<DetailScreenArtifact>(ArtifactKind.detailScreen, m.entityName)
        ?.appBarBottom
        .add(
          name,
          Code(
            breadcrumbBottom(m, ''),
            imports: {
              Libs.goRouter,
              Libs.widgets,
              // Detail providers of ancestors declared in other libraries.
              ...ancestorImports([m]),
            },
          ),
        );
  }
}
