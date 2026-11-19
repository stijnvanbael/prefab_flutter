## Unreleased

* **Breaking:** generated list screens, notifiers and API clients are search, sort and pagination aware: `ApiClient.list(...)` returns a `PrefabPage<Entity>`, `EntitysNotifier` is an `AutoDisposeAsyncNotifier<PrefabPage<Entity>>` with `setSearch`, `setSort`, `goToPage` and `setPageSize`, and list screens get a search bar, sort menu and pagination bar. The server must answer `{ items, total }` (a bare array still works); override `prefabListAdapterProvider` to adapt other backends (PF-13).

* **Breaking:** the generated form screens now save: they build the entity through its unnamed constructor and call the provider's `create()`/`update()`. The id (and any field not on the form) must be nullable, optional or have a default, otherwise the build fails naming the parameter (PF-11).

* **Breaking:** the six generated files per source (`.detail_screen.dart`, `.list_screen.dart`, `.form_screen.dart`, `.provider.dart`, `.api_client.dart`, `.routes.dart`) are replaced by a single `.prefab.dart` library, produced by one builder (`prefabBuilder`); the generated files no longer import each other (PF-32).
  **Migration:** delete the old generated files, import `x.prefab.dart` instead of `x.routes.dart`, and re-run `dart run build_runner build --delete-conflicting-outputs`.
* Generated list providers now use `AsyncNotifierProvider.autoDispose` with `AutoDisposeAsyncNotifier` / `AutoDisposeFamilyAsyncNotifier` instead of the legacy `StateNotifier`; the provider names and the `create`/`update`/`delete` methods are unchanged. Supported `flutter_riverpod`: `>=2.5.0 <3.0.0` (PF-29).
* Fix a compile error in the routes generator and a stale nested-screens test left by merging PF-24 and PF-25.
* **Breaking:** generated API clients deserialize responses with `Entity.fromJson(Map<String, dynamic>)` and send `entity.toJson()` as the request body instead of casting `response.data`. Entities need a `fromJson` factory and a `toJson()` method (e.g. via `json_serializable`); the build fails with an error naming the entity when either is missing (PF-12).
* **Breaking:** the generated routes getter is no longer called `$prefabRoutes`; it is named after the source file (`product.dart` -> `$productRoutes`, `user_account.dart` -> `$userAccountRoutes`), so several routes files can be imported without name clashes (PF-27).
  **Migration:** rename `$prefabRoutes` in your `GoRouter(routes: ...)` to the new name, and combine several files with `[...$productRoutes, ...$customerRoutes]`.
* Fix nested (`@Parent`) entities: create/edit screens take the parent id, the edit screen uses the `(id, parentId)` detail provider, and detail Edit/Delete use nested paths and the family list provider (PF-25).
* Routes generation now fails with a clear error when a `@Parent` entity's parent is not in the same source file, instead of silently omitting its routes (PF-25).
* Detail and form screen generators now support several `@View` classes in one source file.

## 0.1.0

* Initial release.
* Generates detail screens, list screens, form screens, Riverpod providers, Dio API clients, and GoRouter routes from `@View`-annotated Dart classes.
