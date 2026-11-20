// PF-37 prototype - not part of the published generator. Wires the core,
// the detail screen artifact and three feature modules into a builder so it
// can be compared with today's DetailScreenGenerator.

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:prefab_flutter/prefab_flutter.dart';
import 'package:prefab_flutter_generator/src/manifest/entity_manifest.dart';
import 'package:prefab_flutter_generator/src/manifest/entity_paths.dart';
import 'package:source_gen/source_gen.dart';

import 'artifacts/detail_screen.dart';
import 'core/entity_context.dart';
import 'core/library_emitter.dart';
import 'features/breadcrumbs.dart';
import 'features/delete_action.dart';
import 'features/update_action.dart';

const _viewChecker = TypeChecker.fromRuntime(View);

class DetailScreenPrototypeGenerator extends Generator {
  DetailScreenPrototypeGenerator({this.promoted = const []});

  final List<PromotedDeclaration> promoted;

  @override
  String generate(LibraryReader library, BuildStep buildStep) {
    final manifests = [
      for (final a in library.annotatedWith(_viewChecker))
        if (a.element is ClassElement)
          EntityManifest.from(a.element as ClassElement, a.annotation),
    ];
    final paths = EntityPaths(manifests);
    final sourceFileName = buildStep.inputId.pathSegments.last;
    final entities = [
      for (final m in manifests)
        EntityContext(
            manifest: m, paths: paths, sourceFileName: sourceFileName),
    ];
    return LibraryEmitter(
      artifactFactories: [
        (e) => [DetailScreenArtifact(e)]
      ],
      // Registration order is irrelevant: contributions carry an order.
      features: const [
        DeleteActionFeature(),
        BreadcrumbsFeature(),
        UpdateActionFeature(),
      ],
      promoted: promoted,
    ).emit(entities, header: '// GENERATED CODE - DO NOT MODIFY BY HAND');
  }
}

Builder detailScreenPrototypeBuilder(
        {List<PromotedDeclaration> promoted = const []}) =>
    LibraryBuilder(
      DetailScreenPrototypeGenerator(promoted: promoted),
      generatedExtension: '.detail_prototype.dart',
    );
