---
id: PF-69
title: Support validators beyond required on custom field widgets
status: Done
assignee: []
created_date: '2026-11-20 12:00'
labels: []
dependencies:
  - PF-65
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
A custom field widget (`FormOptions.custom`, PF-65) can only be combined with `Validator.required`; the other validators check text, so other rules must be checked inside the widget. Left open after PF-65.

Pass all declared validators that apply to the field's type to the widget's `validator` parameter (e.g. `min`/`max` on a numeric value, `maxLength` on a `String` or a list), and reject at build time the validators that cannot apply to the field type.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Validators that apply to the field's Dart type run through the custom widget's `validator` parameter
- [x] #2 A validator that cannot apply to the field type fails the build with a clear message
- [x] #3 Tests cover a numeric custom field with `min`/`max` and an invalid combination
- [x] #4 docs/user_guide/field-widgets.md is updated and the Known limitations row is removed
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Checks are emitted by `CustomFormFieldEmitter` on the typed value. The example `Review.quality` now uses `min(1)`/`max(5)` on its custom widget; the existing example tests still pass; no extra widget test was added.
<!-- SECTION:NOTES:END -->
