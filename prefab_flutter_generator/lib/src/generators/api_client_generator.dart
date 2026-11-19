import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:prefab_flutter/prefab_flutter.dart';
import 'package:source_gen/source_gen.dart';

import '../manifest/entity_manifest.dart';

const _viewChecker = TypeChecker.fromRuntime(View);

/// Generates a Dio-backed `{Entity}ApiClient` class for every class annotated
/// with [@View].
///
/// Each API client exposes methods for: list, getById and delete, plus create (only with [@Create])
/// and update (only with [@Update]).  When the entity carries a [@Parent]-annotated field, every method
/// accepts a named `{parentFieldName}` parameter and the URL is prefixed with
/// the parent resource path so that the resource is correctly scoped:
///
/// ```
/// GET  /{parentPath}/{parentId}/{path}
/// GET  /{parentPath}/{parentId}/{path}/{id}
/// POST /{parentPath}/{parentId}/{path}
/// PUT  /{parentPath}/{parentId}/{path}/{id}
/// DELETE /{parentPath}/{parentId}/{path}/{id}
/// ```
class ApiClientGenerator extends Generator {
  @override
  String generate(LibraryReader library, BuildStep buildStep) {
    final annotated = library.annotatedWith(_viewChecker).toList();
    if (annotated.isEmpty) return '';

    final manifests = <EntityManifest>[];
    for (final a in annotated) {
      final element = a.element;
      if (element is! ClassElement) continue;
      _requireJsonSupport(element);
      manifests.add(EntityManifest.from(element, a.annotation));
    }

    final sourceFileName = buildStep.inputId.path.split('/').last;

    final buffer = StringBuffer();
    _writeHeader(buffer);
    _writeImports(sourceFileName, buffer);
    buffer.writeln();

    for (final manifest in manifests) {
      _writeApiClientClass(manifest, buffer);
      buffer.writeln();
    }

    return buffer.toString();
  }

  // ---------------------------------------------------------------------------
  // Validation
  // ---------------------------------------------------------------------------

  /// Fails the build unless [element] has a `fromJson(Map<String, dynamic>)`
  /// constructor and a `toJson()` method (e.g. from `json_serializable`).
  void _requireJsonSupport(ClassElement element) {
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
  // Header
  // ---------------------------------------------------------------------------

  void _writeHeader(StringBuffer buffer) {
    const sep =
        '// **************************************************************************';
    buffer.writeln('// GENERATED CODE - DO NOT MODIFY BY HAND');
    buffer.writeln('//');
    buffer.writeln(sep);
    buffer.writeln('// ApiClientGenerator');
    buffer.writeln(sep);
    buffer.writeln();
  }

  // ---------------------------------------------------------------------------
  // Imports
  // ---------------------------------------------------------------------------

  void _writeImports(String sourceFileName, StringBuffer buffer) {
    buffer.writeln("import 'package:dio/dio.dart';");
    buffer.writeln(
        "import 'package:prefab_flutter_widgets/prefab_flutter_widgets.dart';");
    buffer.writeln();
    final base = sourceFileName.replaceFirst(RegExp(r'\.dart$'), '');
    buffer.writeln("import '$base.dart';");
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
    final parentParamName = manifest.parentParamName; // e.g. 'postId'
    final parentParamType = hasParent ? manifest.parentField!.dartType : null;

    // The URL base path: '/parentPath/$parentParam/path' or '/path'.
    final parentPath = manifest.parentPath;
    final urlBase =
        hasParent ? '/$parentPath/\$$parentParamName/$path' : '/$path';

    final parentParamTrailing =
        hasParent ? ', {required $parentParamType $parentParamName}' : '';

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
      if (hasParent) 'required $parentParamType $parentParamName',
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
