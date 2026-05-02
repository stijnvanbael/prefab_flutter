import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:prefab_flutter/prefab_flutter.dart';
import 'package:source_gen/source_gen.dart';

/// Generates a Dio-backed `{Entity}ApiClient` class for every class annotated
/// with [@View].
///
/// Each API client exposes methods for: list (with pagination), getById,
/// create, update and delete.
///
/// NOTE: Full implementation is tracked in a separate backlog task.
class ApiClientGenerator extends GeneratorForAnnotation<View> {
  @override
  String generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    // TODO: implement API client generation
    return '';
  }
}
