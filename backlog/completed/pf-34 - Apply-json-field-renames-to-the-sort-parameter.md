---
id: PF-34
title: Apply JSON field renames to the sort parameter
status: Done
assignee: []
created_date: '2026-11-19 10:00'
labels: []
milestone: m-2
dependencies: []
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The generated list client sends the Dart field name as the `sort` value (`sort=unitPrice`). When the entity uses `json_serializable` with `fieldRename` (class-level `@JsonSerializable(fieldRename: ...)` or a field-level `@JsonKey(name: ...)`), the server knows the field by its JSON name (`unit_price`), so sorting fails. Split off from PF-13, which shipped with this limitation.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 The generator reads `@JsonKey(name:)` and `@JsonSerializable(fieldRename:)` and uses the JSON name as the sort key
- [x] #2 Fields without a rename keep the Dart field name
- [x] #3 Generator tests cover `@JsonKey(name:)`, `FieldRename.snake` and no rename
- [x] #4 The Known limitations row in docs/user_guide.md is removed
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
`FieldManifest.jsonName` is read by name (no `json_annotation` dependency) from `@JsonKey(name:)` and the class-level `@JsonSerializable(fieldRename:)`; the sort menu option ids use it. Tests: `test/json_rename_sort_test.dart`. Search is free text and needs no mapping.
<!-- SECTION:NOTES:END -->
