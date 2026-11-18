---
id: PF-13
title: Wire search, sort, and pagination into ListScreen
status: To Do
assignee: []
created_date: '2026-05-03 10:30'
updated_date: '2026-11-18 10:00'
labels: []
dependencies:
  - PF-12
  - PF-29
  - PF-30
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
PrefabSearchBar, PrefabSortMenu, PrefabPaginationBar and PrefabPage exist in prefab_flutter_widgets but generated list screens use none of them. Add searchable and sortable flags to @Field (PF-30), then update the list screen, provider and API client generators.

Before implementing, define the server contract, because the blueprint previously left it open:
- search, sort and pagination happen on the server; the client sends query parameters;
- the default query parameter names are `q`, `sort` (`field` or `-field` for descending), `page` (zero-based) and `size`;
- the default response shape for a paged list is `{ items: [...], total: n }`;
- both are configurable through a single adapter so non-matching backends can plug in their own mapping.

This absorbs PF-1 AC #3 (pagination bar connected to the list state) and PF-7 AC #1-2 (tests for search and sort).
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 The server contract above (query parameter names, paged response shape) is implemented as a configurable adapter in prefab_flutter_widgets with the defaults above, and documented in the user guide
- [ ] #2 @Field gains searchable (bool, default false) and sortable (bool, default false)
- [ ] #3 ListScreenGenerator emits a PrefabSearchBar when at least one field is searchable
- [ ] #4 ListScreenGenerator emits a PrefabSortMenu action listing every sortable field
- [ ] #5 ListScreenGenerator emits a PrefabPaginationBar footer for paged lists
- [ ] #6 The generated list notifier holds search query, sort field, sort direction and page, and reloads when any of them changes; search input is debounced
- [ ] #7 ApiClientGenerator's list() accepts optional search, sort and page parameters and returns a PrefabPage
- [ ] #8 Generator tests cover the presence and absence of the search bar, sort menu and pagination bar
<!-- AC:END -->
