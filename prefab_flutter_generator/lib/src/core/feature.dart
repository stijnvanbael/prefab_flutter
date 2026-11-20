import 'declarations.dart';
import 'entity_context.dart';
import 'library_emitter.dart';

/// A feature module: reads what it needs from the [EntityContext] and adds
/// code to extension points of the artifacts in [artifacts]. It never writes
/// a whole artifact and never writes `import` lines directly.
abstract class Feature {
  const Feature();

  /// Unique name, used to order contributions and in error messages.
  String get name;

  /// New artifacts this feature adds (e.g. the edit screen), if any.
  List<ArtifactFactory> get artifacts => const [];

  /// The kinds of hand-written declaration this feature reads from the
  /// source of every library (see [DeclarationScanner]); the
  /// `prefab_declarations` builder runs them all, so a feature adds a
  /// declaration type without editing `build.yaml` or the builder.
  List<DeclarationScanner<Object>> get declarationScanners => const [];

  void contribute(EntityContext entity, ArtifactSet artifacts);
}
