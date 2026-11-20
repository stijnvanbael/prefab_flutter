import '../../core/entity_context.dart';
import '../../core/feature.dart';

export 'custom_field_display.dart';
export 'custom_field_emitter.dart';

/// Hand-written widgets for single fields (PF-65): `FormOptions.custom` in the
/// create and edit forms, `Field.display` in the detail screen and list tile.
///
/// Like `field_widgets`, this feature adds no code to an artifact itself: the
/// form screens ask the `formFieldEmitters` registry (which lists
/// [CustomFormFieldEmitter] first) and the read-only screens ask the
/// `fieldDisplays` registry (which lists [CustomFieldDisplay] first).
class CustomFieldFeature extends Feature {
  const CustomFieldFeature();

  @override
  String get name => 'custom_field';

  @override
  void contribute(EntityContext entity, ArtifactSet artifacts) {}
}
