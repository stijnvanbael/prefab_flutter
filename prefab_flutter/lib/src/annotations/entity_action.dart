/// Where a hand-written [EntityAction] appears.
enum ActionPlace {
  /// The AppBar of the generated detail screen. The function receives the
  /// entity that is shown; the action is disabled while it is loading.
  detail,

  /// The AppBar of the generated list screen. The function receives no entity.
  list,

  /// The trailing menu of every list item. The function receives the item.
  item,
}

/// Adds a hand-written action to the generated screens of an entity without
/// promoting them ("Duplicate", "Send invoice", ...).
///
/// Annotate a top-level function anywhere under `lib/`:
///
/// ```dart
/// @EntityAction(Product, label: 'Duplicate', icon: 'copy',
///     on: {ActionPlace.detail, ActionPlace.item})
/// Future<void> duplicateProduct(
///     BuildContext context, WidgetRef ref, Product product) async { ... }
/// ```
///
/// The function takes `(BuildContext, WidgetRef, Entity)` for
/// [ActionPlace.detail] and [ActionPlace.item], and `(BuildContext,
/// WidgetRef)` for [ActionPlace.list]; one action cannot mix the two forms. A
/// function with another signature fails the build.
///
/// The annotation is read without resolving your code, so [entity], [label],
/// [icon], [on] and [order] must be literals.
class EntityAction {
  const EntityAction(
    this.entity, {
    required this.label,
    this.icon,
    this.on = const {ActionPlace.detail},
    this.order = 0,
  });

  /// The `@View` class the action belongs to.
  final Type entity;

  /// Text of the menu entry and tooltip of the icon button.
  final String label;

  /// Name of a member of Flutter's `Icons` class (`'copy'` for `Icons.copy`).
  /// A name instead of an `IconData` keeps this package free of Flutter.
  /// Without it the action shows `Icons.bolt`.
  final String? icon;

  /// The places the action appears in; defaults to the detail screen.
  final Set<ActionPlace> on;

  /// Actions are sorted by [order], then by [label], then by function name.
  final int order;
}
