[← User guide](../user_guide.md)

# Using generated code from hand-written code

Hand-written screens can build on the generated providers, notifiers, API
clients, screens and routes. The names and signatures below are the **public
API** of generated code: a change to them is a breaking change, announced in
the changelog. A test (`prefab_flutter_generator/test/api_summary_test.dart`)
compares them with checked-in summaries in
`prefab_flutter_generator/test/api/`, so any change shows up in a pull
request. To take over one of these artifacts instead of using it, see
[Promoting generated code](promoting.md), which lists the signatures a promoted
artifact has to keep.

Everything is shown for the entity `Product` (`@View(path: 'products')`).
Collection names are plural (`productsProvider`), single-entity names singular.

## Public names

| Artifact | Name | Signature |
|---|---|---|
| API client | `ProductApiClient` | `ProductApiClient(Dio, [PrefabListAdapter])` |
| | `list` | `Future<PrefabPage<Product>> list({String? search, String? sort, bool descending = false, int page = 0, int? pageSize})` |
| | `getById` | `Future<Product> getById(int id)` |
| | `create` | `Future<Product> create(Product product)` (needs `@Create`) |
| | `update` | `Future<Product> update(Product product)` (needs `@Update`) |
| | `delete` | `Future<void> delete(Product product)` (needs `@Delete`) |
| API client provider | `productApiClientProvider` | `Provider.autoDispose<ProductApiClient>` |
| Detail provider | `productDetailProvider` | `FutureProvider.autoDispose.family<Product, int>`, keyed by the id |
| List provider | `productsProvider` | `AsyncNotifierProvider.autoDispose<ProductsNotifier, PrefabPage<Product>>` |
| List notifier | `ProductsNotifier` | getters `search`, `sort`, `descending`, `page` |
| | `setSearch` | `void setSearch(String query)` (debounced 300 ms, back to page 0) |
| | `setSort` | `Future<void> setSort(String? field, {bool descending = false})` |
| | `goToPage` | `Future<void> goToPage(int page)` (zero-based) |
| | `setPageSize` | `Future<void> setPageSize(int pageSize)` |
| | `create`, `updateEntity`, `delete` | `Future<void> …(Product product)`; reload the list and invalidate the detail provider |
| Screens | `ProductListScreen`, `ProductDetailScreen`, `ProductCreateScreen`, `ProductEditScreen` | `const` constructors with `{super.key}`; the detail and edit screens also take `required int id` |
| Routes | `$productRoutes` | `List<RouteBase> get $productRoutes` (`$<file>Routes`) |

The id type is the entity's id type (`int` or `String`).

### Entities with a `@Parent`

For an `OrderLine` under `Order`, every ancestor id is added:

- Client methods take named `required int orderId` (`getById(int id, {required int orderId})`).
- The detail provider key is a record `(id, orderId)`: `orderLineDetailProvider((id, orderId))`.
- The list provider is a family keyed by the ancestor ids: `orderLinesProvider(orderId)`, and for two levels `orderLineNotesProvider((orderId, orderLineId))`. The notifier adds a getter `orderId`.
- Screens take the ancestor ids as `required` named parameters (`OrderLineListScreen(orderId: …)`).

## Not public API

Everything else in a `*.prefab.dart` file is an implementation detail and may
change at any time: the state classes of form screens (`_ProductCreateScreenState`
and the like, private by name), the fields and private methods of notifiers
(`_load`, `_search`, …), the widgets and layout that screens build, and the
generated `build` bodies. Do not depend on them; [promote](promoting.md) the
artifact instead.

## Example: a hand-written screen

```dart
class ProductSearchScreen extends ConsumerWidget {
  const ProductSearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(productsProvider);
    final notifier = ref.read(productsProvider.notifier);
    return Scaffold(
      appBar: AppBar(
        title: TextField(onChanged: notifier.setSearch),
        actions: [
          IconButton(
            icon: const Icon(Icons.sort_by_alpha),
            onPressed: () => notifier.setSort('name',
                descending: notifier.sort == 'name' && !notifier.descending),
          ),
        ],
      ),
      body: products.when(
        data: (page) => ListView(children: [
          for (final product in page.items)
            ListTile(
              title: Text(product.name),
              onTap: () => context.push('/products/${product.id}'),
              trailing: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => notifier.delete(product),
              ),
            ),
        ]),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
      ),
      bottomNavigationBar: PrefabPaginationBar.controlled(
        page: products.valueOrNull?.page ?? 0,
        totalPages: products.valueOrNull?.totalPages ?? 0,
        onPageChanged: notifier.goToPage,
      ),
    );
  }
}
```

Read a single entity with `ref.watch(productDetailProvider(id))`, call the
client directly with `ref.read(productApiClientProvider).getById(id)`, and
register the generated routes with `GoRouter(routes: $productRoutes)`. The
widgets used above (`PrefabPaginationBar` and others) are described under
[Runtime widgets](runtime-widgets.md).
