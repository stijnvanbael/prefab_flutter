[← User guide](../user_guide.md)

# Generated files

For a source file `product.dart` the generator writes one library,
`product.prefab.dart`. Import that single file to use everything below; it
contains:

| Generated code | Contents |
|---|---|
| `ProductListScreen` | A `ListView` of items (or a "No items found" message when empty); tapping one opens its detail screen. With a `searchable` field it has a `PrefabSearchBar`, with `sortable` fields a `PrefabSortMenu` in the AppBar, and (unless `@View(paged: false)`) a `PrefabPaginationBar` footer. With `@Create`, a floating action button opens the create screen (nested route for nested entities) and the list reloads on return |
| `ProductDetailScreen(id:)` | One `ListTile` per visible field, plus Edit/Delete actions |
| `ProductCreateScreen` | Only with `@Create` |
| `ProductEditScreen(id:)` | Only with `@Update` |
| `productDetailProvider`, `productsProvider`, `ProductsNotifier`, `productApiClientProvider` | `productDetailProvider` (`FutureProvider.autoDispose.family` on the id), `productsProvider` (`AsyncNotifierProvider.autoDispose`) with `ProductsNotifier` (an `AutoDisposeAsyncNotifier<List<Product>>`; nested entities use `AutoDisposeFamilyAsyncNotifier` keyed on the parent id) exposing `setSearch`, `setSort`, `goToPage`, `setPageSize`, `create` (with `@Create`), `updateEntity` (with `@Update`) and `delete` (with `@Delete`) (`updateEntity` and `delete` invalidate the entity's `productDetailProvider` so detail screens refetch), and `productApiClientProvider` |
| `ProductApiClient` | `list` (returns a `PrefabPage<Product>`), `getById`, `delete`, plus `create` (with `@Create`) and `update` (with `@Update`); responses are read with `Product.fromJson` and request bodies are sent as `product.toJson()` |
| `$productRoutes` | Named after the source file; a `List<RouteBase>` with the routes of every entity in the file |

A file without `@View` classes produces no output. The previous layout of six
files per source (`.list_screen.dart`, `.detail_screen.dart`, `.form_screen.dart`,
`.provider.dart`, `.api_client.dart`, `.routes.dart`) was replaced by the single
`.prefab.dart` file (PF-32); delete the old files when migrating.

### JSON serialization requirement

Every `@View` class needs a `fromJson(Map<String, dynamic> json)` factory and a
`toJson()` method; the generated API client uses them instead of casting
`response.data`. The easiest way is `json_serializable`:

```dart
@JsonSerializable()
@View(title: 'Product', path: 'products')
class Product {
  // ...fields...
  factory Product.fromJson(Map<String, dynamic> json) => _$ProductFromJson(json);
  Map<String, dynamic> toJson() => _$ProductToJson(this);
}
```

Add `json_annotation` and `json_serializable` to your `pubspec.yaml` and add
`part 'product.g.dart';`. Hand-written implementations work too. If either is
missing the build fails with an error naming the entity. List responses are
decoded with `(response.data as List).map((e) => Product.fromJson(e as Map<String, dynamic>))`.

Several `@View` classes may live in one source file; their code is combined
in the same generated files.

The edit screen loads the entity through the detail provider and fills the
form fields from it before showing the form.
