[← User guide](../user_guide.md)

# REST contract

The generated client expects this API, relative to the Dio base URL. Query parameter names, the page response, the sort encoding and the id encoding come from the **backend adapter** (`PrefabBackend`); the table shows the Prefab preset:

| Method | URL | Body | Response |
|---|---|---|---|
| `list(search:, sort:, descending:, page:, pageSize:)` | `GET /{path}?q=&sort=&page=&size=` | — | a page (see below; a bare JSON array is accepted as a single page) |
| `getById(id)` | `GET /{path}/{id}` | — | entity |
| `create(e)` | `POST /{path}` | the create fields (below) | entity |
| `update(e)` | `PUT /{path}/{e.id}` | the entity without read-only and create-only fields | entity |
| `delete(e)` | `DELETE /{path}/{e.id}` | — | ignored |

### Request bodies

The bodies are the JSON of the entity (`toJson()`), filtered by the model:

- **Create** sends only the fields of the create form and the `@Parent` field.
  The id, `@Field(readOnly: true)` fields, edit-only fields
  (`FormOptions(on: {FormMode.update})`) and un-annotated fields are not in it.
- **Update** sends everything except `@Field(readOnly: true)` fields and
  create-only fields (`FormOptions(on: {FormMode.create})`); the id stays in.

A field in the body is named by its JSON name (`@JsonKey(name:)` or
`fieldRename`). See [Request bodies](annotations.md#request-bodies) for the
full table.

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

### Server validation errors

A failed request is turned into a `PrefabApiError` by
`PrefabBackend.parseError(error)`: the HTTP `status`, a general `message`, the
`fieldErrors` by JSON field name, and the `cause` (the `DioException`). It has
`isNotFound` (404), `isConflict` (409; the edit conflict flow is PF-52) and
`isValidation` (400, 422). An error that is not an HTTP response (no network)
has no status and the text of the error as its message.

The error body is RFC 9457 Problem Details. The presets read:

| | **Prefab** (default) | **Simple** (`PrefabBackend.simple()`) |
|---|---|---|
| General message | `detail`, else `title` | `message`, else `title` |
| Field errors | `errors`: `[{ "field": "price", "message": "must be positive" }]` | same key; both a list of objects and an object `{ "price": "must be positive" }` (a value may be a list of texts) are accepted |

```json
{
  "type": "about:blank",
  "title": "Invalid request",
  "status": 422,
  "detail": "The product is invalid.",
  "errors": [{ "field": "unit_price", "message": "Must be positive" }]
}
```

Other names: `PrefabBackend(errorMessageKey:, errorsKey:, errorFieldKey:,
errorFieldMessageKey:)`, or override `parseError` for a different shape.

In the generated create and edit screens:

* a field error is shown under the matching form field and disappears when
  the user edits that field; every save clears the old errors first;
* the field is matched by its **JSON name**: the `@JsonKey(name:)` value, else
  the `@JsonSerializable(fieldRename:)` applied name, else the Dart name (the
  same rule as the sort parameter). An error for a name the form does not have
  (`warehouse: No capacity`) and the general message appear in a banner above
  the form;
* the screen stays open. Errors without a response (network failure) appear in
  the banner too.

The detail and edit screens show `PrefabTheme.notFoundBuilder` ("Not found"
with a **Back to list** button, which goes to the list route of the entity)
when loading the item answers 404, instead of the raw error. Hand-written
(promoted) screens can do the same with
`ref.read(prefabBackendProvider).parseError(error).isNotFound`. The server
errors widgets `PrefabFormErrors`, `PrefabFieldError` and
`PrefabFormErrorBanner` are public for hand-written forms.

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

Filters (PF-55) will extend the adapter. Error responses are parsed by
`parseError`, see below.

### Migrating from `PrefabListAdapter`

`PrefabListAdapter` and `prefabListAdapterProvider` are deprecated and keep
the previous contract (the Simple preset), so existing overrides still work.
The *default* changed to the Prefab preset: an app that relied on the default
against a plain backend adds
`prefabBackendProvider.overrideWithValue(const PrefabBackend.simple())`.
