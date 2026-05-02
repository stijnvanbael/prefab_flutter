import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:prefab_flutter/prefab_flutter.dart';
import 'package:source_gen/source_gen.dart';

/// Generates a `{Entity}ListScreen` [ConsumerWidget] for every class annotated
/// with [@View].
///
/// The list screen includes a search bar when searchable fields exist, sort
/// column controls when sortable fields exist, and pagination.
///
/// NOTE: Full implementation is tracked in a separate backlog task.
class ListScreenGenerator extends GeneratorForAnnotation<View> {
  @override
  String generateForAnnotatedNode(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    // TODO: implement list screen generation
    return '';
  }
}
