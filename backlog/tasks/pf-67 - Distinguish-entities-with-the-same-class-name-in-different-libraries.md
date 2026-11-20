---
id: PF-67
title: Distinguish entities with the same class name in different libraries
status: To Do
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
- [ ] #1 `@EntityScreen` and `@EntityAction` targets are matched by library and class name
- [ ] #2 An ambiguous target fails the build with a message naming the candidate libraries
- [ ] #3 Tests cover two `@Entity` classes with the same name in different libraries
- [ ] #4 The Known limitations row is removed
<!-- AC:END -->
