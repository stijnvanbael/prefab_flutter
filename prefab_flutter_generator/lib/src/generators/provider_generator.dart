import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:prefab_flutter/prefab_flutter.dart';
import 'package:source_gen/source_gen.dart';

/// Generates Riverpod providers for every class annotated with [@View].
///
/// Produced providers include:
/// - `{entity}DetailProvider` — watches a single entity by ID,
/// - `{entity}sProvider` — a [StateNotifier] for the list with CRUD methods.
///
/// NOTE: Full implementation is tracked in a separate backlog task.
class ProviderGenerator extends GeneratorForAnnotation<View> {
  @override
  String generateForAnnotatedNode(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    // TODO: implement provider generation
    return '';
  }
}
