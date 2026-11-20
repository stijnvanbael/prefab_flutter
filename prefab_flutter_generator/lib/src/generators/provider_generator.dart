import '../core/artifact.dart';
import '../core/artifact_generator.dart';
import '../core/code.dart';
import '../core/entity_context.dart';
import '../core/extension_point.dart';
import '../core/family_key.dart';
import '../features/features.dart';
import '../manifest/entity_manifest.dart';

/// Generates Riverpod providers for every class annotated with [@View].
///
/// Produced providers include:
/// - `{entity}DetailProvider` — `FutureProvider.autoDispose.family` that fetches a single
///   entity by ID via the generated API client,
/// - `{entity}sProvider` — an `AsyncNotifierProvider.autoDispose` (`AutoDisposeAsyncNotifier`) for the full list with
///   create / update / delete mutations.
///
/// When the entity carries a [@Parent]-annotated field, every provider accepts
/// the ids of its whole ancestor chain (outermost first) and threads them
/// through to the API client:
/// - `{entity}DetailProvider` becomes a `family` keyed on `(id, ancestor ids...)`.
/// - `{entity}sProvider` becomes a `family` (`AutoDisposeFamilyAsyncNotifier`)
///   keyed on the parent id, or on a record of the ancestor ids when the
///   entity is nested more than one level deep.
class ProviderGenerator extends ArtifactGenerator {
  ProviderGenerator()
      : super('ProviderGenerator', const [createProviderArtifacts],
            features: registeredFeatures,
            kinds: {
              ArtifactKind.detailProvider,
              ArtifactKind.listProvider,
              ArtifactKind.apiClientProvider,
            });
}

/// The provider artifacts of one entity: its detail provider, list provider
/// and API client provider, in this order. They share one factory so that the
/// providers of an entity stay together in the generated file.
Iterable<Artifact> createProviderArtifacts(EntityContext entity) => [
      DetailProviderArtifact(entity),
      ListProviderArtifact(entity),
      ApiClientProviderArtifact(entity),
    ];

/// The templates shared by the provider artifacts of one entity.
abstract class _ProviderArtifact extends Artifact {
  _ProviderArtifact(this.entity);

  final EntityContext entity;

  EntityManifest get manifest => entity.manifest;

  Code _code(StringBuffer buffer, Set<String> imports) => Code(
        buffer.toString().trim(),
        imports: {...imports, Libs.riverpod, entity.sourceFileName},
      );

  // ---------------------------------------------------------------------------
  // Provider declarations
  // ---------------------------------------------------------------------------

  void _writeDetailProvider(StringBuffer buffer, FamilyKey key) {
    final entity = manifest.entityName;
    final entityLower = manifest.entityNameLower;

    if (!key.isEmpty) {
      // Detail provider keyed on (id, ancestor ids...), outermost first.
      final named = [
        for (var i = 0; i < key.ids.length; i++)
          '${key.ids[i].name}: args.\$${i + 2}',
      ].join(', ');
      buffer.writeln(
          'final ${entityLower}DetailProvider = FutureProvider.autoDispose'
          '.family<$entity, ${key.detailType(manifest.idType)}>((ref, args) =>');
      buffer.writeln(
          '    ref.watch(${entityLower}ApiClientProvider).getById(args.\$1, $named));');
    } else {
      // Detail provider keyed on the typed id.
      buffer.writeln(
          'final ${entityLower}DetailProvider = FutureProvider.autoDispose'
          '.family<$entity, ${manifest.idType}>((ref, id) =>');
      buffer.writeln(
          '    ref.watch(${entityLower}ApiClientProvider).getById(id));');
    }
  }

  void _writeApiClientProvider(StringBuffer buffer) {
    final entity = manifest.entityName;
    final entityLower = manifest.entityNameLower;
    buffer.writeln(
        'final ${entityLower}ApiClientProvider = Provider.autoDispose<${entity}ApiClient>(');
    buffer.writeln(
        '  (ref) => ${entity}ApiClient(ref.watch(prefabDioProvider), ref.watch(prefabListAdapterProvider)));');
  }
}

/// The `{entity}DetailProvider` of one entity.
class DetailProviderArtifact extends _ProviderArtifact {
  DetailProviderArtifact(super.entity);

  @override
  ArtifactId get id =>
      ArtifactId(ArtifactKind.detailProvider, manifest.entityName);

  @override
  String get primaryName => '${manifest.entityNameLower}DetailProvider';

  /// The ids of the owning resources, outermost first (nested resources);
  /// the detail provider is keyed on `(id, ids...)`.
  final familyKey = ValuePoint<FamilyId>('detailProvider.familyKey');

  @override
  Code emit() {
    final buffer = StringBuffer();
    _writeDetailProvider(buffer, FamilyKey(familyKey.values));
    return _code(buffer, const {});
  }
}

/// The `{entity}sProvider` and its notifier of one entity.
class ListProviderArtifact extends _ProviderArtifact {
  ListProviderArtifact(super.entity);

  @override
  ArtifactId get id =>
      ArtifactId(ArtifactKind.listProvider, manifest.entityName);

  @override
  String get primaryName => '${manifest.entityNameLower}sProvider';

  /// Fields and getters of the notifier, after `_client` (indent 2).
  /// Orders in use: 10 list query.
  final state = ExtensionPoint('listProvider.state');

  /// Statements at the start of `build` (indent 4).
  final onBuild = ExtensionPoint('listProvider.onBuild');

  /// Methods after `_load` (indent 2), separated by blank lines. Orders in
  /// use: 10 list query, 20 create, 30 update, 40 delete. Contribute with
  /// `addLazy` when the code uses [key].
  final methods = ExtensionPoint('listProvider.methods');

  /// Arguments of `_client.list(...)`, after the ancestor ids. Orders in use:
  /// 10 search, 20 sort, 30 descending, 40 page, 50 page size.
  final fetchArguments = ValuePoint<NamedArgument>('listProvider.fetchArguments');

  /// The ids of the owning resources, outermost first (nested resources):
  /// the list provider becomes a family keyed on them and passes them to the
  /// API client.
  final familyKey = ValuePoint<FamilyId>('listProvider.familyKey');

  /// The ids of [familyKey] and the snippets built from them.
  FamilyKey get key => FamilyKey(familyKey.values);

  /// The ancestor ids as trailing named arguments of an API client call, e.g.
  /// `, postId: postId`, or empty without ancestors.
  String get clientTrailing => key.isEmpty ? '' : ', ${key.namedArgs()}';

  /// The argument of `{entity}DetailProvider(...)` for the entity held in the
  /// local variable named like the entity (`post`).
  String get detailKeyArgs => key.detailExpr(
      '${manifest.entityNameLower}.${manifest.idFieldName}${manifest.idBang}',
      (a) => a.name);

  @override
  List<String> get declaredNames =>
      [primaryName, '${manifest.entityName}sNotifier'];

  void _writeListProvider(StringBuffer buffer) {
    final entity = manifest.entityName;
    final entityLower = manifest.entityNameLower;
    final key = FamilyKey(familyKey.values);
    final hasParent = !key.isEmpty;
    final parentParamType = hasParent ? key.listType : null;

    if (hasParent) {
      // List provider keyed on parentType parentId.
      buffer.writeln(
          'final ${entityLower}sProvider = AsyncNotifierProvider.autoDispose'
          '.family<${entity}sNotifier, PrefabPage<$entity>, $parentParamType>(');
      buffer.writeln('  ${entity}sNotifier.new);');
      buffer.writeln();

      // Family notifier; the family argument is the parent id.
      buffer.writeln(
          'class ${entity}sNotifier extends AutoDisposeFamilyAsyncNotifier<PrefabPage<$entity>, $parentParamType> {');
      for (var i = 0; i < key.depth; i++) {
        final a = key.ids[i];
        final access = key.depth == 1 ? 'arg' : 'arg.\$${i + 1}';
        buffer.writeln('  ${a.type} get ${a.name} => $access;');
      }
      buffer.writeln();
      _writeNotifierBody(manifest, buffer,
          key: key,
          buildSignature: '$parentParamType arg',
          parentArg: key.namedArgs());
      buffer.writeln('}');
    } else {
      // List provider (no family arg).
      buffer.writeln(
          'final ${entityLower}sProvider = AsyncNotifierProvider.autoDispose'
          '<${entity}sNotifier, PrefabPage<$entity>>(${entity}sNotifier.new);');
      buffer.writeln();

      // AsyncNotifier.
      buffer.writeln(
          'class ${entity}sNotifier extends AutoDisposeAsyncNotifier<PrefabPage<$entity>> {');
      _writeNotifierBody(manifest, buffer,
          key: key, buildSignature: '', parentArg: '');
      buffer.writeln('}');
    }
  }

  /// Writes the members shared by the plain and the family list notifier:
  /// the state and methods features contribute (list query), `build`,
  /// `_load` and the create / update / delete mutations.
  ///
  /// [buildSignature] is the parameter list of `build` (`'int arg'` for a
  /// family notifier, empty otherwise); [parentArg] is the named parent
  /// argument passed to the API client (`'postId: postId'`, or empty).
  void _writeNotifierBody(
    EntityManifest manifest,
    StringBuffer buffer, {
    required FamilyKey key,
    required String buildSignature,
    required String parentArg,
  }) {
    final entity = manifest.entityName;
    final entityLower = manifest.entityNameLower;
    final hasParent = !key.isEmpty;
    final listArgs = [
      if (hasParent) parentArg,
      for (final argument in fetchArguments.values) '$argument',
    ].join(', ');
    buffer.writeln(
        '  ${entity}ApiClient get _client => ref.read(${entityLower}ApiClientProvider);');
    buffer.writeln();
    if (!state.isEmpty) {
      buffer.writeln(state.render(2));
      buffer.writeln();
    }
    buffer.writeln('  @override');
    buffer.writeln('  Future<PrefabPage<$entity>> build($buildSignature) {');
    if (!onBuild.isEmpty) buffer.writeln(onBuild.render(4));
    buffer.writeln('    return _client.list($listArgs);');
    buffer.writeln('  }');
    buffer.writeln();
    buffer.writeln('  Future<void> _load() async {');
    buffer.writeln(
        '    state = const AsyncLoading<PrefabPage<$entity>>().copyWithPrevious(state);');
    buffer.writeln(
        '    state = await AsyncValue.guard(() => _client.list($listArgs));');
    buffer.writeln('  }');
    if (!methods.isEmpty) {
      buffer.writeln();
      buffer.writeln(methods.render(2, separator: '\n\n'));
    }
  }

  @override
  Code emit() {
    final buffer = StringBuffer();
    _writeListProvider(buffer);
    return _code(buffer, {
      ...state.imports,
      ...onBuild.imports,
      ...methods.imports,
      Libs.widgets,
    });
  }
}

/// The `{entity}ApiClientProvider` of one entity.
class ApiClientProviderArtifact extends _ProviderArtifact {
  ApiClientProviderArtifact(super.entity);

  @override
  ArtifactId get id =>
      ArtifactId(ArtifactKind.apiClientProvider, manifest.entityName);

  @override
  String get primaryName => '${manifest.entityNameLower}ApiClientProvider';

  @override
  Code emit() {
    final buffer = StringBuffer();
    _writeApiClientProvider(buffer);
    return _code(buffer, {Libs.widgets});
  }
}
