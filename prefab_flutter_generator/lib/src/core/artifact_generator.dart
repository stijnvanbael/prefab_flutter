import 'package:build/build.dart';
import 'package:glob/glob.dart';
import 'package:source_gen/source_gen.dart';

import '../features/actions/action_scanner.dart';
import 'entity_context.dart';
import 'feature.dart';
import '../promoted/promoted_scanner.dart';
import 'format.dart';
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
  Future<String> generate(LibraryReader library, BuildStep buildStep) async {
    final sourceFileName = buildStep.inputId.path.split('/').last;
    final allActions = await readActions(buildStep);
    final self = buildStep.inputId.uri.toString();
    final entities = EntityContext.readAll(library, sourceFileName, actions: [
      for (final a in allActions) a.uri == self ? a.inSameLibrary() : a,
    ]);
    final promoted = await readPromoted(buildStep);
    if (entities.isEmpty) return '';
    final emitter = LibraryEmitter(
      artifactFactories: artifactFactories,
      features: features,
      promoted: promoted,
    );
    await _checkPromoted(emitter, entities, promoted, buildStep);
    await _checkActions(entities, allActions, buildStep);
    final source = emitter.emit(entities, header: banner(name));
    return formatGenerated(source, sourceFileName);
  }

  /// Fails when a `@Promoted` declaration names no generated artifact of the
  /// package. Names this file does not generate are looked up in the other
  /// libraries with `@View` classes, and only then reported.
  Future<void> _checkPromoted(LibraryEmitter emitter,
      List<EntityContext> entities,
      List<PromotedDeclaration> promoted, BuildStep buildStep) async {
    if (promoted.isEmpty) return;
    final known = emitter.artifactNames(entities).toSet();
    var unknown = [
      for (final p in promoted)
        if (!known.contains(p.name)) p,
    ];
    if (unknown.isEmpty) return;
    final self = buildStep.inputId;
    final ids = await buildStep.findAssets(Glob('lib/**.dart')).toList()
      ..sort((a, b) => a.path.compareTo(b.path));
    for (final id in ids) {
      if (id == self ||
          id.path.endsWith('.prefab.dart') ||
          id.path.endsWith('.g.dart') ||
          !await buildStep.resolver.isLibrary(id)) {
        continue;
      }
      final other = await buildStep.resolver.libraryFor(id);
      final others = EntityContext.readAll(
          LibraryReader(other), id.path.split('/').last);
      known.addAll(emitter.artifactNames(others));
    }
    unknown = [
      for (final p in unknown)
        if (!known.contains(p.name)) p,
    ];
    if (unknown.isEmpty) return;
    final p = unknown.first;
    final closest = closestName(p.name, known);
    throw InvalidGenerationSourceError(
      '@Promoted ${p.name} (${p.libraryUri}) is not a generated artifact'
      '${closest == null ? '' : '; did you mean $closest?'}',
    );
  }

  /// Fails when an `@EntityAction` names a class that is not a `@View` entity
  /// of the package. Entities of other libraries are looked up like in
  /// [_checkPromoted], and only when this file does not have the entity.
  Future<void> _checkActions(List<EntityContext> entities,
      List<ActionDeclaration> actions, BuildStep buildStep) async {
    if (actions.isEmpty) return;
    final known = {for (final e in entities) e.manifest.entityName};
    var unknown = [
      for (final a in actions)
        if (!known.contains(a.entity)) a,
    ];
    if (unknown.isEmpty) return;
    final self = buildStep.inputId;
    final ids = await buildStep.findAssets(Glob('lib/**.dart')).toList()
      ..sort((a, b) => a.path.compareTo(b.path));
    for (final id in ids) {
      if (id == self ||
          id.path.endsWith('.prefab.dart') ||
          id.path.endsWith('.g.dart') ||
          !await buildStep.resolver.isLibrary(id)) {
        continue;
      }
      final other = await buildStep.resolver.libraryFor(id);
      known.addAll([
        for (final e in EntityContext.readAll(
            LibraryReader(other), id.path.split('/').last))
          e.manifest.entityName,
      ]);
    }
    unknown = [
      for (final a in unknown)
        if (!known.contains(a.entity)) a,
    ];
    if (unknown.isEmpty) return;
    final a = unknown.first;
    final closest = closestName(a.entity, known);
    throw InvalidGenerationSourceError(
      '@EntityAction on ${a.name} (${a.uri}): ${a.entity} is not a @View '
      'entity${closest == null ? '' : '; did you mean $closest?'}',
    );
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

/// The entry of [names] closest to [name] by edit distance, or `null` when
/// none is reasonably close.
String? closestName(String name, Iterable<String> names) {
  String? best;
  var bestDistance = 1 << 30;
  for (final n in names) {
    final d = _distance(name.toLowerCase(), n.toLowerCase());
    if (d < bestDistance) {
      best = n;
      bestDistance = d;
    }
  }
  return bestDistance <= (name.length / 2).ceil() ? best : null;
}

int _distance(String a, String b) {
  var prev = List.generate(b.length + 1, (i) => i);
  for (var i = 1; i <= a.length; i++) {
    final cur = [i, ...List.filled(b.length, 0)];
    for (var j = 1; j <= b.length; j++) {
      cur[j] = [
        prev[j] + 1,
        cur[j - 1] + 1,
        prev[j - 1] + (a[i - 1] == b[j - 1] ? 0 : 1),
      ].reduce((x, y) => x < y ? x : y);
    }
    prev = cur;
  }
  return prev[b.length];
}
