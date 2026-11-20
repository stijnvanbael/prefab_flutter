import '../../core/artifact.dart';
import '../../core/code.dart';
import '../../core/entity_context.dart';
import '../../core/feature.dart';
import '../../core/library_emitter.dart';
import '../../generators/api_client_generator.dart';
import '../../generators/detail_screen_generator.dart';
import '../../generators/provider_generator.dart';
import '../../generators/routes_generator.dart';
import 'edit_screen_artifact.dart';

/// Updating entities (`@Update`).
///
/// Adds the `{Entity}EditScreen`, the `update` method of the API client, the
/// `updateEntity` method of the list notifier, the Edit button of the detail
/// screen and the `edit` route. Orders used on the shared extension points:
/// 10 on the detail app bar actions and the routes, 20 on the API client
/// methods and 30 on the notifier methods.
class UpdateFeature extends Feature {
  const UpdateFeature();

  static const _name = 'update';

  @override
  String get name => _name;

  @override
  List<ArtifactFactory> get artifacts => const [EditScreenArtifact.create];

  @override
  void contribute(EntityContext entity, ArtifactSet artifacts) {
    final manifest = entity.manifest;
    if (!manifest.hasUpdate) return;
    final id = manifest.entityName;
    final type = manifest.entityName;
    final lower = manifest.entityNameLower;

    final client = artifacts.get<ApiClientArtifact>(ArtifactKind.apiClient, id);
    if (client != null) {
      client.methods.addLazy(
        _name,
        () => Code(
          [
            'Future<$type> update($type $lower${client.parentParamTrailing}) async {',
            "  final response = await _dio.put('${client.urlBase}/\${$lower.${manifest.idFieldName}}', data: $lower.toJson());",
            '  return $type.fromJson(response.data as Map<String, dynamic>);',
            '}',
          ].join('\n'),
        ),
        order: 20,
      );
    }

    final provider =
        artifacts.get<ListProviderArtifact>(ArtifactKind.listProvider, id);
    if (provider != null) {
      provider.methods.addLazy(
        _name,
        () => Code(
          [
            'Future<void> updateEntity($type $lower) async {',
            '  await _client.update($lower${provider.clientTrailing});',
            '  ref.invalidate(${lower}DetailProvider(${provider.detailKeyArgs}));',
            '  await _load();',
            '}',
          ].join('\n'),
        ),
        order: 30,
      );
    }

    final detail =
        artifacts.get<DetailScreenArtifact>(ArtifactKind.detailScreen, id);
    if (detail != null) {
      detail.appBarActions.add(
        _name,
        Code(
          [
            'IconButton(',
            '  icon: const Icon(Icons.edit),',
            "  tooltip: 'Edit',",
            "  onPressed: () => context.push('${entity.paths.editPath(manifest, r'$id')}'),",
            '),',
          ].join('\n'),
          imports: {Libs.goRouter, Libs.materialUi},
        ),
        order: 10,
      );
    }

    final routes = artifacts.get<RoutesArtifact>(
        ArtifactKind.routes, entity.libraryManifests.first.entityName);
    routes?.detailChildRoutes.add(
      _name,
      DetailChildRoute(
        entityName: id,
        path: 'edit',
        className: '${type}EditScreen',
        libraryUri: '',
      ),
      order: 5,
    );
  }
}
