import '../../core/field_registries.dart';
import '../../manifest/field_manifest.dart';

/// A [FieldEmitter] for the create and edit forms, with what the form template
/// needs to know about every widget.
abstract class FormFieldEmitter extends FieldEmitter {
  const FormFieldEmitter();

  /// Whether the form state holds a `TextEditingController` for the field
  /// (and disposes it).
  bool get usesController;

  /// Whether the widget is a text input, which accepts every [Validator]
  /// (other widgets only accept `required`).
  bool get isTextInput;

  /// Whether the text of the field is checked to parse as a number before the
  /// other validators run.
  bool get parsesNumbers => false;

  /// Whether the field is a number type (`int`, `double`, `num`).
  static bool isNumber(FieldManifest field) =>
      const {'int', 'double', 'num'}.contains(field.dartType);
}
