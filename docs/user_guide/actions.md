[← User guide](../user_guide.md)

# Actions

Business apps need more than Edit and Delete ("Duplicate", "Send invoice").
Add a hand-written action to the generated screens with `@EntityAction`,
without [promoting](promoting.md) them. Annotate a top-level function anywhere
under `lib/`:

```dart
@EntityAction(Product, label: 'Duplicate', icon: 'copy',
    on: {ActionPlace.detail, ActionPlace.item})
Future<void> duplicateProduct(
    BuildContext context, WidgetRef ref, Product product) async {
  await ref.read(productsProvider.notifier).create(
      Product(name: '${product.name} (copy)', price: product.price, inStock: true));
}

@EntityAction(Product, label: 'Refresh', icon: 'refresh',
    on: {ActionPlace.list})
void refreshProducts(BuildContext context, WidgetRef ref) =>
    ref.invalidate(productsProvider);
```

| Parameter | Meaning |
|---|---|
| first argument | The `@View` class the action belongs to |
| `label` (required) | Menu text and tooltip |
| `icon` | Name of a member of Flutter's `Icons` as a string (`'copy'` for `Icons.copy`); the annotation package has no Flutter dependency. Default `Icons.bolt` |
| `on` | A set of places, default `{ActionPlace.detail}` |
| `order` | Sort key, default `0` |

All arguments must be literals: the annotation is read from the syntax tree,
without resolving your code (like `@Promoted`).

## Places and signatures

| `ActionPlace` | Where | Function signature |
|---|---|---|
| `detail` | AppBar of the detail screen, after Edit and Delete | `(BuildContext, WidgetRef, Product)`; disabled while the product is loading |
| `item` | Trailing menu of every list item | `(BuildContext, WidgetRef, Product)` |
| `list` | AppBar of the list screen | `(BuildContext, WidgetRef)` |

One action cannot be on `list` and on `detail` or `item`, because the
signatures differ; write two functions. Parameters must be required
positional with exactly these types. A function with another signature, a
private function, a non-literal argument or an unknown entity fails the build,
for example `@EntityAction on duplicateProduct (package:app/actions.dart):
expected the parameters (BuildContext, WidgetRef, Product) but found
(BuildContext, Product)`.

## Rendering and order

Actions of one place are sorted by `order`, then by `label` (case-insensitive),
then by function name. In an AppBar (detail screen, list screen) the first two
are icon buttons with the label as tooltip and the rest are entries of one
overflow menu (`PopupMenuButton`) after them. Edit and Delete of the detail
screen always come first and do not count. Item actions are entries of a menu
at the end of each list tile; the third field of the list view is shown in
front of the menu button.

## Refreshing after an action

The function gets a `WidgetRef`; refresh what it changed with the generated
providers:

```dart
ref.invalidate(productsProvider);          // the list (nested: productsProvider(parentId))
ref.invalidate(productDetailProvider(id)); // one detail screen
```

The list notifier methods (`create`, `delete`, ...) already refresh the list.

## When nothing is added

An action is only added to a screen that is generated. If the detail or list
screen is [promoted](promoting.md), its actions are skipped without a message;
call the function from your own screen. The `promote` command does not copy
actions into the promoted file (the screen then has no actions until you add
them).
