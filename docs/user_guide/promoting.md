[← User guide](../user_guide.md)

# Promoting generated code

When one screen, provider or client has to be special, take it over as
ordinary code. The generator stops producing that one artifact and everything
else keeps working with your version; the other artifacts stay generated.

1. Copy the artifact from the generated `*.prefab.dart` file into a file of
   your own anywhere under `lib/` (together with the imports it needs).
2. Annotate the declaration with `@Promoted()` from
   `package:prefab_flutter/prefab_flutter.dart` and import the generated file
   (`import 'product.prefab.dart';`) for the artifacts you still use.
3. Run `dart run build_runner build`.

```dart
// lib/product_detail_screen.dart
import 'product.prefab.dart';

@Promoted()
class ProductDetailScreen extends ConsumerWidget {
  final int id;
  const ProductDetailScreen({super.key, required this.id});
  ...
}
```

The generated library then no longer declares `ProductDetailScreen`; it
imports your file and re-exports the name (`export '...' show
ProductDetailScreen;`), so routes, list screens and `main.dart` that import
`product.prefab.dart` compile unchanged. The import cycle between the two
files is fine in Dart. The annotation may also be written `@prefix.Promoted()`.

The name must be the artifact's **primary name** (below). A `@Promoted`
declaration whose name is not a generated artifact fails the build and
suggests the closest one: `@Promoted ProductDetailScren ... is not a generated
artifact; did you mean ProductDetailScreen?`. Promoting an artifact promotes
everything it declares (the notifier of a list provider, the private state
class of a form screen).

## Artifacts and the signature to keep

Generated code refers to your declaration exactly as to the generated one, so
keep the public signature. If you do not, the build reports a compile error
at the generated call site.

| Artifact | Primary name (entity `Product`) | Signature to keep |
|---|---|---|
| API client | `ProductApiClient` | Constructor `(Dio, [PrefabListAdapter])`; `list`, `getById`, `create`, `update`, `delete` as generated (the ones the providers and screens use) |
| API client provider | `productApiClientProvider` | `Provider<ProductApiClient>` |
| Detail provider | `productDetailProvider` | `FutureProvider.autoDispose.family<Product, IdType>` keyed by the entity id |
| List provider | `productsProvider` | `AsyncNotifierProvider<ProductsNotifier, PrefabPage<Product>>`; the notifier keeps the members the list screen uses (search, sort, paging) |
| Detail screen | `ProductDetailScreen` | `const ProductDetailScreen({super.key, required this.id})`; plus the ancestor ids of a `@Parent` chain |
| List screen | `ProductListScreen` | const constructor; ancestor ids of a `@Parent` chain (`orderId`) |
| Create screen | `ProductCreateScreen` | const constructor; ancestor ids |
| Edit screen | `ProductEditScreen` | `id` and ancestor ids |
| Routes | `$productRoutes` (`$<file>Routes`) | `List<RouteBase>` getter |

The `id` parameter has the type of the entity's id (`int` or `String`).

## Limits

- Promotion is per artifact, not per entity; promote each artifact you want.
- The name must be declared at the top level of a file under `lib/` of the
  same package.
- A command that writes an artifact into a file for you is planned in PF-49.
