import '../../core/entity_context.dart';
import '../../core/feature.dart';

/// Form field validators (`@Field.validators`).
///
/// The checks are one `ValidatorEmitter` per `Validator` in
/// `validator_emitters.dart`, registered in `validatorEmitters`. The form
/// template looks them up per field, so this feature adds no code to extension
/// points.
class ValidatorsFeature extends Feature {
  const ValidatorsFeature();

  @override
  String get name => 'validators';

  @override
  void contribute(EntityContext entity, ArtifactSet artifacts) {}
}
