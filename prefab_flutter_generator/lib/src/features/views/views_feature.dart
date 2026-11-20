import '../../core/artifact.dart';
import '../../core/entity_context.dart';
import '../../core/feature.dart';
import '../../generators/detail_screen_generator.dart';
import '../../generators/list_screen_generator.dart';
import '../../manifest/entity_manifest.dart';
import '../../manifest/field_manifest.dart';

/// Named views of an entity (`@Field.views`): which fields the list tile and
/// the detail screen show.
///
/// Contributes the fields of the `list` view to the `itemTile` point of the
/// list screen (title, subtitle and trailing slot, in that order) and the
/// fields of the `detail` view to the `detailFields` point of the detail
/// screen, both with order 10. Without any declared view the list tile shows
/// only the first visible field and the detail screen all visible fields. A
/// field without `views` appears in every view. The raw `views` set stays in
/// `FieldManifest` (read with the other field flags).
class ViewsFeature extends Feature {
  const ViewsFeature();

  static const _name = 'views';

  /// Number of list tile slots (title, subtitle, trailing).
  static const tileSlots = 3;

  @override
  String get name => _name;

  @override
  void contribute(EntityContext entity, ArtifactSet artifacts) {
    final id = entity.manifest.entityName;
    final m = entity.manifest;

    final list = artifacts.get<ListScreenArtifact>(ArtifactKind.listScreen, id);
    if (list != null) {
      for (final f in m.tileFields) {
        list.itemTile.add(_name, f, order: 10);
      }
    }

    final detail =
        artifacts.get<DetailScreenArtifact>(ArtifactKind.detailScreen, id);
    if (detail != null) {
      for (final f in m.detailFields) {
        detail.detailFields.add(_name, f, order: 10);
      }
    }
  }
}

/// What only the views feature needs to know about an entity.
extension ViewsManifest on EntityManifest {
  /// Visible fields that appear in the view named [viewName]; fields without
  /// a `views` set appear in every view.
  List<FieldManifest> fieldsForView(String viewName) =>
      visibleFields.where((f) => f.inView(viewName)).toList();

  /// Whether any field declares a `views` set.
  bool get hasViews => fields.any((f) => f.views != null);

  /// Fields of the list tile slots, at most [ViewsFeature.tileSlots].
  List<FieldManifest> get tileFields => (hasViews
          ? fieldsForView('list').take(ViewsFeature.tileSlots)
          : visibleFields.take(1))
      .toList();

  /// Fields of the detail screen: the `detail` view, or every visible field
  /// when the view is empty.
  List<FieldManifest> get detailFields {
    final inDetail = fieldsForView('detail');
    return inDetail.isEmpty ? visibleFields : inDetail;
  }
}
