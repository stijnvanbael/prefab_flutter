---
id: PF-15
title: Nullable / optional field handling
status: Done
assignee: []
created_date: '2026-05-03 10:30'
updated_date: '2026-11-18 10:00'
labels: []
dependencies: []
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Fields with nullable Dart types (String?, int?, DateTime?, etc.) are treated identically to non-nullable ones: the manifest drops nullability and generated code assumes a value is always present. Use nullability as a signal: non-nullable fields are required by default, nullable fields are optional and round-trip null.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 FieldManifest exposes an isNullable flag derived from the Dart type
- [x] #2 Non-nullable fields get a required check automatically, without needing Validator.required; nullable fields are optional unless a required validator is declared
- [x] #3 _prefillControllers uses null-safe reads for nullable fields (e.g. item.field?.toString() ?? '')
- [x] #5 Nullable DateTime, bool and enum fields start as null in generated state; nullable bool uses a tri-state widget or a dropdown with an empty option
- [x] #6 The detail screen shows a placeholder (e.g. an em dash) for null values instead of 'null'
- [x] #7 Generated code compiles without warnings for entities that mix nullable and non-nullable fields
<!-- AC:END -->

## Implementation Notes

- `FieldManifest.isNullable` / `isRequired` added; form generator requires non-nullable fields, skips other validators on empty optional values, and prefills null-safely. Nullable `bool` is a dropdown (empty/Yes/No); nullable enum dropdown has an empty option.
- Detail screen shows an em dash for nullable `null` values.
- AC#4 (empty nullable input -> `null` in the constructed entity) moved to PF-11 AC#7, since the Save button builds no entity until PF-11. The nullability metadata PF-11 needs is `FieldManifest.isNullable` / `isRequired`.
- AC#7 verified by running the real builders (`build_runner`) on an entity mixing nullable and non-nullable `String`, `int`, `DateTime`, `bool` and enum fields in a scratch Flutter app and running `flutter analyze`: no errors or warnings come from the nullable handling. Two unrelated errors remain in the detail screen output (`itemDetailProvider` and `itemsProvider` are undefined because `item.detail_screen.dart` does not import `item.provider.dart`), plus an unused import in the list screen and `value` deprecations on dropdowns; these predate PF-15.
- Also fixed on the way: `routes_generator.dart` called a non-existent `EntityPaths.parentOf` (main did not compile) and a stale nested-screens test expectation.
