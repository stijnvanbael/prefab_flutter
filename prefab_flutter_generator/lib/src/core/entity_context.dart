import 'package:analyzer/dart/element/element.dart';
import 'package:prefab_flutter/prefab_flutter.dart';
import 'package:source_gen/source_gen.dart';

import '../features/actions/action_scanner.dart';
import '../manifest/entity_manifest.dart';
import '../features/entity_screens/child_screen.dart';
import '../manifest/entity_paths.dart';
import 'artifact.dart';

final _entityChecker = TypeChecker.typeNamed(Entity, inPackage: 'prefab_flutter');

/// What a feature module or artifact template knows about one entity: the
/// manifest (all annotation reading happens there) plus file-level facts.
class EntityContext {
  const EntityContext({
    required this.manifest,
    required this.paths,
    required this.sourceFileName,
    required this.element,
    required this.libraryManifests,
    this.actions = const [],
    this.childScreens = const [],
  });

  final EntityManifest manifest;
  final EntityPaths paths;

  /// File name of the annotated source, imported by every artifact.
  final String sourceFileName;

  final ClassElement element;

  /// The manifests of every entity in the same source file, in declaration
  /// order (for artifacts that span the library, such as the routes).
  final List<EntityManifest> libraryManifests;

  /// The hand-written `@EntityAction` functions of this entity, in the order
  /// they were found (see the `actions` feature).
  final List<ActionDeclaration> actions;
  /// The hand-written `@EntityScreen` classes of this entity, found anywhere
  /// in the package.
  final List<ChildScreen> childScreens;

  /// The class names of the `@Entity` classes of [library].
  static Set<String> entityNames(LibraryReader library) => {
        for (final a in library.annotatedWith(_entityChecker))
          if (a.element.name != null) a.element.name!,
      };

  /// Reads every `@Entity` class of [library] in declaration order.
  static List<EntityContext> readAll(
      LibraryReader library, String sourceFileName,
      {List<ActionDeclaration> actions = const [],
      List<ChildScreen> childScreens = const []}) {
    final annotated = library.annotatedWith(_entityChecker).toList();
    final classes = <(ClassElement, ConstantReader)>[];
    for (final a in annotated) {
      final element = a.element;
      if (element is! ClassElement) {
        throw InvalidGenerationSourceError(
          '@Entity can only be applied to classes.',
          element: element,
        );
      }
      classes.add((element, a.annotation));
    }
    final manifests = [
      for (final (element, annotation) in classes)
        EntityManifest.from(element, annotation),
    ];
    final paths = EntityPaths(manifests);
    return [
      for (var i = 0; i < manifests.length; i++)
        EntityContext(
          manifest: manifests[i],
          paths: paths,
          sourceFileName: sourceFileName,
          element: classes[i].$1,
          libraryManifests: manifests,
          actions: [
            for (final a in actions)
              if (a.entity == manifests[i].entityName) a,
          ],
          childScreens: [
            for (final s in childScreens)
              if (s.entity == manifests[i].entityName) s,
          ],
        ),
    ];
  }
}

/// The artifacts generated for one library, after skipped ones were removed.
/// Feature modules look artifacts up here; a lookup returns `null` when the
/// artifact is not generated (e.g. no `@Update`) or skipped, so a feature
/// never contributes to hand-written code.
class ArtifactSet {
  ArtifactSet(Iterable<Artifact> artifacts,
      {Iterable<Artifact> promoted = const [],
      void Function(String message)? onWarning})
      : _byId = {for (final a in artifacts) a.id: a},
        _promoted = {for (final a in promoted) a.id: a},
        _onWarning = onWarning;

  final Map<ArtifactId, Artifact> _byId;
  final Map<ArtifactId, Artifact> _promoted;
  final void Function(String message)? _onWarning;

  Iterable<Artifact> get all => _byId.values;

  T? get<T extends Artifact>(ArtifactKind kind, String entity) =>
      _byId[ArtifactId(kind, entity)] as T?;

  /// The primary name of the artifact when it is replaced by a `@Promoted`
  /// declaration, `null` otherwise. A feature that has something to add to a
  /// promoted artifact calls [warn] with it, as it cannot write to
  /// hand-written code.
  String? promotedName(ArtifactKind kind, String entity) =>
      _promoted[ArtifactId(kind, entity)]?.primaryName;

  /// Reports [message] as a build warning.
  void warn(String message) => _onWarning?.call(message);
}
