## Unreleased

* **Breaking:** the generated routes getter is no longer called `$prefabRoutes`; it is named after the source file (`product.dart` -> `$productRoutes`, `user_account.dart` -> `$userAccountRoutes`), so several routes files can be imported without name clashes (PF-27).
  **Migration:** rename `$prefabRoutes` in your `GoRouter(routes: ...)` to the new name, and combine several files with `[...$productRoutes, ...$customerRoutes]`.

## 0.1.0

* Initial release.
* Generates detail screens, list screens, form screens, Riverpod providers, Dio API clients, and GoRouter routes from `@View`-annotated Dart classes.
