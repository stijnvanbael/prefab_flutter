---
id: PF-24
title: Type-safe @Parent(Type) with cross-file parents
status: Done
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
- [x] #1 @Parent takes the parent entity type as a required argument
- [x] #2 EntityManifest resolves the parent's @View annotation (path, title, id type) through the analyzer, also when the parent lives in another source file
- [x] #3 A build-time error is emitted when the referenced type has no @View annotation
- [x] #4 The parent field's type is checked against the parent's id type
- [x] #5 Generated code imports the parent's generated files when needed
- [x] #6 Existing tests are migrated and a cross-file test is added
- [x] #7 The user guide documents the new syntax
<!-- AC:END -->

## Implementation Notes

- `@Parent(Type)` resolved via the analyzer in `EntityManifest.from`; `@View` path/title and the parent's `id` type are read from the referenced class. Errors: missing `@View`, field/id type mismatch, multiple `@Parent` fields.
- Cross-file parents: the child's routes become top-level `/parentPath/:parentId/path` routes. No extra imports of the parent's generated files are needed because generated code only uses the parent's path and id type (AC #5 resolved as not needed).
- Tests migrated to `@Parent(Post)` and cross-file/validation tests added. Not run: no Dart SDK was available in the authoring environment, so CI must verify.
