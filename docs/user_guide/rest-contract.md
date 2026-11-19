[← User guide](../user_guide.md)

# REST contract

The generated client expects this API, relative to the Dio base URL:

| Method | URL | Body | Response |
|---|---|---|---|
| `list(search:, sort:, descending:, page:, pageSize:)` | `GET /{path}?q=&sort=&page=&size=` | — | `{ "items": [...], "total": n }` (a bare JSON array is accepted as a single page) |
| `getById(id)` | `GET /{path}/{id}` | — | entity |
| `create(e)` | `POST /{path}` | entity | entity |
| `update(e)` | `PUT /{path}/{e.id}` | entity | entity |
| `delete(e)` | `DELETE /{path}/{e.id}` | — | ignored |

After `create`, `update` or `delete` the list notifier reloads the current page
with the current search and sort.

### Search, sorting and pagination

Searching, sorting and paging happen on the **server**; the client only sends
query parameters. The defaults, implemented by `PrefabListAdapter`:

| Query parameter | Meaning |
|---|---|
| `q` | Search text (left out when empty). The server decides which fields it searches; `searchable` only controls whether the list screen shows the search bar |
| `sort` | JSON name of the field, `-` prefix for descending (`price`, `-price`). The JSON name is the `@JsonKey(name:)` value, else the class's `@JsonSerializable(fieldRename:)` applied to the Dart name (`unitPrice` becomes `unit_price` with `FieldRename.snake`), else the Dart name. Left out when unsorted |
| `page` | Zero-based page index (only for `paged` lists) |
| `size` | Page size, default 20 (only for `paged` lists) |

The response is `{ "items": [...], "total": 42 }`; `total` is the number of
items across all pages. A bare JSON array also works and counts as one page.

The generated list notifier holds the search text, sort field, sort direction
and page. Changing any of them reloads the list; typing in the search bar is
debounced (300 ms) and a new search or sort returns to the first page.

To adapt a backend with other names or another response shape, override
`prefabListAdapterProvider` (every generated API client reads it):

```dart
ProviderScope(
  overrides: [
    prefabListAdapterProvider.overrideWithValue(
      const PrefabListAdapter(
        searchParam: 'query',
        sizeParam: 'limit',
        itemsKey: 'data',
        totalKey: 'count',
        defaultPageSize: 50,
      ),
    ),
  ],
  child: const MyApp(),
);
```

Subclass `PrefabListAdapter` and override `queryParameters` / `parsePage` for
anything the constructor parameters cannot express.
