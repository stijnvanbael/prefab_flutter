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

  const View({required this.title, required this.path});
}
