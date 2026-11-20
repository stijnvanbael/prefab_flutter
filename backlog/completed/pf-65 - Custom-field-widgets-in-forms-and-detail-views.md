---
id: PF-65
title: Custom field widgets in forms and detail views
status: Done
assignee: []
created_date: '2026-11-20 10:00'
labels: []
milestone: m-1
dependencies:
  - PF-39
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
A field that none of the built-in `FieldWidget` values fits (a colour picker, a schedule editor, a map position) forces the developer to promote the whole form screen today. Let them plug in one hand-written widget for one field and keep the rest generated (M1 goal: no app abandons generation because one field is special).

Smallest annotation that expresses it (principle 1): a constant reference to a hand-written widget on the field, for example `@Field(form: FormOptions(custom: ColorField.new), display: ColorSwatch.new)`. Constructor tear-offs are constant expressions, so they are allowed in annotations. The generated form passes the widget a plain-Flutter contract: the initial value, an `onChanged` callback, the label and the composed `validator`; the detail screen and list tile pass the value. Implement it as a `FieldEmitter` and a `FieldDisplay` in a feature module (`lib/src/features/custom_field/`), per the contract from PF-39.

The reference apps need this for quantities with units and time-range schedules (energy balancing) before M3 adds them as built-in types.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 A field can name a hand-written form widget in its annotation; the create and edit screens use it, prefill it in the edit screen, run the field's validators on its value and pass the value to the entity constructor
- [x] #2 A field can name a hand-written display widget, used by the detail screen and the list tile slots instead of `toString()`
- [x] #3 The contract a custom widget implements (constructor parameters and their types) is a typedef or abstract class in `prefab_flutter_widgets`, documented in `docs/user_guide/field-widgets.md`
- [x] #4 A reference that is not a const constructor or function with the expected signature fails the build with a message naming the field
- [x] #5 The feature lives in its own module with its own test file; a snapshot fixture covers a custom form and display widget
- [x] #6 The example app uses one custom field widget and CI compiles it; changelog fragments added
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
- Annotation: `FormOptions.custom` and `Field.display` (type `Function?`, since `prefab_flutter` is pure Dart). The contract is `PrefabFieldBuilder<T>` / `PrefabDisplayBuilder<T>` in `prefab_flutter_widgets`.
- Module `custom_field`: `CustomFormFieldEmitter` (claims fields through the new `FieldEmitter.claims` hook, listed first in `formFieldEmitters`) and `CustomFieldDisplay` (`FieldDisplay.widget`, used through `fieldValueWidget` by the detail screen and list tile). The reference is read and checked in the manifest (`CustomWidgetRef`).
- Only `Validator.required` is supported with a custom widget; a required field needs a widget with a `validator` parameter. Parameter types are checked by Dart in the generated code, the generator checks parameter names.
- Example app: `Review.quality` with `RatingField` and `RatingStars`.
<!-- SECTION:NOTES:END -->
