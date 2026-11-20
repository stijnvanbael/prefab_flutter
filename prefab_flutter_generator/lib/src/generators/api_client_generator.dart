import 'package:analyzer/dart/element/element.dart';
import 'package:source_gen/source_gen.dart';

import '../core/artifact.dart';
import '../core/artifact_generator.dart';
import '../core/code.dart';
import '../core/entity_context.dart';
import '../manifest/entity_manifest.dart';

/// Generates a Dio-backed `{Entity}ApiClient` class for every class annotated
/// with [@View].
///
/// Each API client exposes methods for: list, getById and delete, plus create (only with [@Create])
/// and update (only with [@Update]).  When the entity carries a [@Parent]-annotated field, every method
/// accepts a named id parameter for each ancestor (the whole chain, outermost
/// first) and the URL is prefixed with the ancestor resource paths so that the
/// resource is correctly scoped:
///
/// ```
/// GET  /{parentPath}/{parentId}/{path}
/// GET  /{parentPath}/{parentId}/{path}/{id}
/// POST /{parentPath}/{parentId}/{path}
/// PUT  /{parentPath}/{parentId}/{path}/{id}
/// DELETE /{parentPath}/{parentId}/{path}/{id}
/// ```
class ApiClientGenerator extends ArtifactGenerator {
  ApiClientGenerator()
      : super('ApiClientGenerator', const [ApiClientArtifact.create]);
}

/// The `{Entity}ApiClient` class of one entity.
class ApiClientArtifact extends Artifact {
  ApiClientArtifact(this.entity);

  final EntityContext entity;

  static Iterable<Artifact> create(EntityContext entity) {
    _requireJsonSupport(entity.element);
    return [ApiClientArtifact(entity)];
  }

  @override
  ArtifactId get id =>
      ArtifactId(ArtifactKind.apiClient, entity.manifest.entityName);

  @override
  String get primaryName => '${entity.manifest.entityName}ApiClient';

  @override
  Code emit() {
    final buffer = StringBuffer();
    _writeApiClientClass(entity.manifest, buffer);
    return Code(
      buffer.toString().trim(),
      imports: {Libs.dio, Libs.widgets, entity.sourceFileName},
    );
  }

  // ---------------------------------------------------------------------------
  // Validation
  // ---------------------------------------------------------------------------

  /// Fails the build unless [element] has a `fromJson(Map<String, dynamic>)`
  /// constructor and a `toJson()` method (e.g. from `json_serializable`).
  static void _requireJsonSupport(ClassElement element) {
    final fromJson = element.getNamedConstructor('fromJson');
    final toJson = element.getMethod('toJson');
    final missing = <String>[
      if (fromJson == null) 'a "fromJson(Map<String, dynamic> json)" factory',
      if (toJson == null) 'a "toJson()" method',
    ];
    if (missing.isEmpty) return;
    throw InvalidGenerationSourceError(
      'Entity "${element.name}" needs ${missing.join(' and ')} so that the '
      'generated API client can (de)serialize it. Annotate the class with '
      '@JsonSerializable() (json_serializable) or write them by hand.',
      element: element,
    );
  }

  // ---------------------------------------------------------------------------
  // API client class
  // ---------------------------------------------------------------------------

  void _writeApiClientClass(
    EntityManifest manifest,
    StringBuffer buffer,
  ) {
    final entity = manifest.entityName;
    final path = manifest.path;

    // Determine whether this entity is nested under a parent.
    final hasParent = manifest.hasParent;
    // The URL base path: '/orders/$orderId/lines/$orderLineId/notes' or
    // '/path'; every ancestor contributes its path and id.
    final urlBase = [
      for (final a in manifest.ancestors) '/${a.path}/\$${a.paramName}',
      '/$path',
    ].join();

    final requiredAncestors = [
      for (final a in manifest.ancestors) 'required ${a.idType} ${a.paramName}',
    ].join(', ');
    final parentParamTrailing = hasParent ? ', {$requiredAncestors}' : '';

    buffer.writeln('class ${entity}ApiClient {');
    buffer.writeln('  final Dio _dio;');
    buffer.writeln('  final PrefabListAdapter _adapter;');
    buffer.writeln();
    buffer.writeln(
        '  ${entity}ApiClient(this._dio, [this._adapter = const PrefabListAdapter()]);');
    buffer.writeln();

    // list: search, sort and pagination go to the server as query parameters
    // (names and response shape come from the PrefabListAdapter).
    final listParams = [
      if (hasParent) requiredAncestors,
      'String? search',
      'String? sort',
      'bool descending = false',
      'int page = 0',
      'int? pageSize',
    ].join(', ');
    buffer.writeln('  Future<PrefabPage<$entity>> list({$listParams}) async {');
    buffer.writeln('    final response = await _dio.get(');
    buffer.writeln("      '$urlBase',");
    buffer.writeln('      queryParameters: _adapter.queryParameters(');
    buffer.writeln('        search: search,');
    buffer.writeln('        sort: sort,');
    buffer.writeln('        descending: descending,');
    if (manifest.paged) {
      buffer.writeln('        page: page,');
      buffer.writeln('        pageSize: pageSize,');
    }
    buffer.writeln('      ),');
    buffer.writeln('    );');
    buffer.writeln('    return _adapter.parsePage(');
    buffer.writeln('      response.data,');
    buffer.writeln('      $entity.fromJson,');
    if (manifest.paged) {
      buffer.writeln('      page: page,');
      buffer.writeln('      pageSize: pageSize,');
    }
    buffer.writeln('    );');
    buffer.writeln('  }');
    buffer.writeln();

    // getById
    buffer.writeln(
        '  Future<$entity> getById(${manifest.idType} id$parentParamTrailing) async {');
    buffer.writeln("    final response = await _dio.get('$urlBase/\$id');");
    buffer.writeln(
        '    return $entity.fromJson(response.data as Map<String, dynamic>);');
    buffer.writeln('  }');
    buffer.writeln();

    if (manifest.hasCreate) {
      // create
      buffer.writeln(
          '  Future<$entity> create($entity ${manifest.entityNameLower}$parentParamTrailing) async {');
      buffer.writeln(
          "    final response = await _dio.post('$urlBase', data: ${manifest.entityNameLower}.toJson());");
      buffer.writeln(
          '    return $entity.fromJson(response.data as Map<String, dynamic>);');
      buffer.writeln('  }');
      buffer.writeln();
    }

    if (manifest.hasUpdate) {
      // update
      buffer.writeln(
          '  Future<$entity> update($entity ${manifest.entityNameLower}$parentParamTrailing) async {');
      buffer.writeln(
          "    final response = await _dio.put('$urlBase/\${${manifest.entityNameLower}.${manifest.idFieldName}}', data: ${manifest.entityNameLower}.toJson());");
      buffer.writeln(
          '    return $entity.fromJson(response.data as Map<String, dynamic>);');
      buffer.writeln('  }');
      buffer.writeln();
    }

    // delete
    buffer.writeln(
        '  Future<void> delete($entity ${manifest.entityNameLower}$parentParamTrailing) async {');
    buffer.writeln(
        "    await _dio.delete('$urlBase/\${${manifest.entityNameLower}.${manifest.idFieldName}}');");
    buffer.writeln('  }');

    buffer.writeln('}');
  }
}
