## Unreleased

* The generated form screens now save: they build the entity from the form and call the provider's `create()`/`update()` (PF-11). The id must be nullable or have a default.
* Added `@Id` annotation; ids are typed (`String`/`int`) instead of `Object` (PF-23).
* `@Parent` now takes the parent entity type: `@Parent(Post)`; the parent may live in another source file.

## 0.1.0

* Initial release.
* Annotations: `@View`, `@Update`, `@Delete`, `@FormField`, `@Parent`.
* Enums: `Validator` (`required`, `email`, `positiveNumber`, `url`), `FieldWidget` (`auto`, `multilineText`, `password`, `datePicker`, `dropdown`, `toggle`).
