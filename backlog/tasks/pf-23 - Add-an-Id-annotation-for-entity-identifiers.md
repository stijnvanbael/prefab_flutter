---
id: PF-23
title: Add an @Id annotation for entity identifiers
status: Done
assignee: []
created_date: '2026-11-18 10:00'
updated_date: '2026-11-18 10:00'
labels: []
dependencies: []
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Every generator hard-codes `.id` as the identifier, and its type is never checked: routes pass a String path parameter, providers key on Object, and the entity may use int. Make the identifier explicit and typed.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 A new @Id annotation is added; when absent, a field named `id` is used; when neither exists the generator emits a build-time error
- [x] #2 FieldManifest/EntityManifest expose the id field name and Dart type
- [x] #3 Routes convert the path parameter to the id type (int.parse for int, as-is for String) before passing it to screens
- [x] #4 Detail providers, screens and API clients use the typed id instead of Object
- [x] #5 The id field is never shown as an editable form field
- [x] #6 The user guide documents the id convention
<!-- AC:END -->

## Implementation Notes

- `@Id` in `prefab_flutter`; `EntityManifest` exposes `idFieldName`/`idType` (FieldManifest unchanged: the id field is excluded from `fields`, so it is never a form/detail field).
- Generators and routes use the typed id; parent path params are converted by the parent field's type too.
- Tests updated and `id_annotation_test.dart` added; not run locally (no Dart SDK in this environment) — rely on CI.
- Not changed: edit screen of a nested entity still takes only `id` (existing limitation, PF-25).
