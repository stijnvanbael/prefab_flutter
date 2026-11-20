import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'entity_context.dart';
import 'feature.dart';
import 'library_emitter.dart';

/// A `source_gen` [Generator] that renders the artifacts of [artifactFactories]
/// through the [LibraryEmitter].
///
/// [PrefabGenerator] uses every factory; the per-kind generators (kept for
/// tests and the builders in `builder.dart`) use the factories of one kind.
class ArtifactGenerator extends Generator {
  const ArtifactGenerator(
    this.name,
    this.artifactFactories, {
    this.features = const [],
  });

  /// Printed in the banner of the generated file.
  final String name;
  final List<ArtifactFactory> artifactFactories;
  final List<Feature> features;

  @override
  String generate(LibraryReader library, BuildStep buildStep) {
    final sourceFileName = buildStep.inputId.path.split('/').last;
    final entities = EntityContext.readAll(library, sourceFileName);
    if (entities.isEmpty) return '';
    return LibraryEmitter(
      artifactFactories: artifactFactories,
      features: features,
    ).emit(entities, header: banner(name));
  }

  /// The "GENERATED CODE" comment at the top of a generated file, ending in a
  /// blank line.
  static String banner(String generatorName) {
    const sep =
        '// **************************************************************************';
    return [
      '// GENERATED CODE - DO NOT MODIFY BY HAND',
      '//',
      sep,
      '// $generatorName',
      sep,
      '',
    ].join('\n');
  }
}
