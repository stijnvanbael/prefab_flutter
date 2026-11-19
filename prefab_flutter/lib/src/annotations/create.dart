/// Signals that a prefab entity can be created.
///
/// When present on a class annotated with [@View], prefab generates the
/// `{Entity}CreateScreen`, the `create` route, the create button on the list
/// screen and the `create()` methods on the provider and API client.
///
/// Independent of [@Update]: an entity may be create-only, edit-only, both, or
/// neither (read-only).
class Create {
  const Create();
}
