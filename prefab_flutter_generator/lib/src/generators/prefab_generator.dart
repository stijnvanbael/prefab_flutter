import '../core/artifact_generator.dart';
import 'api_client_generator.dart';
import 'detail_screen_generator.dart';
import 'form_screen_generator.dart';
import 'list_screen_generator.dart';
import 'provider_generator.dart';
import 'routes_generator.dart';

/// Generates everything for a source file into one `.prefab.dart` library.
///
/// Creates the artifacts of every kind (API clients, providers, detail, list,
/// create and edit screens, routes) and lets the `LibraryEmitter` assemble
/// them: the imports are collected from the emitted artifacts, not parsed
/// from text.
class PrefabGenerator extends ArtifactGenerator {
  PrefabGenerator()
      : super('PrefabGenerator', const [
          ApiClientArtifact.create,
          createProviderArtifacts,
          DetailScreenArtifact.create,
          ListScreenArtifact.create,
          createFormScreenArtifacts,
          RoutesArtifact.create,
        ]);
}
