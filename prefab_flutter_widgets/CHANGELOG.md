## Unreleased

* Fix `PrefabSortMenu` crashing (and overflowing in an AppBar) once an option was selected: it now always shows the sort icon, with the selected option in the tooltip (PF-13).
* Add `PrefabListAdapter` and `prefabListAdapterProvider` (query parameters `q`, `sort`, `page`, `size`; `{ items, total }` responses) and `PrefabPaginationBar.controlled` (PF-13).
* Add `prefabDioProvider`, the `Dio` instance used by generated API clients (PF-22).

## 0.1.0

* Initial release.
* Widgets: `PrefabPage`, `PrefabSearchBar`, `PrefabPaginationBar`, `PrefabDeleteDialog`, `PrefabSortMenu`.
