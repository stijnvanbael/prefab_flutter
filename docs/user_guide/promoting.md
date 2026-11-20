[← User guide](../user_guide.md)

# Promoting generated code

When one screen, provider or client has to be special, take it over as
ordinary code. The generator stops producing that one artifact and everything
else keeps working with your version; the other artifacts stay generated.

The quickest way is the `promote` command (next section). To do it by hand:

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

## The promote command

```sh
dart run prefab_flutter_generator:promote ProductDetailScreen
dart run build_runner build
```

Run it in the package root. It writes the generated code of that one artifact
to `lib/<folder of the entity>/<snake_name>.dart` (here
`lib/product_detail_screen.dart`), with its imports, the import of the
`.prefab.dart` library, `package:prefab_flutter/prefab_flutter.dart` and
`@Promoted()`. The code is formatted and carries no generated-file banner. The
next `build_runner build` stops generating the artifact and re-exports your
file, so the app compiles and behaves the same.

- `--to lib/screens/product_detail.dart` chooses another file (relative to the
  package root); relative imports are rewritten for the new folder.
- The command refuses to overwrite an existing file.
- The name is the artifact's primary name (table below). An unknown name fails
  with the closest one: `ProductDetailScren is not a generated artifact; did
  you mean ProductDetailScreen?`.
- The command reads the `@Entity` classes under `lib/`, not the generated file,
  so it works before the first `build_runner build` too.

## Actions and screen links

`promote` writes a list or detail screen with the `@EntityAction` calls and the
`@EntityScreen` link tiles the generated screen has at that moment, as plain
code (with the imports of the functions and screens), so the promoted screen
behaves like the one it replaces.

A contribution added after the promotion cannot be written into your file. On
every build the generator warns for each promoted screen that has one, naming
the screen and the contribution:

```
AlphaDetailScreen is @Promoted, so it does not show the action archive
(@EntityAction on Alpha). Add it to AlphaDetailScreen by hand.
```

The generator cannot tell whether your screen already calls the function, so
the warning stays until the screen is no longer promoted.

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
- A wrong signature is not reported by the generator; it is a compile error
  in the generated file that calls the promoted artifact (build-time checks
  are planned in PF-70).
- A promoted list or detail screen does not get actions or `@EntityScreen`
  links added later: the build warns about each one (see below), and you add
  it to the screen by hand.
