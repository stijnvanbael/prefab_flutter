# prefab_flutter_example

See the [root README](../README.md) and the [user guide](../docs/user_guide.md).

A runnable example for [prefab_flutter](../README.md). It has two annotated
entities and an in-memory mock backend, so no server is needed.

- `lib/product.dart`: a top-level `Product` entity (`@View`, `@Update`, `@Delete`, `@Field`).
- `lib/review.dart`: a nested `Review` entity (`@Parent(Product)`), served under
  `/products/:productId/reviews`.
- `lib/mock_backend.dart`: a Dio `HttpClientAdapter` implementing the REST
  contract of the generated clients in memory. `main.dart` installs it through
  `prefabDioProvider`; replace it with a real `Dio` to talk to a server.
- `test/crud_flow_test.dart`: widget tests that create, edit and delete
  products and reviews through the generated screens.

## Run it

Requires Flutter 3.47 or newer.

```bash
cd prefab_flutter_example
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run -d chrome
```

The app opens on the Products list. Tap **+** to create a product, tap a
product to see its detail screen, then edit or delete it. Reviews are served
under a product: open `/products/1/reviews` (for example by typing the URL in
the browser). The detail screen does not yet link to the nested list.

The generated files (`*.g.dart`, `*.prefab.dart`) are not committed.

## Test it

```bash
dart run build_runner build --delete-conflicting-outputs
flutter analyze --fatal-infos
flutter test
```
