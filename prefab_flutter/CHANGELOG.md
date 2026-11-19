## Unreleased

* Added `@Id` annotation; ids are typed (`String`/`int`) instead of `Object` (PF-23).
* `@Parent` now takes the parent entity type: `@Parent(Post)`; the parent may live in another source file.

## 0.1.0

* Initial release.
* Annotations: `@View`, `@Update`, `@Delete`, `@FormField`, `@Parent`.
* Enums: `Validator` (`required`, `email`, `positiveNumber`, `url`), `FieldWidget` (`auto`, `multilineText`, `password`, `datePicker`, `dropdown`, `toggle`).
