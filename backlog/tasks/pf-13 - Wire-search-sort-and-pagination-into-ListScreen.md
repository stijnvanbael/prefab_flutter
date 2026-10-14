---
id: PF-13
title: Wire search, sort, and pagination into ListScreen
status: To Do
assignee: []
created_date: '2026-05-03 10:30'
updated_date: '2026-05-03 10:30'
labels: []
dependencies: []
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
PrefabSearchBar, PrefabSortMenu, and PrefabPaginationBar widgets already exist in prefab_flutter_widgets but are never used in generated list screens. Add searchable and sortable flags to @FormField (or new dedicated annotations), then update ListScreenGenerator and ProviderGenerator to include search/sort/page state, pass those parameters to the API client, and render the three runtime widgets in the generated list screen.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 @FormField gains a searchable parameter (bool, default false) that marks a field for client-side or server-side search
- [ ] #2 @FormField gains a sortable parameter (bool, default false) that marks a field as a sort column
- [ ] #3 ListScreenGenerator emits a PrefabSearchBar in the AppBar when at least one searchable field exists
- [ ] #4 ListScreenGenerator emits a PrefabSortMenu action when at least one sortable field exists
- [ ] #5 ListScreenGenerator emits a PrefabPaginationBar footer when pagination metadata is present
- [ ] #6 ProviderGenerator emits search query, sort column, sort direction, and page index state and passes them to the API client list() call
- [ ] #7 ApiClientGenerator accepts optional search, sort, and page query parameters in the list() method
<!-- AC:END -->
