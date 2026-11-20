/// Declares a hand-written screen as a child of an entity.
///
/// Annotate a widget class that takes the entity's id (and the ids of its
/// ancestors, for nested entities) as named constructor parameters:
///
/// ```dart
/// @EntityScreen(Site, path: 'live', title: 'Live')
/// class SiteLiveScreen extends ConsumerWidget {
///   const SiteLiveScreen({super.key, required this.id});
///   final int id;
///   ...
/// }
/// ```
///
/// The generator adds the route `/{entity path}/:id/{path}` under the entity's
/// detail route (passing the typed ids), a link on the entity's detail screen
/// and a `{entity}Breadcrumbs` helper for the screen's app bar. A constructor
/// that does not match fails the build with a message naming the expected
/// parameters. See the user guide ("Routes").
class EntityScreen {
  const EntityScreen(this.entity, {required this.path, this.title});

  /// The entity (a `@View` class) the screen belongs to.
  final Type entity;

  /// The route segment below the entity's detail route, e.g. `live` for
  /// `/sites/:id/live`. Letters, digits, `-` and `_` only; it must not be
  /// `edit` or the path of a nested entity.
  final String path;

  /// Label of the link on the detail screen and last breadcrumb. Defaults to
  /// [path] in sentence case (`study-session` becomes `Study session`).
  final String? title;
}
