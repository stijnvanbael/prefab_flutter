/// Signals that a prefab entity can be edited.
///
/// When present on a class annotated with [@View], prefab generates the
/// `{Entity}EditScreen`, the `edit` route, the **Edit** action in the detail
/// screen's AppBar and the `update()` methods on the provider and API client.
///
/// Independent of [@Create]: an entity may be create-only, edit-only, both, or
/// neither (read-only).
class Update {
  const Update();
}
