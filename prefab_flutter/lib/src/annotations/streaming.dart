/// Signals that the backend streams the changes of an entity as server-sent
/// events (Prefab's `@Streaming`).
///
/// When present on a class annotated with [@Entity], the generated list and
/// detail providers apply the `created`, `updated` and `deleted` events of
/// the entity's event stream, so the screens update live without a
/// subscription written by hand. The stream is opened while a screen listens
/// and closed afterwards. The URL and the event format belong to the backend
/// adapter (`PrefabBackend`).
class Streaming {
  const Streaming();
}
