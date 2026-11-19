---
id: PF-13
title: Wire search, sort, and pagination into ListScreen
status: Done
assignee: []
created_date: '2026-05-03 10:30'
updated_date: '2026-11-19 10:00'
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
- [x] #1 The server contract above (query parameter names, paged response shape) is implemented as a configurable adapter in prefab_flutter_widgets with the defaults above, and documented in the user guide
- [x] #2 @Field gains searchable (bool, default false) and sortable (bool, default false)
- [x] #3 ListScreenGenerator emits a PrefabSearchBar when at least one field is searchable
- [x] #4 ListScreenGenerator emits a PrefabSortMenu action listing every sortable field
- [x] #5 ListScreenGenerator emits a PrefabPaginationBar footer for paged lists
- [x] #6 The generated list notifier holds search query, sort field, sort direction and page, and reloads when any of them changes; search input is debounced
- [x] #7 ApiClientGenerator's list() accepts optional search, sort and page parameters and returns a PrefabPage
- [x] #8 Generator tests cover the presence and absence of the search bar, sort menu and pagination bar
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
- `PrefabListAdapter` (+ `prefabListAdapterProvider`) in prefab_flutter_widgets holds the contract; a bare JSON array is also accepted as one page.
- `@Field(searchable:, sortable:)` and `@View(paged:)` (default `true`) were added; `paged: false` skips the `page`/`size` parameters and the pagination bar, which is what makes the "absent pagination bar" test case possible.
- `PrefabPaginationBar.controlled` was added so the bar can be driven by the Riverpod notifier.
- Search is sent as free text (`q`); which fields the server searches is the server's decision. `sort` uses the Dart field name (json `fieldRename` is not applied; see Known limitations).
- Generated code was compiled against the runtime packages in a scratch app; there is still no runnable example app (PF-9).
<!-- SECTION:NOTES:END -->
