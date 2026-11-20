import '../core/artifact_generator.dart';
import '../core/library_emitter.dart';
import '../features/features.dart';
import 'api_client_generator.dart';
import 'detail_screen_generator.dart';
import 'list_screen_generator.dart';
import 'provider_generator.dart';
import 'routes_generator.dart';

/// The artifact factories of the combined `.prefab.dart` library.
const List<ArtifactFactory> prefabArtifactFactories = [
  ApiClientArtifact.create,
  createProviderArtifacts,
  DetailScreenArtifact.create,
  ListScreenArtifact.create,
  RoutesArtifact.create,
];

/// Generates everything for a source file into one `.prefab.dart` library.
///
/// Creates the artifacts of every kind (API clients, providers, detail, list,
/// create and edit screens, routes) and lets the `LibraryEmitter` assemble
/// them: the imports are collected from the emitted artifacts, not parsed
/// from text.
class PrefabGenerator extends ArtifactGenerator {
  PrefabGenerator()
      : super('PrefabGenerator', prefabArtifactFactories,
            features: registeredFeatures);
}
