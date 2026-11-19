## Unreleased

* Generated list providers now use `AsyncNotifierProvider.autoDispose` with `AutoDisposeAsyncNotifier` / `AutoDisposeFamilyAsyncNotifier` instead of the legacy `StateNotifier`; the provider names and the `create`/`update`/`delete` methods are unchanged. Supported `flutter_riverpod`: `>=2.5.0 <3.0.0` (PF-29).
* Fix a compile error in the routes generator and a stale nested-screens test left by merging PF-24 and PF-25.
* **Breaking:** the generated routes getter is no longer called `$prefabRoutes`; it is named after the source file (`product.dart` -> `$productRoutes`, `user_account.dart` -> `$userAccountRoutes`), so several routes files can be imported without name clashes (PF-27).
  **Migration:** rename `$prefabRoutes` in your `GoRouter(routes: ...)` to the new name, and combine several files with `[...$productRoutes, ...$customerRoutes]`.
* Fix nested (`@Parent`) entities: create/edit screens take the parent id, the edit screen uses the `(id, parentId)` detail provider, and detail Edit/Delete use nested paths and the family list provider (PF-25).
* Routes generation now fails with a clear error when a `@Parent` entity's parent is not in the same source file, instead of silently omitting its routes (PF-25).
* Detail and form screen generators now support several `@View` classes in one source file.

## 0.1.0

* Initial release.
* Generates detail screens, list screens, form screens, Riverpod providers, Dio API clients, and GoRouter routes from `@View`-annotated Dart classes.
