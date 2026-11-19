[← User guide](../user_guide.md)

# Routes

For `@View(path: 'products')` with `@Create` and `@Update` (the `create` route needs `@Create`, the `edit` route needs `@Update`):

| Path | Screen |
|---|---|
| `/products` | `ProductListScreen` |
| `/products/create` | `ProductCreateScreen` |
| `/products/:id` | `ProductDetailScreen` |
| `/products/:id/edit` | `ProductEditScreen` |

Register them with:

```dart
GoRouter(routes: $productRoutes)
```

The getter name is derived from the source file name: `product.dart` gives
`$productRoutes`, `user_account.dart` gives `$userAccountRoutes`. Because every
file has a unique name, an app with entities in several source files can import
all the routes files without prefixes and concatenate the lists:

```dart
import 'product.prefab.dart';
import 'customer.prefab.dart';

final router = GoRouter(
  routes: [...$productRoutes, ...$customerRoutes],
);
```
