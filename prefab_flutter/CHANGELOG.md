## Unreleased

* Added `FieldWidget.timePicker` (`Duration` / `HH:mm` `String`) and `FieldWidget.dateTimePicker` (`DateTime`); picker display text now uses `MaterialLocalizations` instead of ISO-8601 (PF-17).
* Added `@Field.views` to choose the views (`list`, `detail`) a field appears in; list tiles fill title, subtitle and trailing from the `list` view (PF-16).
* Added `searchable` and `sortable` to `@Field` and `paged` to `@View` (PF-13).
* The generated form screens now save: they build the entity from the form and call the provider's `create()`/`update()` (PF-11). The id must be nullable or have a default.
* `Validator` is now a sealed class with parameterised validators: `positive`, `nonNegative`, `min`, `max`, `minLength`, `maxLength`, `pattern`, each with an optional custom message; `required`, `email`, `url` and `positiveNumber` remain as constants (PF-31).
* Added `@Id` annotation; ids are typed (`String`/`int`) instead of `Object` (PF-23).
* `@Parent` now takes the parent entity type: `@Parent(Post)`; the parent may live in another source file.
* Added `@Field` (label, hidden, `form: FormOptions(widget:, validators:)`) replacing `@FormField`, which is now deprecated and kept for one release (PF-30).

## 0.1.0

* Initial release.
* Annotations: `@View`, `@Update`, `@Delete`, `@FormField`, `@Parent`.
* Enums: `Validator` (`required`, `email`, `positiveNumber`, `url`), `FieldWidget` (`auto`, `multilineText`, `password`, `datePicker`, `dropdown`, `toggle`).
