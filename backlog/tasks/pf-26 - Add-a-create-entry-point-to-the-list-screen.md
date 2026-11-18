---
id: PF-26
title: Add a create entry point to the list screen
status: To Do
assignee: []
created_date: '2026-11-18 10:00'
updated_date: '2026-11-18 10:00'
labels: []
dependencies:
  - PF-25
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The /create route is generated, but no generated screen links to it, so users cannot reach the create form. Add a FloatingActionButton to the list screen.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 ListScreenGenerator emits a FloatingActionButton that pushes the create route when the entity supports creation
- [ ] #2 For nested entities the button pushes the nested create route
- [ ] #3 The list reloads after returning from the create screen
- [ ] #4 The list screen shows an empty state message when there are no items
- [ ] #5 Generator tests cover the button's presence and absence
<!-- AC:END -->
