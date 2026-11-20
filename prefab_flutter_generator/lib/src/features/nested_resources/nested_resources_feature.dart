import '../../core/artifact.dart';
import '../../core/entity_context.dart';
import '../../core/extension_point.dart';
import '../../core/family_key.dart';
import '../../core/feature.dart';
import '../../generators/api_client_generator.dart';
import '../../generators/detail_screen_generator.dart';
import '../../generators/list_screen_generator.dart';
import '../../generators/provider_generator.dart';
import '../../generators/routes_generator.dart';
import '../../manifest/entity_manifest.dart';

/// Entities nested under another with `@Parent` (to any depth).
///
/// Every ancestor id becomes a `familyKey` entry of the API client, the
/// providers and the list and detail screens (so URLs, provider families,
/// constructors and invalidation carry the whole chain), and the routes of a
/// nested entity are added inside its parent's detail route (`childRoutes`)
/// or, when the parent is declared in another library, as top-level routes
/// (`routes`).
class NestedResourcesFeature extends Feature {
  const NestedResourcesFeature();

  static const _name = 'nested_resources';

  @override
  String get name => _name;

  @override
  void contribute(EntityContext entity, ArtifactSet artifacts) {
    final m = entity.manifest;
    final id = m.entityName;
    final ids = [
      for (final a in m.ancestors)
        FamilyId(name: a.paramName, type: a.idType, path: a.path),
    ];
    void addIds(ValuePoint<FamilyId> point) {
      for (var i = 0; i < ids.length; i++) {
        point.add(_name, ids[i], order: i);
      }
    }

    if (ids.isNotEmpty) {
      artifacts
          .get<ApiClientArtifact>(ArtifactKind.apiClient, id)
          ?.let((a) => addIds(a.familyKey));
      artifacts
          .get<DetailProviderArtifact>(ArtifactKind.detailProvider, id)
          ?.let((a) => addIds(a.familyKey));
      artifacts
          .get<ListProviderArtifact>(ArtifactKind.listProvider, id)
          ?.let((a) => addIds(a.familyKey));
      artifacts
          .get<ListScreenArtifact>(ArtifactKind.listScreen, id)
          ?.let((a) => addIds(a.familyKey));
      artifacts
          .get<DetailScreenArtifact>(ArtifactKind.detailScreen, id)
          ?.let((a) => addIds(a.familyKey));
    }

    // The routes of a library are one artifact; contribute once.
    if (m == entity.libraryManifests.first) {
      final routes = artifacts.get<RoutesArtifact>(ArtifactKind.routes, id);
      if (routes != null) _routes(routes, entity.libraryManifests);
    }
  }

  void _routes(RoutesArtifact routes, List<EntityManifest> manifests) {
    routes.screenArguments.add(_name, _routeArguments);
    routes.childRoutes.add(
        _name,
        (parent) => [
              for (final m in manifests)
                // Children of a parent declared in another file cannot be nested
                // inside that file's route tree; they become top-level routes.
                if (m.parentEntityNameLower == parent.entityNameLower &&
                    m.parentInSameLibrary)
                  RouteSpec(m, path: m.path),
            ]);
    for (final m in manifests) {
      if (m.hasParent && !m.parentInSameLibrary) {
        routes.routes.add(
          _name,
          RouteSpec(m,
              path: [
                for (final a in m.ancestors) '/${a.path}/:${a.routeParam}',
                '/',
                m.path,
              ].join()),
        );
      }
    }
  }

  /// Every ancestor id comes from the path parameters of the enclosing routes
  /// (named after the ancestor, so they are unique per level).
  static String _routeArguments(EntityManifest m) => m.ancestors
      .map((a) =>
          "${a.paramName}: ${a.parse("state.pathParameters['${a.routeParam}']!")}")
      .join(', ');
}

extension _Let<T> on T {
  void let(void Function(T value) block) => block(this);
}
