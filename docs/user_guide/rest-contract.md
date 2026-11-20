[← User guide](../user_guide.md)

# REST contract

The generated client expects this API, relative to the Dio base URL. Query parameter names, the page response, the sort encoding and the id encoding come from the **backend adapter** (`PrefabBackend`); the table shows the Prefab preset:

| Method | URL | Body | Response |
|---|---|---|---|
| `list(search:, sort:, descending:, page:, pageSize:)` | `GET /{path}?q=&sort=&page=&size=` | — | a page (see below; a bare JSON array is accepted as a single page) |
| `getById(id)` | `GET /{path}/{id}` | — | entity |
| `create(e)` | `POST /{path}` | entity | entity |
| `update(e)` | `PUT /{path}/{e.id}` | entity | entity |
| `delete(e)` | `DELETE /{path}/{e.id}` | — | ignored |

After `create`, `update` or `delete` the list notifier reloads the current page
with the current search and sort.

### Search, sorting and pagination

Searching, sorting and paging happen on the **server**; the client only sends
query parameters. `PrefabBackend` owns them, with two presets:

| | **Prefab** (default, `PrefabBackend()`) | **Simple** (`PrefabBackend.simple()`) |
|---|---|---|
| Search | `q` (left out when empty) | `q` |
| Sort | `sort=price,asc` / `sort=price,desc` | `sort=price` / `sort=-price` |
| Paging (only for `paged` lists) | `page` (zero-based), `size` (default 20) | same |
| Response | Spring `PagedModel`: `{ "content": [...], "page": { "number": 0, "totalElements": 42 } }` | `{ "items": [...], "total": 42 }` |
| Ids in URLs | URL-encoded path segment (`Reference<T>` strings or numbers) | same |

A bare JSON array is accepted by both and counts as one page. The server
decides which fields `q` searches; `searchable` only controls whether the list
screen shows the search bar. The sort field is the JSON name: the
`@JsonKey(name:)` value, else the class's `@JsonSerializable(fieldRename:)`
applied to the Dart name (`unitPrice` becomes `unit_price` with
`FieldRename.snake`), else the Dart name.

The generated list notifier holds the search text, sort field, sort direction
and page. Changing any of them reloads the list; typing in the search bar is
debounced (300 ms) and a new search or sort returns to the first page.

### Choosing a preset or writing a custom adapter

Every generated API client reads `prefabBackendProvider`; it defaults to the
Prefab preset. Override it for another backend:

```dart
ProviderScope(
  overrides: [
    // A plain backend with today's `{ items, total }` contract:
    prefabBackendProvider.overrideWithValue(const PrefabBackend.simple()),
    // ...or other names and keys (dotted paths read nested values):
    // prefabBackendProvider.overrideWithValue(const PrefabBackend(
    //   searchParam: 'query',
    //   sizeParam: 'limit',
    //   sortFormat: PrefabSortFormat.minusPrefix,
    //   itemsKey: 'data',
    //   totalKey: 'meta.count',
    //   pageKey: null,
    //   defaultPageSize: 50,
    // )),
  ],
  child: const MyApp(),
);
```

For anything the constructor parameters cannot express, subclass
`PrefabBackend` and override `queryParameters` (request side), `parsePage`
(response side) or `encodeId` (id in the URL).

Parsing of error responses is not part of the adapter yet (planned in PF-51);
filters (PF-55) will extend it.

### Migrating from `PrefabListAdapter`

`PrefabListAdapter` and `prefabListAdapterProvider` are deprecated and keep
the previous contract (the Simple preset), so existing overrides still work.
The *default* changed to the Prefab preset: an app that relied on the default
against a plain backend adds
`prefabBackendProvider.overrideWithValue(const PrefabBackend.simple())`.
