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
  final Map<String, EntityManifest> _byName;

  EntityPaths(Iterable<EntityManifest> manifests)
      : _byName = {for (final m in manifests) m.entityNameLower: m};

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

  /// The parent manifest of [manifest], or null when it has no parent.
  /// Throws when the parent is not declared in the same source file.
  EntityManifest? parentOf(EntityManifest manifest) {
    final name = manifest.parentEntityNameLower;
    if (name == null) return null;
    final parent = _byName[name];
    if (parent == null) {
      throw InvalidGenerationSourceError(
        'Entity "${manifest.entityName}" has a @Parent field referencing '
        '"$name", but no @View-annotated class with that name was '
        'found in the same source file. Define the parent entity in the '
        'same source file as its children.',
      );
    }
    return parent;
  }

  /// Collection path, e.g. `/products` or `/posts/$postId/comments`.
  String collectionPath(EntityManifest manifest) {
    final parent = parentOf(manifest);
    if (parent == null) return '/${manifest.path}';
    return '/${parent.path}/\$${manifest.parentParamName}/${manifest.path}';
  }

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
