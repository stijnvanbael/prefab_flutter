---
id: PF-15
title: Nullable / optional field handling
status: To Do
assignee: []
created_date: '2026-05-03 10:30'
updated_date: '2026-05-03 10:30'
labels: []
dependencies: []
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Fields with nullable Dart types (String?, int?, DateTime?, etc.) are currently treated identically to their non-nullable counterparts. The generator should detect nullability from the Dart type and handle it correctly: do not auto-inject Validator.required for nullable fields, allow controllers and state variables to hold null, and emit safe null-aware reads in _prefillControllers and the entity construction call.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 FieldManifest exposes an isNullable flag derived from the Dart type's nullability
- [ ] #2 Validator.required is not automatically added for nullable fields
- [ ] #3 _prefillControllers uses null-safe reads (e.g. item.field?.toString() ?? '') for nullable fields
- [ ] #4 The entity construction in the save callback passes null when a nullable field's controller is empty
- [ ] #5 Nullable DateTime and bool fields initialise to null rather than a default value in generated state variables
- [ ] #6 Generated code compiles without null-safety warnings for entities that mix nullable and non-nullable fields
<!-- AC:END -->
