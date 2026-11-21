# prefab_flutter_example

See the [root README](../README.md) and the [user guide](../docs/user_guide.md).

A runnable example for [prefab_flutter](../README.md). It has annotated
entities and an in-memory mock backend, so no server is needed.

- `lib/product.dart`: a top-level `Product` entity (`@Entity`, `@Create`, `@Update`, `@Delete`, `@Field`) showing
  search, sort and filters (enum chips, bool, date range, text with autocomplete), validators (`required`, `positive`, `maxLength`), an enum
  dropdown, a multi-line text field kept out of the list (`on: {Place.detail, Place.form}`) and a
  date picker. `sku` is create-only (`FormOptions(on: {FormMode.create})`) and
  `createdAt` is server-set (`@Field(readOnly: true)`): neither is in the other
  form or in the wrong request body (`test/request_shapes_test.dart`).
  Its `@Version` field makes updates optimistically locked: an update of a stale
  version is answered with 409 and the edit screen offers to reload
  (`test/edit_conflict_test.dart`).
  `Product` is also `@Streaming`: the mock backend serves `/products/stream` and
  sends an event for every change, so the list and detail screens update live
  (`test/streaming_test.dart`), and catch up when the stream drops and reconnects (the mock backend can drop its streams and change data silently).
- `lib/report.dart`: a `Report` job entity (PF-57). Its `@JobStatus` field makes list
  items show a progress indicator, a check mark or an error icon, and the detail
  screen start with a banner (with the server's message when the job failed).
  Both refresh every two seconds until the job is final. The mock backend has no
  clock: every read of a running report moves its job on, and a report whose title
  contains "fail" ends failed. `@Update(path: 'regenerate', startsJob: true)` starts
  the job again and opens the report from the list. See `test/job_status_test.dart`.
- `lib/review.dart`: a nested `Review` entity (`@Parent(Product)`), served under
  `/products/:productId/reviews`, with a `numberInput` rating validated with
  `Validator.min` / `Validator.max`.
- `lib/product_stats_screen.dart`: **the reference for hand-written code**. A
  statistics screen declared with `@EntityScreen(Product, path: 'stats')`,
  reached at `/products/:id/stats`. It watches the generated
  `productDetailProvider(id)` and `reviewsProvider(id)` and draws the generated
  `productBreadcrumbs` bar (a `PrefabBreadcrumbBar`). Tested in
  `test/product_stats_screen_test.dart`.
- The generated product list links to the statistics screen from each item's menu (`test/entity_screen_list_link_test.dart`).
- `lib/product_detail_screen.dart`: the promoted (`@Promoted`) detail screen,
  linking to the statistics screen and to the reviews.
- `lib/review_summary_screen.dart`: another `@EntityScreen`, below a nested entity.
- `lib/actions.dart`: hand-written `@EntityAction`s on list and detail screens.
- `lib/reply.dart`: a `Reply` nested one level deeper (`@Parent(Review)`),
  served under `/products/:productId/reviews/:reviewId/replies`; its list and
  detail screens show breadcrumbs back to the review and product.
- `lib/mock_backend.dart`: a Dio `HttpClientAdapter` implementing the REST
  contract of the generated clients in memory. `main.dart` installs it through
  `prefabDioProvider`; replace it with a real `Dio` to talk to a server. It
  speaks the Prefab preset of `PrefabBackend` (Spring paging, `sort=field,desc`),
  which `main.dart` selects explicitly through `prefabBackendProvider`.
- `test/backend_preset_test.dart`: runs the app against that explicit preset.
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

Server validation errors (PF-51): the mock backend rejects a product whose name
is already taken (error on the **Name** field) and a price above 10000 (error
on **Price** plus one for a field the form does not have, shown above the
form). Open `/products/2/reviews/999` for the not-found state.
See `test/server_errors_test.dart`.

Named operations (PF-54): the menu of each product in the list has
**Discontinue** (`@Update(path: 'discontinue', confirm: ...)`, runs after a
confirmation; a second call shows the server's 409 problem in a snack bar) and
**Discount** (`@Update(path: 'discount', parameters: DiscountParameters)`, opens
`/products/:id/discount`, a form with a percent validator; the mock backend
rejects more than 50 percent on an expensive product under the **Percent**
field). See `test/named_operations_test.dart`.

The generated files (`*.g.dart`, `*.prefab.dart`) are not committed.

## Test it

```bash
dart run build_runner build --delete-conflicting-outputs
flutter analyze --fatal-infos
flutter test
```
