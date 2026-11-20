[← User guide](../user_guide.md)

# Validators

`Validator` is a sealed class. Parameterless rules are static constants
(`Validator.email`); rules with a value are const factories
(`Validator.min(0)`). Rules are combined in the field's `form: FormOptions(validators: [...])` list and
checked in order; the first failing check shows its message.

| Validator | Check | Default message |
|---|---|---|
| `Validator.required` | value is not empty | `Required` |
| `Validator.email` | matches `^[^@\s]+@[^@\s]+\.[^@\s]+$` | `Invalid email address` |
| `Validator.url` | parses as an absolute URI | `Invalid URL` |
| `Validator.positive` | parses as a number greater than 0 (`positiveNumber` is a kept alias) | `Must be a positive number` |
| `Validator.nonNegative` | parses as a number >= 0 | `Must not be negative` |
| `Validator.min(n)` | parses as a number >= `n` | `Must be at least n` |
| `Validator.max(n)` | parses as a number <= `n` | `Must be at most n` |
| `Validator.minLength(n)` | at least `n` characters | `Must be at least n characters` |
| `Validator.maxLength(n)` | at most `n` characters | `Must be at most n characters` |
| `Validator.pattern(regex)` | matches the regular expression | `Invalid format` |

Every validator accepts a custom message. The factories take
`message:` (`Validator.min(0, message: 'No negatives')`,
`Validator.pattern(r'^[A-Z]+$', message: 'Capitals only')`); for the constants
use the class constructor, e.g. `RequiredValidator(message: 'Name needed')`,
`EmailValidator(message: ...)`, `UrlValidator`, `PositiveValidator`,
`NonNegativeValidator`.

Checks depend on the rendered widget:

- Text, multiline and password fields support every validator.
- On `dropdown` fields (and nullable `toggle` fields) only `required` applies;
  it checks `value == null`.
- Using any other validator on a dropdown, toggle or date picker field fails the
  build with an error naming the field.

### Nullable and optional fields

The nullability of the Dart type decides whether a field is required:

| Field type | Form behaviour | Detail screen |
|---|---|---|
| Non-nullable (`String`, `int`, `DateTime`, enum) | Required automatically (`Required`), no `Validator.required` needed | Value |
| Nullable (`String?`, `int?`, `DateTime?`, enum?) | Optional: empty input is valid and other validators are skipped when empty. Add `Validator.required` to require it | `—` (em dash) when `null` |
| `bool` | `SwitchListTile`, starts `false` | Value |
| `bool?` | Dropdown with an empty, `Yes` and `No` option; starts `null` | `—` when `null` |
| Nullable enum | Dropdown with an empty option; starts `null` | `—` when `null` |
| Nullable `DateTime` | Date picker, starts empty | `—` when `null` |

The edit form prefills nullable fields null-safely (`item.x ?? ''`).

### Saving

The Save button validates the form and builds the entity by calling the
entity's **unnamed constructor**. Each constructor parameter gets its value from:

| Parameter | Create screen | Edit screen |
|---|---|---|
| the id (`@Id` / `id`) | omitted | `widget.id` |
| the `@Parent` field | `widget.<parentId>` | `widget.<parentId>` |
| a visible `@Field` | typed form state | typed form state |
| a hidden or un-annotated field | omitted | copied from the loaded item |

Form values are converted by type: `int` / `double` / `num` are parsed from the
text field (the form rejects non-numeric input first), `DateTime`, enums and
`bool` come from their pickers, and an **empty input for a nullable field is
passed as `null`**.

Parameters that are omitted on create must be nullable, optional or have a
default value. Otherwise the generator fails with a build-time error naming the
parameter (so the id must be e.g. `final int? id;` with `this.id`). A form field
of a type the form cannot convert (anything other than `String`, `int`,
`double`, `num`, `bool`, `DateTime` or an enum) also fails the build, naming the
field.

The entity is then passed to the list notifier's `create()` (create screen) or
`updateEntity()` (edit screen; named to avoid clashing with `AsyncNotifier.update`) and the screen pops on success. While the request is
in flight the button is disabled and shows a progress indicator; an error is
shown in a `SnackBar` and the screen stays open.
