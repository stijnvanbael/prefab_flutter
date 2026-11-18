---
id: PF-1
title: Implement runtime widgets library
status: Done
assignee: []
created_date: '2026-05-02 06:03'
updated_date: '2026-11-18 10:00'
labels: []
dependencies: []
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The generated code references PrefabPage, PrefabSearchBar, PrefabPaginationBar, PrefabDeleteDialog and PrefabSortMenu but these do not exist. A prefab_flutter_widgets package (or a runtime section in prefab_flutter) must provide these widgets so generated code compiles and runs.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 PrefabPage<T> model class with items list and pagination metadata
- [x] #2 PrefabSearchBar widget with onChanged callback
- [ ] #3 PrefabPaginationBar widget connected to the list notifier
- [x] #4 PrefabDeleteDialog<T> confirmation dialog
- [x] #5 PrefabSortMenu<T> sort menu widget
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
All widgets are implemented and exported from prefab_flutter_widgets. AC #3 (pagination bar connected to the list notifier) is not met: generated list screens do not use any of these widgets yet. That wiring moved to PF-13.
<!-- SECTION:NOTES:END -->
