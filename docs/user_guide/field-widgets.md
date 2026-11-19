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
