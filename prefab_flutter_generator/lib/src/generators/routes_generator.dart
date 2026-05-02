import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:prefab_flutter/prefab_flutter.dart';
import 'package:source_gen/source_gen.dart';

/// Generates GoRouter `TypedGoRoute` declarations for every class annotated
/// with [@View].
///
/// Also produces the top-level `$prefabRoutes` list that collects all entity
/// routes so they can be registered with [GoRouter] in one place.
///
/// NOTE: Full implementation is tracked in a separate backlog task.
class RoutesGenerator extends GeneratorForAnnotation<View> {
  @override
  String generateForAnnotatedNode(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    // TODO: implement routes generation
    return '';
  }
}
