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
| `PrefabTheme` | yes (list, detail and form screens) | `ThemeExtension` with the layout decisions of generated screens, see [Theming](#theming) |
| `PrefabBackend` / `prefabBackendProvider` | yes (API client) | Query parameters, page response, sort and id encoding of REST requests; Prefab and Simple presets |

You can use these widgets in hand-written screens too.

## Theming

Generated screens use the ambient Material `Theme` for colours and text. The
layout decisions the templates make are read from `PrefabTheme`, a
`ThemeExtension` you set in `ThemeData.extensions`. Without it the screens use
the defaults below, which are the look they always had.

```dart
MaterialApp.router(
  theme: ThemeData(extensions: [
    PrefabTheme(
      listPadding: const EdgeInsets.symmetric(vertical: 8),
      emptyBuilder: (context) => const Center(child: MyEmptyIllustration()),
      errorBuilder: (context, error, stackTrace) => MyErrorView(error: error),
    ),
  ]),
  routerConfig: router,
)
```

| Property | Default | Used by |
|---|---|---|
| `listPadding` | `EdgeInsets.zero` | Padding of the list in list screens |
| `detailPadding` | `EdgeInsets.all(16)` | Padding of the fields in detail screens |
| `formPadding` | `EdgeInsets.all(16)` | Padding of the fields in create and edit screens |
| `emptyBuilder(context)` | Centered `No items found` | List screens without items |
| `loadingBuilder(context)` | Centered `CircularProgressIndicator` | List, detail and edit screens while loading |
| `errorBuilder(context, error, stackTrace)` | Centered `Error: $error` | List, detail and edit screens when loading failed |
| `detailFieldBuilder(context, label, value)` | `ListTile` with the label as title and the value widget as subtitle | Every field of detail screens |
| `saveButtonBuilder(context, label, onPressed, saving)` | `ElevatedButton`; a small progress indicator while `saving` (`onPressed` is then `null`) | Create and edit screens |

`PrefabTheme` has `copyWith` and `lerp` (paddings interpolate, builders switch
at `t >= 0.5`). `PrefabTheme.of(context)` returns the extension or the
defaults. The default texts are English; localising them is planned in M3.
