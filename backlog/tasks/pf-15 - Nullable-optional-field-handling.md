---
id: PF-15
title: Nullable / optional field handling
status: To Do
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
- [ ] #1 FieldManifest exposes an isNullable flag derived from the Dart type
- [ ] #2 Non-nullable fields get a required check automatically, without needing Validator.required; nullable fields are optional unless a required validator is declared
- [ ] #3 _prefillControllers uses null-safe reads for nullable fields (e.g. item.field?.toString() ?? '')
- [ ] #4 Entity construction passes null when a nullable field's input is empty
- [ ] #5 Nullable DateTime, bool and enum fields start as null in generated state; nullable bool uses a tri-state widget or a dropdown with an empty option
- [ ] #6 The detail screen shows a placeholder (e.g. an em dash) for null values instead of 'null'
- [ ] #7 Generated code compiles without warnings for entities that mix nullable and non-nullable fields
<!-- AC:END -->
