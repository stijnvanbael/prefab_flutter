# prefab_flutter_example

See the [root README](../README.md) and the [user guide](../docs/user_guide.md).

A runnable example for [prefab_flutter](../README.md). It has three annotated
entities and an in-memory mock backend, so no server is needed.

- `lib/product.dart`: a top-level `Product` entity (`@View`, `@Create`, `@Update`, `@Delete`, `@Field`) showing
  search and sort, validators (`required`, `positive`, `maxLength`), an enum
  dropdown, a multi-line text field limited to the detail view (`views`) and a
  date picker.
- `lib/review.dart`: a nested `Review` entity (`@Parent(Product)`), served under
  `/products/:productId/reviews`, with a `numberInput` rating validated with
  `Validator.min` / `Validator.max`.
- `lib/product_stats_screen.dart`: **the reference for hand-written code**. A
  statistics screen declared with `@EntityScreen(Product, path: 'stats')`,
  reached at `/products/:id/stats`. It watches the generated
  `productDetailProvider(id)` and `reviewsProvider(id)` and draws the generated
  `productBreadcrumbs` bar (a `PrefabBreadcrumbBar`). Tested in
  `test/product_stats_screen_test.dart`.
- `lib/product_detail_screen.dart`: the promoted (`@Promoted`) detail screen,
  linking to the statistics screen and to the reviews.
- `lib/review_summary_screen.dart`: another `@EntityScreen`, below a nested entity.
- `lib/actions.dart`: hand-written `@EntityAction`s on list and detail screens.
- `lib/reply.dart`: a `Reply` nested one level deeper (`@Parent(Review)`),
  served under `/products/:productId/reviews/:reviewId/replies`; its list and
  detail screens show breadcrumbs back to the review and product.
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
the browser) or from the **Reviews** tile of the product detail screen.

The generated files (`*.g.dart`, `*.prefab.dart`) are not committed.

## Test it

```bash
dart run build_runner build --delete-conflicting-outputs
flutter analyze --fatal-infos
flutter test
```
