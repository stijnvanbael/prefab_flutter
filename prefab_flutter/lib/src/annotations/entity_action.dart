import '../enums/place.dart';

/// Adds a hand-written action to the generated screens of an entity without
/// promoting them ("Duplicate", "Send invoice", ...).
///
/// Annotate a top-level function anywhere under `lib/`:
///
/// ```dart
/// @EntityAction(Product, label: 'Duplicate', icon: 'copy',
///     on: {Place.detail, Place.item})
/// Future<void> duplicateProduct(
///     BuildContext context, WidgetRef ref, Product product) async { ... }
/// ```
///
/// The function takes `(BuildContext, WidgetRef, Entity)` for
/// [Place.detail] and [Place.item], and `(BuildContext,
/// WidgetRef)` for [Place.list]; one action cannot mix the two forms. A
/// function with another signature fails the build.
///
/// The annotation is read without resolving your code, so [entity], [label],
/// [icon], [on] and [order] must be literals.
class EntityAction {
  const EntityAction(
    this.entity, {
    required this.label,
    this.icon,
    this.on = const {Place.detail},
    this.order = 0,
  });

  /// The `@Entity` class the action belongs to.
  final Type entity;

  /// Text of the menu entry and tooltip of the icon button.
  final String label;

  /// Name of a member of Flutter's `Icons` class (`'copy'` for `Icons.copy`).
  /// A name instead of an `IconData` keeps this package free of Flutter.
  /// Without it the action shows `Icons.bolt`.
  final String? icon;

  /// The places the action appears in ([Place.list], [Place.item] or
  /// [Place.detail]); defaults to the detail screen.
  final Set<Place> on;

  /// Actions are sorted by [order], then by [label], then by function name.
  final int order;
}
