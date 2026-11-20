/// Marks a field as a reference to the owning (parent) entity.
///
/// [entity] is the parent entity class, which must be annotated with `@Entity` and
/// may be declared in another source file:
///
/// ```dart
/// @Field() @Parent(Post) final int postId;
/// ```
///
/// List and detail screens are scoped under the parent entity's route and the
/// API path includes the parent ID as a path parameter. The type of the
/// annotated field must match the type of the parent's `id` field.
class Parent {
  /// The parent entity class.
  final Type entity;

  const Parent(this.entity);
}
