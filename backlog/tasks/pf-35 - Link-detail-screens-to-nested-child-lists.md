---
id: PF-35
title: Link detail screens to nested child lists
status: To Do
assignee: []
created_date: '2026-11-19 10:00'
labels: []
dependencies: []
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
A parent's detail screen does not link to the lists of its nested (`@Parent`) child entities, so users reach `/products/1/reviews` only by URL or a hand-written link. The detail screen should offer a navigation entry per child entity. Left open after PF-19 (multi-level nesting and breadcrumbs).
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 The detail screen of an entity shows one navigation entry per child entity (`@Parent` pointing at it), labelled with the child's title, that pushes the nested list route
- [ ] #2 Works for children declared in another source file and at every nesting depth
- [ ] #3 Generator tests cover zero, one and several child entities
- [ ] #4 The Known limitations row in docs/user_guide.md is removed
<!-- AC:END -->
