---
id: PF-72
title: Theming hook for list items
status: To Do
assignee: []
created_date: '2026-11-20 12:00'
labels: []
dependencies:
  - PF-46
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
`PrefabTheme` (PF-46) customises padding, empty, loading and error states, detail fields and the save button, but not how a list item is laid out. The self-study reference app needs mobile-first card layouts; today that means promoting the whole list screen, which also loses search, sort, paging and item actions.

Add a list item builder to `PrefabTheme` that receives the entity's title, subtitle fields, the item's actions and the tap callback, so an app can render cards instead of `ListTile`s without promoting the screen (principles 3 and 6).
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 `PrefabTheme` has a list item builder with a documented signature; the default renders today's `ListTile`
- [ ] #2 Generated list screens use it, keeping item actions and navigation
- [ ] #3 The example app or a widget test shows a card layout
- [ ] #4 docs/user_guide/runtime-widgets.md describes the hook
<!-- AC:END -->
