import 'package:analyzer/dart/element/element.dart';
import 'package:prefab_flutter/prefab_flutter.dart';
import 'package:source_gen/source_gen.dart';

import 'entity_manifest.dart';

const _viewChecker = TypeChecker.fromRuntime(View);

/// Builds navigation paths for entities in one place, so list, detail, form
/// and routes generation agree on nested (`@Parent`) URLs.
///
/// Returned strings are Dart string-literal contents (without quotes) that may
/// contain interpolations such as `$postId`.
class EntityPaths {
  /// The parent's path and id are resolved by [EntityManifest], so the
  /// manifests are only accepted for API stability.
  const EntityPaths(Iterable<EntityManifest> manifests);

  /// Collects the manifests of every [@View] class in [element]'s library.
  factory EntityPaths.forLibraryOf(Element element) {
    final manifests = <EntityManifest>[];
    for (final a
        in LibraryReader(element.library!).annotatedWith(_viewChecker)) {
      final e = a.element;
      if (e is ClassElement) {
        manifests.add(EntityManifest.from(e, a.annotation));
      }
    }
    return EntityPaths(manifests);
  }

  /// Collection path, e.g. `/products`, `/posts/$postId/comments` or
  /// `/orders/$orderId/lines/$orderLineId/notes`.
  String collectionPath(EntityManifest manifest) {
    return [
      for (final a in manifest.ancestors) '/${a.path}/\$${a.paramName}',
      '/${manifest.path}',
    ].join();
  }

  /// Item path of the ancestor at [index] of [manifest]'s chain, e.g.
  /// `/orders/$orderId/lines/$orderLineId`.
  static String ancestorPath(EntityManifest manifest, int index) => [
        for (final a in manifest.ancestors.take(index + 1))
          '/${a.path}/\$${a.paramName}',
      ].join();

  /// Item path for the id expression [idExpr] (e.g. `$id` or `${c.id}`).
  String itemPath(EntityManifest manifest, String idExpr) =>
      '${collectionPath(manifest)}/$idExpr';

  /// Edit path for the id expression [idExpr].
  String editPath(EntityManifest manifest, String idExpr) =>
      '${itemPath(manifest, idExpr)}/edit';

  /// Create path.
  String createPath(EntityManifest manifest) =>
      '${collectionPath(manifest)}/create';
}
