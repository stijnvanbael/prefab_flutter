---
id: PF-24
title: Type-safe @Parent(Type) with cross-file parents
status: To Do
assignee: []
created_date: '2026-11-18 10:00'
updated_date: '2026-11-18 10:00'
labels: []
dependencies:
  - PF-23
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The parent entity is currently derived from the field name by stripping an `Id` suffix (postId -> post) and must be declared in the same source file as the child. Make the reference explicit and type-safe: @Parent(Post).
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 @Parent takes the parent entity type as a required argument
- [ ] #2 EntityManifest resolves the parent's @View annotation (path, title, id type) through the analyzer, also when the parent lives in another source file
- [ ] #3 A build-time error is emitted when the referenced type has no @View annotation
- [ ] #4 The parent field's type is checked against the parent's id type
- [ ] #5 Generated code imports the parent's generated files when needed
- [ ] #6 Existing tests are migrated and a cross-file test is added
- [ ] #7 The user guide documents the new syntax
<!-- AC:END -->
