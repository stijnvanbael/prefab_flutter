import 'package:source_gen/source_gen.dart';
import 'package:prefab_flutter/prefab_flutter.dart';

import '../../core/artifact.dart';
import '../../core/code.dart';
import '../../core/entity_context.dart';
import '../../core/feature.dart';
import '../../generators/detail_screen_generator.dart';
import '../../generators/list_screen_generator.dart';
import '../../generators/provider_generator.dart';
import 'job_status_manifest.dart';

final _streamingChecker =
    TypeChecker.typeNamed(Streaming, inPackage: 'prefab_flutter');

/// Status of long-running server jobs (`@JobStatus`, PF-57).
///
/// The list item shows the state of its job (`PrefabJobIndicator`), the detail
/// screen starts with a `PrefabJobBanner` (with the failure message), and
/// while a job runs the providers refresh until it is final: the list notifier
/// through a `PrefabJobPoller`, the detail provider as a `StreamProvider` built
/// on `prefabPolledDetail`. An entity that is `@Streaming` follows its live
/// events instead (the streaming feature owns the providers then), so only
/// the screens change.
///
/// Orders used on the shared extension points: 10 on the detail screen
/// `beforeFields` and the list screen `itemStatus`, 20 on the list notifier
/// `state`, 20 on its `onBuild`, 60 on its `methods`, and 20 on the detail
/// provider `declaration`.
class JobStatusFeature extends Feature {
  const JobStatusFeature();

  static const _name = 'job_status';

  @override
  String get name => _name;

  @override
  void contribute(EntityContext entity, ArtifactSet artifacts) {
    final job = JobStatusManifest.read(entity.element);
    if (job == null) return;
    final manifest = entity.manifest;
    final id = manifest.entityName;
    final type = manifest.entityName;
    final lower = manifest.entityNameLower;
    final streaming = _streamingChecker.hasAnnotationOf(entity.element);
    final enumImports = {
      Libs.widgets,
      if (job.enumLibraryUri != entity.element.library.uri.toString())
        job.enumLibraryUri,
    };

    final detail =
        artifacts.get<DetailScreenArtifact>(ArtifactKind.detailScreen, id);
    if (detail != null) {
      detail.beforeFields.add(
        _name,
        Code(
          [
            'PrefabJobBanner(',
            '  state: ${job.stateExpression(lower)},',
            '  message: ${job.messageExpression(lower)},',
            '),',
          ].join('\n'),
          imports: enumImports,
        ),
        order: 10,
      );
    } else {
      _warnPromoted(artifacts, ArtifactKind.detailScreen, id,
          'does not show the job banner');
    }

    final list = artifacts.get<ListScreenArtifact>(ArtifactKind.listScreen, id);
    if (list != null) {
      list.itemStatus.addLazy(
        _name,
        () => Code(
          'PrefabJobIndicator(state: ${job.stateExpression(list.itemName)})',
          imports: enumImports,
        ),
        order: 10,
      );
    } else {
      _warnPromoted(artifacts, ArtifactKind.listScreen, id,
          'does not show the job status of its items');
    }

    // Live events keep a streaming entity up to date; polling would only
    // duplicate them.
    if (streaming) return;

    final detailProvider =
        artifacts.get<DetailProviderArtifact>(ArtifactKind.detailProvider, id);
    if (detailProvider != null) {
      detailProvider.declaration.addLazy(
        _name,
        () => Code(
          [
            'final ${lower}DetailProvider = StreamProvider.autoDispose',
            '    .family<$type, ${detailProvider.keyType}>((ref, ${detailProvider.argName}) {',
            '  final client = ref.watch(${lower}ApiClientProvider);',
            '  return prefabPolledDetail<$type>(',
            '    load: () => client.getById(${detailProvider.idExpr}${detailProvider.ancestorArgs}),',
            '    isRunning: ($lower) => ${job.runningCondition(lower)},',
            '    interval: ${_duration(job.pollInterval)},',
            '  );',
            '});',
          ].join('\n'),
          imports: {Libs.riverpod, ...enumImports},
        ),
        order: 20,
      );
    }

    final provider =
        artifacts.get<ListProviderArtifact>(ArtifactKind.listProvider, id);
    if (provider != null) {
      provider.state.add(
        _name,
        Code(
          [
            '/// Refreshes the page while one of its jobs runs.',
            'late final _jobPoller = PrefabJobPoller(',
            '  interval: ${_duration(job.pollInterval)},',
            '  isRunning: () =>',
            '      state.valueOrNull?.items.any((item) => ${job.runningCondition('item')}) ??',
            '      false,',
            '  refresh: _refreshJobs,',
            ');',
          ].join('\n'),
          imports: enumImports,
        ),
        order: 20,
      );
      provider.onBuild.add(
        _name,
        Code(
          [
            '// Job status: poll while an item is running.',
            'ref.onDispose(_jobPoller.cancel);',
            'listenSelf((previous, next) => _jobPoller.check());',
          ].join('\n'),
          imports: {Libs.widgets},
        ),
        order: 20,
      );
      provider.methods.addLazy(
        _name,
        () => Code(
          [
            '/// Loads the page again without a loading state (job polling).',
            'Future<void> _refreshJobs() async {',
            '  state = AsyncData(await ${provider.fetchCall});',
            '}',
          ].join('\n'),
          imports: {Libs.riverpod},
        ),
        order: 60,
      );
    }
  }

  void _warnPromoted(
      ArtifactSet artifacts, ArtifactKind kind, String id, String what) {
    final promoted = artifacts.promotedName(kind, id);
    if (promoted != null) {
      artifacts.warn('$promoted is @Promoted, so it $what (@JobStatus on '
          '$id). Add it to $promoted by hand.');
    }
  }

  static String _duration(Duration d) {
    final micros = d.inMicroseconds;
    if (micros % Duration.microsecondsPerSecond == 0) {
      return 'const Duration(seconds: ${d.inSeconds})';
    }
    if (micros % Duration.microsecondsPerMillisecond == 0) {
      return 'const Duration(milliseconds: ${d.inMilliseconds})';
    }
    return 'const Duration(microseconds: $micros)';
  }
}
