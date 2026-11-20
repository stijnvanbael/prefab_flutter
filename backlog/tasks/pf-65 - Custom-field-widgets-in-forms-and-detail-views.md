---
id: PF-65
title: Custom field widgets in forms and detail views
status: To Do
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
- [ ] #1 A field can name a hand-written form widget in its annotation; the create and edit screens use it, prefill it in the edit screen, run the field's validators on its value and pass the value to the entity constructor
- [ ] #2 A field can name a hand-written display widget, used by the detail screen and the list tile slots instead of `toString()`
- [ ] #3 The contract a custom widget implements (constructor parameters and their types) is a typedef or abstract class in `prefab_flutter_widgets`, documented in `docs/user_guide/field-widgets.md`
- [ ] #4 A reference that is not a const constructor or function with the expected signature fails the build with a message naming the field
- [ ] #5 The feature lives in its own module with its own test file; a snapshot fixture covers a custom form and display widget
- [ ] #6 The example app uses one custom field widget and CI compiles it; changelog fragments added
<!-- AC:END -->
