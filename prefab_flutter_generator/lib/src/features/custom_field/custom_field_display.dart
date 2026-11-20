import '../../core/code.dart';
import '../../core/field_registries.dart';
import '../../manifest/field_manifest.dart';

/// A hand-written display widget (`@Field(displayBuilder: ...)`), used by the detail
/// screen and the list tile slots instead of `Text(value.toString())`. It gets
/// the field value (also `null` for a nullable field) as `value:`.
class CustomFieldDisplay extends FieldDisplay {
  const CustomFieldDisplay();

  @override
  bool accepts(FieldManifest field) => field.customDisplay != null;

  @override
  String text(FieldManifest field, String receiver) =>
      '$receiver.${field.name}.toString()';

  @override
  Code? widget(FieldManifest field, String receiver) {
    final custom = field.customDisplay!;
    return Code(
      '${custom.invocation}(value: $receiver.${field.name})',
      imports: {if (custom.libraryUri != null) custom.libraryUri!},
    );
  }
}
