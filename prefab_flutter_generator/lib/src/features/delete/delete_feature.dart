import '../../core/artifact.dart';
import '../../core/code.dart';
import '../../core/entity_context.dart';
import '../../core/feature.dart';
import '../../generators/api_client_generator.dart';
import '../../generators/detail_screen_generator.dart';
import '../../generators/provider_generator.dart';

/// Deleting entities (`@Delete`).
///
/// Adds the `delete` method of the API client, the `delete` method of the
/// list notifier and the Delete button (with a confirmation dialog) of the
/// detail screen. Orders used on the shared extension points: 20 on the detail
/// app bar actions, 30 on the API client methods and 40 on the notifier
/// methods.
///
/// The API client's `delete` is generated for every entity, with or without
/// `@Delete`, as it always was; the notifier method and the button need the
/// annotation.
class DeleteFeature extends Feature {
  const DeleteFeature();

  static const _name = 'delete';

  @override
  String get name => _name;

  @override
  void contribute(EntityContext entity, ArtifactSet artifacts) {
    final manifest = entity.manifest;
    final id = manifest.entityName;
    final type = manifest.entityName;
    final lower = manifest.entityNameLower;

    final client = artifacts.get<ApiClientArtifact>(ArtifactKind.apiClient, id);
    if (client != null) {
      client.methods.addLazy(
        _name,
        () => Code(
          [
            'Future<void> delete($type $lower${client.parentParamTrailing}) async {',
            "  await _dio.delete('${client.urlBase}/\${_adapter.encodeId($lower.${manifest.idFieldName})}');",
            '}',
          ].join('\n'),
        ),
        order: 30,
      );
    }

    if (!manifest.hasDelete) return;

    final provider =
        artifacts.get<ListProviderArtifact>(ArtifactKind.listProvider, id);
    if (provider != null) {
      provider.methods.addLazy(
        _name,
        () => Code(
          [
            'Future<void> delete($type $lower) async {',
            '  await _client.delete($lower${provider.clientTrailing});',
            '  ref.invalidate(${lower}DetailProvider(${provider.detailKeyArgs}));',
            '  await _load();',
            '}',
          ].join('\n'),
        ),
        order: 40,
      );
    }

    final detail =
        artifacts.get<DetailScreenArtifact>(ArtifactKind.detailScreen, id);
    if (detail != null) {
      final async = detail.asyncName;
      detail.appBarActions.addLazy(
        _name,
        () {
          final key = detail.key;
          final listProviderArg =
              key.isEmpty ? '' : '(${key.listExpr((a) => a.name)})';
          return Code(
            [
              'IconButton(',
              '  icon: const Icon(Icons.delete),',
              "  tooltip: 'Delete',",
              '  onPressed: $async.hasValue',
              '      ? () async {',
              '          final $lower = $async.value!;',
              '          final confirmed = await showPrefabDeleteDialog(',
              '            context: context,',
              '            item: $lower,',
              '            itemLabel: $lower.${manifest.firstLabelFieldName}.toString(),',
              '            onDelete: () => ref.read(${lower}sProvider$listProviderArg.notifier).delete($lower),',
              '          );',
              '          if (confirmed && context.mounted) {',
              '            context.pop();',
              '          }',
              '        }',
              '      : null,',
              '),',
            ].join('\n'),
            imports: {Libs.goRouter, Libs.materialUi, Libs.widgets},
          );
        },
        order: 20,
      );
    }
  }
}
