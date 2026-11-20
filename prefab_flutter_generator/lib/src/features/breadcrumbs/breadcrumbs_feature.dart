import '../../core/artifact.dart';
import '../../core/code.dart';
import '../../core/entity_context.dart';
import '../../core/feature.dart';
import '../../generators/detail_screen_generator.dart';
import '../../generators/list_screen_generator.dart';
import '../../manifest/entity_manifest.dart';
import 'breadcrumb_items.dart';

/// The breadcrumb row of list and detail screens of entities nested two or
/// more levels deep.
///
/// Each ancestor is a tappable step labelled with the first visible field of
/// the ancestor, read from the ancestor's detail provider; the last step is
/// the entity's own title. Contributes to `appBarBottom` of both screens.
class BreadcrumbsFeature extends Feature {
  const BreadcrumbsFeature();

  static const _name = 'breadcrumbs';

  @override
  String get name => _name;

  @override
  void contribute(EntityContext entity, ArtifactSet artifacts) {
    final m = entity.manifest;
    if (!m.hasBreadcrumbs) return;
    final id = m.entityName;
    final code = _bottom(m);
    artifacts
        .get<ListScreenArtifact>(ArtifactKind.listScreen, id)
        ?.appBarBottom
        .add(_name, code);
    artifacts
        .get<DetailScreenArtifact>(ArtifactKind.detailScreen, id)
        ?.appBarBottom
        .add(_name, code);
  }

  /// The `bottom:` argument of the AppBar of [m].
  static Code _bottom(EntityManifest m) {
    final lines = <String>[
      'bottom: PrefabBreadcrumbBar(',
      '  items: [',
    ];
    lines.addAll(ancestorBreadcrumbItems(m));
    lines
      ..add("    const PrefabBreadcrumb(label: '${escapeDartString(m.title)}'),")
      ..add('  ],')
      ..add('),');
    return Code(
      lines.join('\n'),
      imports: {
        Libs.goRouter,
        Libs.widgets,
        // The ancestors' detail providers live in the other `.prefab.dart`
        // when they are declared in another library.
        ...ancestorImports([m]),
      },
    );
  }
}
