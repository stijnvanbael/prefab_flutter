import '../../core/artifact.dart';
import '../../core/entity_context.dart';
import '../../core/feature.dart';
import '../../core/field_registries.dart';
import '../../generators/detail_screen_generator.dart';
import '../../generators/list_screen_generator.dart';

/// Nullable fields (`String? note`, `int? age`, ...) in the read-only
/// screens: the detail screen and the list tiles show an em dash for `null`.
///
/// Contributes to the `fieldValue` point of both screens (order 10). The
/// nullable handling of the create and edit forms (empty option, `null` when
/// the text is empty) lives in each widget's emitter in `field_widgets`.
class NullableFieldsFeature extends Feature {
  const NullableFieldsFeature();

  static const _name = 'nullable_fields';

  /// Shows a nullable field as text, or an em dash when it is `null`.
  static final fieldValue = FieldValue(
    accepts: (f) => f.isNullable,
    text: (f, receiver) => "$receiver.${f.name}?.toString() ?? '—'",
  );

  @override
  String get name => _name;

  @override
  void contribute(EntityContext entity, ArtifactSet artifacts) {
    final id = entity.manifest.entityName;
    artifacts
        .get<DetailScreenArtifact>(ArtifactKind.detailScreen, id)
        ?.fieldValue
        .add(_name, fieldValue, order: 10);
    artifacts
        .get<ListScreenArtifact>(ArtifactKind.listScreen, id)
        ?.fieldValue
        .add(_name, fieldValue, order: 10);
  }
}
