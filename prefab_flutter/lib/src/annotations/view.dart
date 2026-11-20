/// Marks a class as a prefab entity and drives all code generation.
///
/// Example:
/// ```dart
/// @View()
/// class Product { ... }
///
/// @View(title: 'Product', path: 'products') // explicit, same result
/// class Product { ... }
/// ```
class View {
  /// Human-readable name shown in the AppBar and other UI surfaces. Defaults
  /// to the class name in title case (`ProductOrder` → `Product Order`).
  final String? title;

  /// URL path segment used for routing. Defaults to the kebab-case plural of
  /// the class name: `ProductOrder` → `product-orders`. The last word is
  /// pluralised with a small rule: consonant + `y` → `ies` (`Category` →
  /// `categories`); ending in `s`, `x`, `z`, `ch` or `sh` → `es` (`Box` →
  /// `boxes`); otherwise `s` is appended. Irregular plurals (`Person`) need an
  /// explicit path.
  final String? path;

  /// Whether the list is paged server-side (default `true`). A paged list
  /// sends `page` and `size` query parameters and shows a pagination bar;
  /// with `false` the list is requested in one go and has no pagination bar.
  final bool paged;

  const View({this.title, this.path, this.paged = true});
}
