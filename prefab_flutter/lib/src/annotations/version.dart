/// Marks the field that holds the entity's version for optimistic locking.
///
/// When no field is annotated with [@Version], a field named `version` is
/// used; an entity without one is not locked. The generated update sends the
/// version as the backend adapter says (a body field or an `If-Match` header)
/// and a `409 Conflict` answer opens a "changed by someone else" dialog on the
/// edit screen. The field is never shown as an editable form field; the edit
/// form sends the version of the item it loaded.
class Version {
  const Version();
}
