---
id: PF-15
title: Nullable / optional field handling
status: In Progress
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
- [ ] #4 Entity construction passes null when a nullable field's input is empty
- [x] #5 Nullable DateTime, bool and enum fields start as null in generated state; nullable bool uses a tri-state widget or a dropdown with an empty option
- [x] #6 The detail screen shows a placeholder (e.g. an em dash) for null values instead of 'null'
- [ ] #7 Generated code compiles without warnings for entities that mix nullable and non-nullable fields
<!-- AC:END -->

## Implementation Notes

- `FieldManifest.isNullable` / `isRequired` added; form generator requires non-nullable fields, skips other validators on empty optional values, and prefills null-safely. Nullable `bool` is a dropdown (empty/Yes/No); nullable enum dropdown has an empty option.
- Detail screen shows an em dash for nullable `null` values.
- AC#4 is not done: the Save button does not build an entity yet (PF-11). Do it there.
- AC#7: generator output is covered by string tests only; compilation of generated code was not verified.
- Also fixed on the way: `routes_generator.dart` called a non-existent `EntityPaths.parentOf` (main did not compile) and a stale nested-screens test expectation.
