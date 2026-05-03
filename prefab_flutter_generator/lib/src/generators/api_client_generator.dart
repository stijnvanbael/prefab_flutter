import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:prefab_flutter/prefab_flutter.dart';
import 'package:source_gen/source_gen.dart';

import '../manifest/entity_manifest.dart';

const _viewChecker = TypeChecker.fromRuntime(View);

/// Generates a Dio-backed `{Entity}ApiClient` class for every class annotated
/// with [@View].
///
/// Each API client exposes methods for: list, getById, create, update and
/// delete.  When the entity carries a [@Parent]-annotated field, every method
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
      manifests.add(EntityManifest.from(element, a.annotation));
    }

    final sourceFileName = buildStep.inputId.path.split('/').last;
    // Map entityNameLower → manifest for parent look-up.
    final byName = {for (final m in manifests) m.entityNameLower: m};

    final buffer = StringBuffer();
    _writeHeader(buffer);
    _writeImports(sourceFileName, buffer);
    buffer.writeln();

    for (final manifest in manifests) {
      final parentName = manifest.parentEntityNameLower;
      EntityManifest? parentManifest;
      if (parentName != null) {
        parentManifest = byName[parentName];
        if (parentManifest == null) {
          throw InvalidGenerationSourceError(
            'Entity "${manifest.entityName}" has a @Parent field referencing '
            '"$parentName", but no @View-annotated class with that name was '
            'found in the same source file. Define the parent entity in the '
            'same source file as its children.',
            element: null,
          );
        }
      }
      _writeApiClientClass(manifest, parentManifest, buffer);
      buffer.writeln();
    }

    return buffer.toString();
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
    buffer.writeln();
    final base = sourceFileName.replaceFirst(RegExp(r'\.dart$'), '');
    buffer.writeln("import '$base.dart';");
  }

  // ---------------------------------------------------------------------------
  // API client class
  // ---------------------------------------------------------------------------

  void _writeApiClientClass(
    EntityManifest manifest,
    EntityManifest? parentManifest,
    StringBuffer buffer,
  ) {
    final entity = manifest.entityName;
    final path = manifest.path;

    // Determine whether this entity is nested under a parent.
    final hasParent = manifest.hasParent;
    final parentParamName = manifest.parentParamName; // e.g. 'postId'
    final parentParamType =
        hasParent ? manifest.parentField!.dartType : null;

    // The URL base path: '/parentPath/$parentParam/path' or '/path'.
    final parentPath =
        parentManifest?.path ?? '${manifest.parentEntityNameLower}s';
    final urlBase = hasParent
        ? '/$parentPath/\$$parentParamName/$path'
        : '/$path';

    // Named parent parameter declaration, e.g. '{required String postId}'.
    final parentParam =
        hasParent ? '{required $parentParamType $parentParamName}' : '';
    final parentParamTrailing =
        hasParent ? ', {required $parentParamType $parentParamName}' : '';

    buffer.writeln('class ${entity}ApiClient {');
    buffer.writeln('  final Dio _dio;');
    buffer.writeln();
    buffer.writeln('  ${entity}ApiClient(this._dio);');
    buffer.writeln();

    // list
    buffer.writeln('  Future<List<$entity>> list($parentParam) async {');
    buffer.writeln("    final response = await _dio.get('$urlBase');");
    buffer.writeln(
        '    return (response.data as List).map((e) => e as $entity).toList();');
    buffer.writeln('  }');
    buffer.writeln();

    // getById
    buffer.writeln(
        '  Future<$entity> getById(Object id$parentParamTrailing) async {');
    buffer.writeln("    final response = await _dio.get('$urlBase/\$id');");
    buffer.writeln('    return response.data as $entity;');
    buffer.writeln('  }');
    buffer.writeln();

    // create
    buffer.writeln(
        '  Future<$entity> create($entity ${manifest.entityNameLower}$parentParamTrailing) async {');
    buffer.writeln(
        "    final response = await _dio.post('$urlBase', data: ${manifest.entityNameLower});");
    buffer.writeln('    return response.data as $entity;');
    buffer.writeln('  }');
    buffer.writeln();

    // update
    buffer.writeln(
        '  Future<$entity> update($entity ${manifest.entityNameLower}$parentParamTrailing) async {');
    buffer.writeln(
        "    final response = await _dio.put('$urlBase/\${${manifest.entityNameLower}.id}', data: ${manifest.entityNameLower});");
    buffer.writeln('    return response.data as $entity;');
    buffer.writeln('  }');
    buffer.writeln();

    // delete
    buffer.writeln(
        '  Future<void> delete($entity ${manifest.entityNameLower}$parentParamTrailing) async {');
    buffer.writeln(
        "    await _dio.delete('$urlBase/\${${manifest.entityNameLower}.id}');");
    buffer.writeln('  }');

    buffer.writeln('}');
  }
}
