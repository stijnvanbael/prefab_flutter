// PF-37 prototype - not part of the published generator.

import 'entity_context.dart';

/// A feature module: reads what it needs from the [EntityContext] and adds
/// code to extension points of the artifacts in [artifacts]. It never
/// writes a whole artifact and never writes `import` lines directly.
abstract class Feature {
  const Feature();

  /// Unique name, used to order contributions and in error messages.
  String get name;

  void contribute(EntityContext entity, ArtifactSet artifacts);
}
