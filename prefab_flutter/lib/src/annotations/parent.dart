/// Marks a field as a reference to the owning (parent) entity.
///
/// [type] is the parent entity class, which must be annotated with `@View` and
/// may be declared in another source file:
///
/// ```dart
/// @FormField() @Parent(Post) final int postId;
/// ```
///
/// List and detail screens are scoped under the parent entity's route and the
/// API path includes the parent ID as a path parameter. The type of the
/// annotated field must match the type of the parent's `id` field.
class Parent {
  /// The parent entity class.
  final Type type;

  const Parent(this.type);
}
