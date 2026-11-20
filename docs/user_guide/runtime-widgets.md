[← User guide](../user_guide.md)

# Runtime widgets

`package:prefab_flutter_widgets/prefab_flutter_widgets.dart` exports:

| Widget / class | Used by generated code | Purpose |
|---|---|---|
| `showPrefabDeleteDialog` / `PrefabDeleteDialog<T>` | yes (detail screen) | Delete confirmation; returns `true` when the item was deleted |
| `PrefabSearchBar` | yes (list screen) | Search text field with an `onChanged` callback |
| `PrefabSortMenu<T>` / `PrefabSortOption<T>` | yes (list screen) | Popup menu to choose a sort option |
| `PrefabBreadcrumbBar` / `PrefabBreadcrumb` | yes (list and detail screens of entities with two or more ancestors) | Single-line breadcrumb row for `AppBar.bottom` with tappable ancestor steps |
| `PrefabPaginationBar` / `PrefabPageNotifier` | yes (list screen, via `PrefabPaginationBar.controlled`) | First/previous/next/last page controls |
| `PrefabPage<T>` | yes (API client, notifier, list screen) | A page of items with total count and page metadata |
| `PrefabListAdapter` / `prefabListAdapterProvider` | yes (API client) | Query parameter names and response shape of list requests |

You can use these widgets in hand-written screens too.
