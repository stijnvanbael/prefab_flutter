---
id: PF-67
title: Distinguish entities with the same class name in different libraries
status: Done
assignee: []
created_date: '2026-11-20 12:00'
labels: []
dependencies:
  - PF-45
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
`@EntityScreen` and `@EntityAction` are discovered from the unresolved syntax tree (`.prefab_screens.json`, `.prefab_actions.json`), so the entity they target is matched by class name only. Two `@Entity` classes with the same name in different libraries cannot be told apart: the declaration is attached to the wrong entity or to both. Left open after PF-45.

Record the library the name was imported from (the import URI of the identifier, which is visible in the syntax tree) and match on library and name. If a name stays ambiguous, fail the build with a message that names both libraries.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 `@EntityScreen` and `@EntityAction` targets are matched by library and class name
- [x] #2 An ambiguous target fails the build with a message naming the candidate libraries
- [x] #3 Tests cover two `@Entity` classes with the same name in different libraries
- [x] #4 The Known limitations row is removed
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
The summaries now record the import prefix and the imports of the declaring library (`EntityReference`). A declaration targets the entity of its own library, or of the library an import exposes (prefix, `show` and `hide` respected). Entities reached through a barrel file are matched by name when unique in the package; otherwise the build fails naming the libraries. Summaries without the new field still match by name. The example app has no same-named entities, so it is not extended.
<!-- SECTION:NOTES:END -->
