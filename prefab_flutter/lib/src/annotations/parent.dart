/// Marks a field as a reference to the owning (parent) entity.
///
/// When present on a field in a [@View] entity, list and detail screens are
/// scoped under the parent entity's route and the API path includes the parent
/// ID as a path parameter.
class Parent {
  const Parent();
}
