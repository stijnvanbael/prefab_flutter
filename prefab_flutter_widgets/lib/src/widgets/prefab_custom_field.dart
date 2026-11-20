import 'package:material_ui/material_ui.dart';

/// The contract of a hand-written form widget for one field, named with
/// `@Field(form: FormOptions(custom: ColorField.new))`.
///
/// The generated create and edit screens call the referenced constructor or
/// function with these named parameters (`key` is never passed; `validator`
/// only if the widget declares it). [T] is the field type without `?`.
///
/// * [initialValue] is `null` in the create screen and the loaded value in
///   the edit screen.
/// * [onChanged] must be called with every new value; the form keeps the last
///   one and passes it to the entity constructor on save.
/// * [label] is the field label.
/// * [validator] runs the field's validators (`Validator.required`); a widget
///   that is used for a required field must declare it and wire it to a
///   `FormField` (for example by building on `FormField<T>`).
///
/// The generator checks the parameter names of the referenced widget; Dart
/// checks their types in the generated code.
typedef PrefabFieldBuilder<T> = Widget Function({
  Key? key,
  required T? initialValue,
  required ValueChanged<T?> onChanged,
  required String label,
  String? Function(T? value)? validator,
});

/// The contract of a hand-written display widget for one field, named with
/// `@Field(display: ColorSwatch.new)`: the detail screen and the list tile
/// build it with the field value (`null` for an empty nullable field) instead
/// of showing `toString()`.
typedef PrefabDisplayBuilder<T> = Widget Function({
  Key? key,
  required T value,
});
