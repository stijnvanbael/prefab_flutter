import 'code.dart';

/// The kinds of artifact the generator emits; one value per promotable unit.
enum ArtifactKind {
  apiClient,
  detailProvider,
  listProvider,
  apiClientProvider,
  detailScreen,
  listScreen,
  createScreen,
  editScreen,
  operationScreen,
  routes,
  breadcrumbs,
}

/// Identifies one artifact: its kind and the entity it belongs to (for
/// [ArtifactKind.routes], which is one per library, the first entity).
class ArtifactId {
  const ArtifactId(this.kind, this.entity);

  final ArtifactKind kind;
  final String entity;

  @override
  bool operator ==(Object other) =>
      other is ArtifactId && other.kind == kind && other.entity == entity;

  @override
  int get hashCode => Object.hash(kind, entity);

  @override
  String toString() => '${kind.name}($entity)';
}

/// One independently emitted, independently promotable unit of generated
/// code, such as `ProductDetailScreen`.
abstract class Artifact {
  ArtifactId get id;

  /// The top-level name a developer promotes; the generator skips this
  /// artifact when a promoted declaration has this name.
  String get primaryName;

  /// Every top-level name the artifact declares (e.g. a provider and its
  /// notifier class). All of them disappear when the artifact is promoted.
  List<String> get declaredNames => [primaryName];

  /// Renders the artifact after all features have contributed to its
  /// extension points. The text carries no leading or trailing blank lines.
  Code emit();
}
