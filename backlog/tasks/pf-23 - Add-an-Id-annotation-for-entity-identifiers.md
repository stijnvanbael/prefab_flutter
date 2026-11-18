---
id: PF-23
title: Add an @Id annotation for entity identifiers
status: To Do
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
- [ ] #1 A new @Id annotation is added; when absent, a field named `id` is used; when neither exists the generator emits a build-time error
- [ ] #2 FieldManifest/EntityManifest expose the id field name and Dart type
- [ ] #3 Routes convert the path parameter to the id type (int.parse for int, as-is for String) before passing it to screens
- [ ] #4 Detail providers, screens and API clients use the typed id instead of Object
- [ ] #5 The id field is never shown as an editable form field
- [ ] #6 The user guide documents the id convention
<!-- AC:END -->
