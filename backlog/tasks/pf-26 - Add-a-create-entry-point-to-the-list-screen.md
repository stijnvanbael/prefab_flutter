---
id: PF-26
title: Add a create entry point to the list screen
status: Done
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
- [x] #1 ListScreenGenerator emits a FloatingActionButton that pushes the create route when the entity supports creation
- [x] #2 For nested entities the button pushes the nested create route
- [x] #3 The list reloads after returning from the create screen
- [x] #4 The list screen shows an empty state message when there are no items
- [x] #5 Generator tests cover the button's presence and absence
<!-- AC:END -->

## Implementation Notes

The FAB is emitted only for entities with `@Update` (the create route exists only then). After `context.push` returns, the list provider is invalidated. Empty state text is a generic "No items found".
