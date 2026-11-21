import 'package:prefab_flutter/prefab_flutter.dart';
import 'package:source_gen/source_gen.dart';

import '../../core/artifact.dart';
import '../../core/code.dart';
import '../../core/entity_context.dart';
import '../../core/feature.dart';
import '../../generators/api_client_generator.dart';
import '../../generators/list_screen_generator.dart';
import '../../generators/provider_generator.dart';

final _streamingChecker =
    TypeChecker.typeNamed(Streaming, inPackage: 'prefab_flutter');

/// Live updates over server-sent events (`@Streaming`).
///
/// The API client gets `eventsUrl` (the URL of the event stream, from the
/// backend adapter), the detail provider becomes a `StreamProvider` that
/// follows the events of its entity, the list notifier applies the events to
/// the page it holds (`reload` refreshes it; a reconnect of the stream
/// reloads the list and the detail) and the list screen shows a
/// "new items" banner for created items that were not inserted. Orders used
/// on the shared extension points: 50 on the API client methods, 10 on the
/// detail provider declaration, 50 on the list notifier `onBuild` and
/// `methods`, 20 on the list screen `aboveList`.
class StreamingFeature extends Feature {
  const StreamingFeature();

  static const _name = 'streaming';

  @override
  String get name => _name;

  @override
  void contribute(EntityContext entity, ArtifactSet artifacts) {
    if (!_streamingChecker.hasAnnotationOf(entity.element)) return;
    final manifest = entity.manifest;
    final id = manifest.entityName;
    final type = manifest.entityName;
    final lower = manifest.entityNameLower;
    final idKey = _quote(manifest.idJsonName);

    final client = artifacts.get<ApiClientArtifact>(ArtifactKind.apiClient, id);
    if (client != null) {
      client.methods.addLazy(
        _name,
        () => Code(
          [
            '/// The URL of the live event stream of the collection.',
            'String eventsUrl(${client.key.isEmpty ? '' : '{${client.key.requiredParams}}'}) =>',
            "    _adapter.eventsUrl('${client.urlBase}');",
          ].join('\n'),
        ),
        order: 50,
      );
    }

    final detail =
        artifacts.get<DetailProviderArtifact>(ArtifactKind.detailProvider, id);
    if (detail != null) {
      detail.declaration.addLazy(
        _name,
        () => Code(
          [
            'final ${lower}DetailProvider = StreamProvider.autoDispose',
            '    .family<$type, ${detail.keyType}>((ref, ${detail.argName}) {',
            '  final client = ref.watch(${lower}ApiClientProvider);',
            '  return prefabLiveDetail<$type>(',
            '    load: () => client.getById(${detail.idExpr}${detail.ancestorArgs}),',
            '    events: ref.watch(prefabEventsProvider(',
            '        client.eventsUrl(${_ancestorsOnly(detail.ancestorArgs)}))),',
            '    fromJson: $type.fromJson,',
            '    id: ${detail.idExpr},',
            '    idKey: $idKey,',
            '  );',
            '});',
          ].join('\n'),
          imports: {Libs.riverpod, Libs.widgets},
        ),
        order: 10,
      );
    }

    final provider =
        artifacts.get<ListProviderArtifact>(ArtifactKind.listProvider, id);
    if (provider != null) {
      provider.onBuild.addLazy(
        _name,
        () => Code(
          [
            '// Live updates: follow the event stream while this notifier lives.',
            'final events = ref.watch(prefabEventsProvider(_client.eventsUrl(${_namedAncestors(provider.clientTrailing)})));',
            'final subscription = events.listen(_onEvent);',
            'ref.onDispose(subscription.cancel);',
          ].join('\n'),
          imports: {Libs.widgets},
        ),
        order: 50,
      );
      provider.methods.add(
        _name,
        Code(
          [
            '/// Applies a live event to the loaded page. Created items that do',
            '/// not belong on this page are counted in `PrefabPage.newItems`.',
            '/// After a reconnect the list is reloaded: events may have been missed.',
            'void _onEvent(PrefabEvent event) {',
            '  if (event.type == PrefabEventType.reconnected) {',
            '    if (!state.isLoading) _load();',
            '    return;',
            '  }',
            '  final page = state.valueOrNull;',
            '  if (page == null) return;',
            '  state = AsyncData(applyPrefabEvent<$type>(',
            '    page,',
            '    event,',
            '    fromJson: $type.fromJson,',
            '    idOf: (item) => item.${manifest.idFieldName},',
            '    idKey: $idKey,',
            '    paged: ${manifest.paged},',
            "    canInsert: _search.isEmpty && _sort == null,",
            '  ));',
            '}',
            '',
            '/// Reloads the list, e.g. to show the items counted in',
            '/// `PrefabPage.newItems`.',
            'Future<void> reload() => _load();',
          ].join('\n'),
          imports: {Libs.widgets, entity.sourceFileName},
        ),
        order: 50,
      );
    }

    final screen =
        artifacts.get<ListScreenArtifact>(ArtifactKind.listScreen, id);
    if (screen != null) {
      final async = screen.asyncName;
      screen.aboveList.add(
        _name,
        Code(
          [
            'if (($async.valueOrNull?.newItems ?? 0) > 0)',
            '  PrefabNewItemsBanner(',
            '    count: $async.requireValue.newItems,',
            '    onRefresh: ref.read(${ListScreenArtifact.providerRef}.notifier).reload,',
            '  ),',
          ].join('\n'),
          imports: {Libs.widgets},
        ),
        order: 20,
      );
    }
  }

  /// `, postId: args.$2` → `postId: args.$2`.
  static String _ancestorsOnly(String trailing) =>
      trailing.isEmpty ? '' : trailing.substring(2);

  /// `, postId: postId` → `postId: postId`.
  static String _namedAncestors(String trailing) => _ancestorsOnly(trailing);

  static String _quote(String value) => "'${value.replaceAll(r'$', r'\$')}'";
}
