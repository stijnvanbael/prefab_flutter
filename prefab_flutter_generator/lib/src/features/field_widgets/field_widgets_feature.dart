import '../../core/entity_context.dart';
import '../../core/feature.dart';
import '../../core/field_registries.dart';
import 'choice_field_emitters.dart';
import 'form_field_emitter.dart';
import 'picker_field_emitters.dart';
import 'text_field_emitters.dart';

export 'form_field_emitter.dart';

/// The form widgets of the fields in the create and edit screens, one
/// [FormFieldEmitter] per `FieldWidget`.
///
/// This feature adds no code to an artifact by itself: the form screens ask the
/// registry ([formFieldEmitters]) for the widget of each field. To add a
/// widget, write one emitter class and add it to the list below.
class FieldWidgetsFeature extends Feature {
  const FieldWidgetsFeature();

  @override
  String get name => 'field_widgets';

  @override
  void contribute(EntityContext entity, ArtifactSet artifacts) {}
}

/// The emitter of every `FieldWidget`; for `FieldWidget.auto` the first
/// emitter that accepts the field's type wins, so plain text stays last.
final formFieldEmitters = FieldEmitters<FormFieldEmitter>(const [
  ToggleFieldEmitter(),
  DatePickerFieldEmitter(),
  NumberInputFieldEmitter(),
  DropdownFieldEmitter(),
  TimePickerFieldEmitter(),
  DateTimePickerFieldEmitter(),
  MultilineTextFieldEmitter(),
  PasswordFieldEmitter(),
  PlainTextFieldEmitter(),
]);
