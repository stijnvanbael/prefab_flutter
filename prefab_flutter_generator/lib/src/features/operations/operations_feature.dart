import '../../core/artifact.dart';
import '../../core/code.dart';
import '../../core/entity_context.dart';
import '../../core/family_key.dart';
import '../../core/feature.dart';
import '../../core/library_emitter.dart';
import '../../generators/api_client_generator.dart';
import '../../generators/detail_screen_generator.dart';
import '../../generators/list_screen_generator.dart';
import '../../generators/provider_generator.dart';
import '../../generators/routes_generator.dart';
import '../actions/action_rendering.dart';
import '../validators/validator_emitters.dart' show dartStringLiteral;
import 'operation_manifest.dart';
import 'operation_screen_artifact.dart';

/// Named domain operations (`@Update(path: 'send')`, PF-54).
///
/// Per operation: an API client method (`POST {collection}/{id}/{path}`, the
/// method and body come from `PrefabBackend`), a notifier method that
/// refreshes the entity and the list, a button in the places of `on:` and,
/// for an operation with parameters, an `{Entity}{Operation}Screen` form
/// below the detail route. Orders used on the shared extension points: 40 on
/// the API client methods, 50 on the notifier methods, 40 on the app bar
/// actions and 6 on the detail child routes.
class OperationsFeature extends Feature {
  const OperationsFeature();

  static const _name = 'operations';

  @override
  String get name => _name;

  @override
  List<ArtifactFactory> get artifacts => const [_createScreens];

  static Iterable<Artifact> _createScreens(EntityContext entity) => [
        for (final o in OperationManifest.readAll(entity.element))
          if (o.hasParameters) OperationScreenArtifact(entity, o),
      ];

  @override
  void contribute(EntityContext entity, ArtifactSet artifacts) {
    final operations = OperationManifest.readAll(entity.element);
    if (operations.isEmpty) return;
    final manifest = entity.manifest;
    final id = manifest.entityName;
    final type = manifest.entityName;
    final lower = manifest.entityNameLower;

    final client = artifacts.get<ApiClientArtifact>(ArtifactKind.apiClient, id);
    if (client != null) {
      for (final o in operations) {
        client.methods.addLazy(
          '$_name/${o.path}',
          () => Code(_clientMethod(manifest.idType, client, o),
              imports: {Libs.dio, if (o.parameters?.libraryUri != null) o.parameters!.libraryUri!}),
          order: 40,
        );
      }
    }

    final provider =
        artifacts.get<ListProviderArtifact>(ArtifactKind.listProvider, id);
    if (provider != null) {
      for (final o in operations) {
        provider.methods.addLazy(
          '$_name/${o.path}',
          () {
            final p = o.parameters;
            final params = p == null ? '' : ', ${p.className} parameters';
            final args = p == null ? '' : ', parameters';
            return Code(
              [
                'Future<void> ${o.methodName}(${manifest.idType} id$params) async {',
                '  await _client.${o.methodName}(id$args${provider.clientTrailing});',
                '  ref.invalidate(${lower}DetailProvider(${provider.key.detailExpr('id', (a) => a.name)}));',
                '  await _load();',
                '}',
              ].join('\n'),
              imports: {if (p?.libraryUri != null) p!.libraryUri!},
            );
          },
          order: 50,
        );
      }
    }

    final detail =
        artifacts.get<DetailScreenArtifact>(ArtifactKind.detailScreen, id);
    final onDetail = [for (final o in operations) if (o.places.contains('detail')) o];
    final promotedDetail =
        artifacts.promotedName(ArtifactKind.detailScreen, id);
    if (promotedDetail != null && onDetail.isNotEmpty) {
      artifacts.warn('$promotedDetail is @Promoted, so it does not show the '
          'operations ${[for (final o in onDetail) o.path].join(', ')} '
          '(@Update on $id). Add them to $promotedDetail by hand or use '
          'on: {Place.item}.');
    }
    if (detail != null && onDetail.isNotEmpty) {
      detail.appBarActions.addLazy(
        _name,
        () {
          final key = detail.key;
          final listArg = key.isEmpty ? '' : '(${key.listExpr((a) => a.name)})';
          final items = sortActions([
            for (final o in onDetail)
              ActionItem(
                label: o.label,
                icon: o.icon,
                name: o.path,
                order: o.order,
                call: o.hasParameters
                    ? "context.push('${entity.paths.itemPath(manifest, r'$id')}/${o.path}')"
                    : _run(o, '${lower}sProvider$listArg', 'id'),
              ),
          ]);
          return Code(
            renderAppBarActions(items,
                enabledWhen: '${detail.asyncName}.hasValue'),
            imports: {Libs.goRouter, Libs.materialUi, Libs.widgets, Libs.riverpod},
          );
        },
        order: 40,
      );
    }

    final list = artifacts.get<ListScreenArtifact>(ArtifactKind.listScreen, id);
    final onItem = [for (final o in operations) if (o.places.contains('item')) o];
    if (list != null && onItem.isNotEmpty) {
      list.itemActions.addLazy(
        _name,
        () {
          final key = FamilyKey(list.familyKey.values);
          final listArg = key.isEmpty ? '' : '(${key.listExpr((a) => a.name)})';
          final itemId =
              '${list.itemName}.${manifest.idFieldName}${manifest.idBang}';
          final items = sortActions([
            for (final o in onItem)
              ActionItem(
                label: o.label,
                icon: o.icon,
                name: o.path,
                order: o.order,
                call: _itemCall(
                  o,
                  itemPath: entity.paths.itemPath(manifest, '\${$itemId}'),
                  run: _run(o, '${lower}sProvider$listArg', itemId),
                ),
              ),
          ]);
          return Code(renderMenuEntries(items),
              imports: {Libs.goRouter, Libs.materialUi, Libs.widgets, Libs.riverpod});
        },
        order: 40,
      );
    }

    final routes = artifacts.get<RoutesArtifact>(
        ArtifactKind.routes, entity.libraryManifests.first.entityName);
    for (final o in operations) {
      if (!o.hasParameters) continue;
      routes?.detailChildRoutes.add(
        _name,
        DetailChildRoute(
          entityName: id,
          path: o.path,
          className: '$type${o.pascalName}Screen',
          libraryUri: '',
        ),
        order: 6,
      );
    }
  }

  /// The call of the menu entry of an operation in a list item. An operation
  /// that starts a job (PF-57) opens the detail screen of the item after it
  /// ran; the form of an operation with parameters tells it saved by popping
  /// with `true`.
  String _itemCall(OperationManifest o,
      {required String itemPath, required String run}) {
    final push = "context.push('$itemPath/${o.path}')";
    if (!o.startsJob) return o.hasParameters ? push : run;
    final open = [
      '(started) {',
      '  if (started == true && context.mounted) {',
      "    context.push('$itemPath');",
      '  }',
      '}',
    ].join('\n');
    return o.hasParameters
        ? "context.push<bool>('$itemPath/${o.path}').then($open)"
        : '$run.then($open)';
  }

  /// The expression that confirms and runs an operation without parameters.
  String _run(OperationManifest o, String provider, String idExpression) => [
        'runPrefabOperation(',
        '  context: context,',
        '  backend: ref.read(prefabBackendProvider),',
        '  label: ${dartStringLiteral(o.label)},',
        if (o.confirm != null) '  confirm: ${dartStringLiteral(o.confirm!)},',
        '  run: () => ref.read($provider.notifier).${o.methodName}($idExpression),',
        ')',
      ].join('\n');

  String _clientMethod(
      String idType, ApiClientArtifact client, OperationManifest o) {
    final p = o.parameters;
    final params = p == null ? '' : ', ${p.className} parameters';
    return [
      'Future<void> ${o.methodName}($idType id$params${client.parentParamTrailing}) async {',
      '  await _dio.request<void>(',
      "    '${client.urlBase}/\${_adapter.encodeId(id)}/${o.path}',",
      '    data: _adapter.operationBody(${p == null ? 'null' : 'parameters.toJson()'}),',
      '    options: Options(method: _adapter.operationMethod),',
      '  );',
      '}',
    ].join('\n');
  }
}
