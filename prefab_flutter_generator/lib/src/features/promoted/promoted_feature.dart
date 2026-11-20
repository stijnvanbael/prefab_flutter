import '../../core/declarations.dart';
import '../../core/entity_context.dart';
import '../../core/feature.dart';
import '../../promoted/promoted_scanner.dart';

/// Hand-written replacements of generated artifacts (`@Promoted`).
///
/// The feature only registers the scanner; the `LibraryEmitter` skips the
/// promoted artifacts (see "Emission" in the developer guide).
class PromotedFeature extends Feature {
  const PromotedFeature();

  @override
  String get name => 'promoted';

  @override
  List<DeclarationScanner<Object>> get declarationScanners =>
      const [PromotedScanner.instance];

  @override
  void contribute(EntityContext entity, ArtifactSet artifacts) {}
}
