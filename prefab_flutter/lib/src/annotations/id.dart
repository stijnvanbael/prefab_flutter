/// Marks the field that holds the entity's identifier.
///
/// When no field is annotated with [@Id], a field named `id` is used. If the
/// entity has neither, code generation fails with an error. The field's Dart
/// type (`String` or `int`) is used for route parameters, providers and API
/// clients, and the field is never shown as an editable form field.
class Id {
  const Id();
}
