[← User guide](../user_guide.md)

# Routes

For `@Entity(path: 'products')` with `@Create` and `@Update` (the `create` route needs `@Create`, the `edit` route needs `@Update`):

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

## Hand-written screens below an entity

Some screens belong to an entity but are too specific to generate: live energy
flow of a site, a study session of a course. Declare them with
`@EntityScreen(Entity, path: ..., title: ...)` on a widget class whose
constructor takes the entity's id (and the ids of its ancestors, for nested
entities) as named parameters:

```dart
@EntityScreen(Site, path: 'live', title: 'Live')
class SiteLiveScreen extends ConsumerWidget {
  const SiteLiveScreen({super.key, required this.id});
  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
        appBar: AppBar(
          title: const Text('Live'),
          bottom: siteBreadcrumbs(context, ref, title: 'Live', id: id),
        ),
        body: ...,
      );
}
```

The class may be anywhere under `lib/`; the declaring file does not have to be
the entity's file. The generator then

- adds `GoRoute(path: 'live', ...)` below the detail route, so the screen is
  reached at `/sites/:id/live`; the route passes `id` and, for an entity with a
  `@Parent`, every ancestor id as named arguments, converted to the id types
  like the generated screens do (`/orders/:orderId/lines/:id/picking` passes
  `id` and `orderId`);
- adds a tile with the `title` to the entity's detail screen (not when the
  detail screen is [promoted](promoting.md)) that opens the screen;
- adds an entry with the `title` to the item menu of the list screen (not when
  the list screen is promoted), one per screen, with the item's id and its
  ancestor ids in the route. The entries come before the
  [`@EntityAction`s](annotations.md) of `Place.item` and look like them;
- generates `siteBreadcrumbs(context, ref, {title, id, ...ancestor ids})`, which
  returns the breadcrumb bar of the generated screens: the ancestors, the
  entity (labelled with its first visible field) and `title`. Use it as
  `AppBar.bottom`. It is a generated artifact like the others and can be
  [promoted](promoting.md).

| Parameter | Meaning |
|---|---|
| entity (first argument) | The `@Entity` class the screen belongs to |
| `path` | One route segment (letters, digits, `-`, `_`); not `edit` and not the path of a nested entity |
| `title` | Label of the link and last breadcrumb; defaults to `path` in sentence case (`study-session` gives `Study session`) |

The build fails with a readable message when the constructor does not fit:
a missing or positional `id` or ancestor id parameter, a different id type, a
required parameter the route cannot pass, a path that is already taken, or an
entity that is not an `@Entity` class (with a "did you mean" hint). Optional
parameters such as `super.key` are fine.

The declarations are found without resolving generated code, through a
`prefab_declarations` builder that writes a small `.prefab_declarations.json`
next to each file with an `@EntityScreen` (like `@Promoted`, see [Promoting generated
code](promoting.md)).
