import 'package:prefab_flutter/prefab_flutter.dart';

import '../manifest/field_manifest.dart';
import 'code.dart';
import 'extension_point.dart';

/// How one resolved [FieldWidget] appears in the create and edit forms.
///
/// Registered in a [FieldEmitters] registry, so a new widget is one new class
/// and one registry line. The implementations live in
/// `features/field_widgets/`.
abstract class FieldEmitter {
  const FieldEmitter();

  /// The annotation value this emitter renders. [FieldWidget.auto] is never
  /// returned: auto fields are resolved by [accepts].
  FieldWidget get widget;

  /// Whether [FieldWidget.auto] resolves [field] to this emitter.
  bool accepts(FieldManifest field);

  /// Throws if [field] cannot be rendered by this emitter (e.g. a time picker
  /// on an `int`).
  void check(FieldManifest field) {}

  /// The declaration of the form state of [field] (a controller or a value),
  /// as members of the screen's state class; `null` if it has none.
  Code? stateDeclaration(FieldManifest field);

  /// The statements that copy the value of [field] from [entity] (an
  /// expression of the loaded item) into the form state, in the edit screen.
  Code initialValue(FieldManifest field, String entity);

  /// The form widget of [field].
  Code formField(FieldManifest field);

  /// The value passed to the entity constructor when the form is saved.
  String valueExpression(FieldManifest field);
}

/// The [FieldEmitter]s, looked up by the annotation value of a field.
class FieldEmitters<E extends FieldEmitter> {
  FieldEmitters(this.emitters);

  /// Checked in order for [FieldWidget.auto]; the last one must accept
  /// everything not claimed by another (plain text).
  final List<E> emitters;

  /// The emitter of [field]: the one registered for an explicit
  /// [FieldManifest.fieldWidget], else the first that accepts it.
  E resolve(FieldManifest field) {
    final emitter = field.fieldWidget == FieldWidget.auto
        ? emitters.firstWhere((e) => e.accepts(field))
        : emitters.firstWhere((e) => e.widget == field.fieldWidget);
    emitter.check(field);
    return emitter;
  }
}

/// The Dart condition a validator adds to a field's `validator:` callback.
abstract class ValidatorEmitter<V extends Validator> {
  const ValidatorEmitter();

  /// Lines checking `value` (a non-null `String`) against [validator].
  Code check(FieldManifest field, V validator, String value);
}

/// The [ValidatorEmitter]s, looked up by the runtime type of the validator.
class ValidatorEmitters {
  ValidatorEmitters(this._byType);

  final Map<Type, ValidatorEmitter<Validator>> _byType;

  ValidatorEmitter<Validator> resolve(Validator validator) {
    final emitter = _byType[validator.runtimeType];
    if (emitter == null) {
      throw StateError('No ValidatorEmitter registered for '
          '${validator.runtimeType}.');
    }
    return emitter;
  }
}

/// How a field's value is shown in detail screens and list tiles.
abstract class FieldDisplay {
  const FieldDisplay();

  bool accepts(FieldManifest field);

  /// Dart expression of type `String`, e.g. `p.price.toString()`.
  String text(FieldManifest field, String receiver);
}

/// The [FieldDisplay]s; the first that accepts a field shows it.
class FieldDisplays {
  FieldDisplays(this.displays);

  final List<FieldDisplay> displays;

  FieldDisplay resolve(FieldManifest field) =>
      displays.firstWhere((d) => d.accepts(field));
}

/// Shows every field with `toString()`. Nullable fields are handled by the
/// `nullable_fields` feature through the `fieldValue` point.
class DefaultFieldDisplay extends FieldDisplay {
  const DefaultFieldDisplay();

  @override
  bool accepts(FieldManifest field) => true;

  @override
  String text(FieldManifest field, String receiver) =>
      '$receiver.${field.name}.toString()';
}

/// The field displays used by the detail and list screens.
final fieldDisplays = FieldDisplays(const [DefaultFieldDisplay()]);

/// A feature's way to show a field value in a detail screen or list tile; the
/// `fieldValue` extension point of those screens holds these. The first
/// contribution (by order, then feature name) that [accepts] a field wins
/// over the [FieldDisplay] registry.
class FieldValue {
  const FieldValue({required this.accepts, required this.text});

  final bool Function(FieldManifest field) accepts;

  /// Dart expression of type `String` showing `receiver.field`.
  final String Function(FieldManifest field, String receiver) text;
}

/// The text expression for [field]: a contributed [FieldValue] if one accepts
/// it, else the [fieldDisplays] entry.
String fieldValueText(
  ValuePoint<FieldValue> point,
  FieldManifest field,
  String receiver,
) {
  for (final v in point.values) {
    if (v.accepts(field)) return v.text(field, receiver);
  }
  return fieldDisplays.resolve(field).text(field, receiver);
}
