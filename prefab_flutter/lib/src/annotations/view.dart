/// Marks a class as a prefab entity and drives all code generation.
///
/// Example:
/// ```dart
/// @View(title: 'Product', path: 'products')
/// class Product { ... }
/// ```
class View {
  /// Human-readable name shown in the AppBar and other UI surfaces.
  final String title;

  /// URL path segment used for routing (e.g. `'products'`).
  final String path;

  /// Whether the list is paged server-side (default `true`). A paged list
  /// sends `page` and `size` query parameters and shows a pagination bar;
  /// with `false` the list is requested in one go and has no pagination bar.
  final bool paged;

  const View({required this.title, required this.path, this.paged = true});
}
