import 'package:build/build.dart';
import 'package:glob/glob.dart';
import 'package:source_gen/source_gen.dart';

import '../features/actions/action_scanner.dart';
import '../features/entity_screens/child_screen.dart';
import 'artifact.dart';
import 'declarations.dart';
import 'entity_context.dart';
import 'entity_reference.dart';
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
    this.kinds,
  });

  /// Printed in the banner of the generated file.
  final String name;
  final List<ArtifactFactory> artifactFactories;
  final List<Feature> features;

  /// When set, artifacts that features add are generated only when their
  /// kind is listed. The per-kind generators use it so that registering every
  /// feature (for its contributions) does not add the screens of the create
  /// and update features to, say, the API client output.
  final Set<ArtifactKind>? kinds;

  @override
  Future<String> generate(LibraryReader library, BuildStep buildStep) async {
    final sourceFileName = buildStep.inputId.path.split('/').last;
    final declarations = await Declarations.read(buildStep);
    final allActions = declarations.of(ActionsScanner.instance);
    final self = buildStep.inputId.uri.toString();
    final childScreens = declarations.of(ChildScreensScanner.instance);
    final own = EntityContext.entityNames(library);
    Future<Map<String, Set<String>>>? libraries;
    Future<Map<String, Set<String>>> entityLibraries() => libraries ??=
        readEntityLibraries(buildStep, scanEntityNames);
    // Only declarations that target an entity of this library; the others
    // belong to an entity of the same name in another library.
    final actions = <ActionDeclaration>[];
    for (final a in allActions) {
      if (!own.contains(a.entity) ||
          await targetsEntity(
              name: a.entity,
              libraryUri: self,
              reference: a.entityReference,
              entityLibraries: entityLibraries,
              describe: '@EntityAction on ${a.name} (${a.uri})')) {
        actions.add(a);
      }
    }
    final screens = <ChildScreen>[];
    for (final s in childScreens) {
      if (!own.contains(s.entity) ||
          await targetsEntity(
              name: s.entity,
              libraryUri: self,
              reference: s.entityReference,
              entityLibraries: entityLibraries,
              describe: '@EntityScreen ${s.className} (${s.libraryUri})')) {
        screens.add(s);
      }
    }
    final entities = EntityContext.readAll(library, sourceFileName, actions: [
      for (final a in actions) a.uri == self ? a.inSameLibrary() : a,
    ], childScreens: screens);
    final promoted = declarations.of(PromotedScanner.instance);
    await _checkChildScreens(entities, childScreens, buildStep);
    if (entities.isEmpty) return '';
    final emitter = LibraryEmitter(
      artifactFactories: artifactFactories,
      features: features,
      featureKinds: kinds,
      promoted: promoted,
    );
    await _checkPromoted(emitter, entities, promoted, buildStep);
    final mismatches = emitter.promotedMismatches(entities);
    if (mismatches.isNotEmpty) {
      throw InvalidGenerationSourceError(mismatches.join('\n'));
    }
    await _checkActions(entities, allActions, buildStep);
    final source = emitter.emit(entities, header: banner(name), onWarning: log.warning);
    return formatGenerated(source, sourceFileName);
  }

  /// Fails when an `@EntityScreen` names a class that is not an `@Entity` entity
  /// of the package.
  Future<void> _checkChildScreens(List<EntityContext> entities,
      List<ChildScreen> screens, BuildStep buildStep) async {
    final own = {for (final e in entities) e.manifest.entityName};
    var unknown = [
      for (final s in screens)
        if (!own.contains(s.entity)) s,
    ];
    if (unknown.isEmpty) return;
    final known = {...own, ...await readOtherEntityNames(buildStep)};
    unknown = [
      for (final s in unknown)
        if (!known.contains(s.entity)) s,
    ];
    if (unknown.isEmpty) return;
    final s = unknown.first;
    final closest = closestName(s.entity, known);
    throw InvalidGenerationSourceError(
      '@EntityScreen ${s.className} (${s.libraryUri}) names ${s.entity}, '
      'which is not an @Entity class'
      '${closest == null ? '' : '; did you mean $closest?'}',
    );
  }

  /// Fails when a `@Promoted` declaration names no generated artifact of the
  /// package. Names this file does not generate are looked up in the other
  /// libraries with `@Entity` classes, and only then reported.
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

  /// Fails when an `@EntityAction` names a class that is not an `@Entity` entity
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
      '@EntityAction on ${a.name} (${a.uri}): ${a.entity} is not an @Entity '
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
      '// ignore_for_file: curly_braces_in_flow_control_structures, deprecated_member_use',
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
