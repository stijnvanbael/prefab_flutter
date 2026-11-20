import '../../core/artifact.dart';
import '../../core/code.dart';
import '../../core/entity_context.dart';
import '../../core/feature.dart';
import '../../core/library_emitter.dart';
import '../../generators/api_client_generator.dart';
import '../../generators/list_screen_generator.dart';
import '../../generators/provider_generator.dart';
import '../../generators/routes_generator.dart';
import 'create_screen_artifact.dart';

/// Creating entities (`@Create`).
///
/// Adds the `{Entity}CreateScreen`, the `create` method of the API client and
/// of the list notifier, the create button of the list screen and the
/// `create` route. Orders used on the shared extension points: 10 on the
/// floating action button and the routes, 10 on the API client methods and
/// 20 on the notifier methods.
class CreateFeature extends Feature {
  const CreateFeature();

  static const _name = 'create';

  @override
  String get name => _name;

  @override
  List<ArtifactFactory> get artifacts => const [CreateScreenArtifact.create];

  @override
  void contribute(EntityContext entity, ArtifactSet artifacts) {
    final manifest = entity.manifest;
    if (!manifest.hasCreate) return;
    final id = manifest.entityName;
    final type = manifest.entityName;
    final lower = manifest.entityNameLower;

    final client = artifacts.get<ApiClientArtifact>(ArtifactKind.apiClient, id);
    if (client != null) {
      client.methods.addLazy(
        _name,
        () => Code(
          [
            'Future<$type> create($type $lower${client.parentParamTrailing}) async {',
            "  final response = await _dio.post('${client.urlBase}', data: _createBody($lower));",
            '  return $type.fromJson(response.data as Map<String, dynamic>);',
            '}',
            '',
            '/// Only the fields of the create form (and the parent id).',
            'Map<String, dynamic> _createBody($type $lower) => {',
            '  for (final e in $lower.toJson().entries)',
            '    if (const <String>{${manifest.createJsonNames.map((n) => "'$n'").join(', ')}}.contains(e.key)) e.key: e.value,',
            '};',
          ].join('\n'),
        ),
        order: 10,
      );
    }

    final provider =
        artifacts.get<ListProviderArtifact>(ArtifactKind.listProvider, id);
    if (provider != null) {
      provider.methods.addLazy(
        _name,
        () => Code(
          [
            'Future<void> create($type $lower) async {',
            '  await _client.create($lower${provider.clientTrailing});',
            '  await _load();',
            '}',
          ].join('\n'),
        ),
        order: 20,
      );
    }

    final screen =
        artifacts.get<ListScreenArtifact>(ArtifactKind.listScreen, id);
    if (screen != null) {
      screen.floatingActionButton.add(
        _name,
        Code(
          [
            'FloatingActionButton(',
            "  tooltip: 'Create ${manifest.title}',",
            '  onPressed: () async {',
            "    await context.push('${entity.paths.createPath(manifest)}');",
            '    ref.invalidate(${ListScreenArtifact.providerRef});',
            '  },',
            '  child: const Icon(Icons.add),',
            '),',
          ].join('\n'),
          imports: {Libs.goRouter, Libs.materialUi},
        ),
        order: 10,
      );
    }

    final routes = artifacts.get<RoutesArtifact>(
        ArtifactKind.routes, entity.libraryManifests.first.entityName);
    routes?.listChildRoutes.add(
      _name,
      ListChildRoute(
          entityName: id, path: 'create', className: '${type}CreateScreen'),
      order: 10,
    );
  }
}
