[← User guide](../user_guide.md)

# Field widgets

`FieldWidget` selects the input widget in the create and edit forms.

| Value | Generated widget | Used automatically for |
|---|---|---|
| `auto` | Inferred from the Dart type (see the right-hand column) | — |
| `multilineText` | `TextFormField` with `maxLines: null` | — |
| `password` | `TextFormField` with `obscureText: true` | — |
| `numberInput` | `TextFormField` with a numeric keyboard and an input formatter (`int`: signed digits; `double`/`num`: signed digits and one `.`), plus a type check | `int`, `double`, `num` |
| `datePicker` | Read-only `TextFormField` that opens `showDatePicker` (years 2000–2100) | `DateTime` |
| `timePicker` | Read-only `TextFormField` that opens `showTimePicker`; supports `Duration` (time since midnight) and `String` in `HH:mm` format | — |
| `dateTimePicker` | Read-only `TextFormField` that chains `showDatePicker` and `showTimePicker` | — (`DateTime` defaults to `datePicker`) |
| `dropdown` | `DropdownButtonFormField` over `Type.values`, labelled with `name` | enum types |
| `toggle` | `SwitchListTile` | `bool` |

`auto` inference rules: `bool` → `toggle`; enum types → `dropdown`;
`DateTime` → `datePicker`; `int`/`double`/`num` → `numberInput`; every other type
(`String`, …) → a plain `TextFormField`. `multilineText`, `password`,
`timePicker` and `dateTimePicker` are never inferred; set them explicitly.

With `auto`, any other type (`String`, …) gets a plain `TextFormField`.
Number fields reject non-numeric text ("Must be a whole number" / "Must be a
number"); combine them with `Validator.nonNegative`, `Validator.min(n)` or
`Validator.max(n)` for range checks.

The picker widgets keep the selected value in a typed state variable (so the
entity is built without parsing text); the text controller only holds the
display string, formatted with the locale's `MaterialLocalizations`
(`formatCompactDate` / `formatTimeOfDay`), not ISO-8601. `TimeOfDay` is not a
supported field type because entity classes stay pure Dart. Using
`timePicker` on a type other than `Duration`/`String`, or `dateTimePicker` on
a type other than `DateTime`, fails the build with an error.

## Custom widgets for one field

When no `FieldWidget` fits (a colour picker, a schedule editor, a map
position), plug in one hand-written widget and keep the rest of the screen
generated. Name it with a constant constructor tear-off or top-level function:

```dart
@Field(
  label: 'Accent colour',
  form: FormOptions(builder: ColorField.new, validators: [Validator.required]),
  displayBuilder: ColorSwatch.new,
)
final int accent;
```

**Form widget** (`FormOptions.builder`). It replaces the generated widget in
the create and edit screens. The generated code calls it with these named
parameters (the `PrefabFieldBuilder<T>` typedef in `prefab_flutter_widgets`;
`T` is the field type without `?`):

| Parameter | Type | Meaning |
|---|---|---|
| `initialValue` | `T?` | `null` in the create screen, the loaded value in the edit screen |
| `onChanged` | `ValueChanged<T?>` | call it with every new value; the form keeps the last one and passes it to the entity constructor |
| `label` | `String` | the field label |
| `validator` | `String? Function(T? value)?` | runs `Validator.required`; optional, but a widget used for a required field must declare it |
| `key` | `Key?` | optional, never passed |

Only `Validator.required` can be combined with a custom widget (the other
validators check text; others are planned in PF-69); check other rules inside the widget. Create and
edit screens share the widget; it is built after the edit screen has loaded
the entity, so `initialValue` is already the stored value.

**Display widget** (`Field.displayBuilder`). The detail screen and the list tile
slots build it with `value:` (the `PrefabDisplayBuilder<T>` typedef; `null`
for an empty nullable field) instead of `Text(value.toString())`. It also
replaces the em dash shown for nullable fields.

The generator checks the reference at build time: it must be a constructor
or function with the named parameters above (and no other required
parameters). Otherwise the build fails with a message naming the field. Dart
checks the parameter types in the generated code. The library that declares
the widget is imported automatically. The example app uses `RatingField` and
`RatingStars` for `Review.quality`.
