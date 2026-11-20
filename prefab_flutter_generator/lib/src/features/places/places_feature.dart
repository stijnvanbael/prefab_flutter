import 'package:prefab_flutter/prefab_flutter.dart';

import '../../core/artifact.dart';
import '../../core/entity_context.dart';
import '../../core/feature.dart';
import '../../generators/detail_screen_generator.dart';
import '../../generators/list_screen_generator.dart';
import '../../manifest/entity_manifest.dart';
import '../../manifest/field_manifest.dart';

/// Where fields appear (`@Field.on`): which fields the list item and the
/// detail screen show. Forms read `on` through `EntityManifest.formFields`.
///
/// Contributes the fields of [Place.item] to the `itemTile` point of the list
/// screen (title, subtitle and trailing slot, in that order) and the fields of
/// [Place.detail] to the `detailFields` point of the detail screen, both with
/// order 10. When no field names its places, the list item shows only the
/// first visible field. A field without `on` appears in every place.
class PlacesFeature extends Feature {
  const PlacesFeature();

  static const _name = 'places';

  /// Number of list item slots (title, subtitle, trailing).
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

/// What only the places feature needs to know about an entity.
extension PlacesManifest on EntityManifest {
  /// Visible fields that appear in [place].
  List<FieldManifest> fieldsOn(Place place) =>
      visibleFields.where((f) => f.isOn(place)).toList();

  /// Whether any field names the places it appears in.
  bool get hasPlaces =>
      fields.any((f) => f.places != null && f.places!.isNotEmpty);

  /// Fields of the list item slots, at most [PlacesFeature.tileSlots].
  List<FieldManifest> get tileFields => (hasPlaces
          ? fieldsOn(Place.item).take(PlacesFeature.tileSlots)
          : visibleFields.take(1))
      .toList();

  /// Fields of the detail screen.
  List<FieldManifest> get detailFields => fieldsOn(Place.detail);
}
