/// A part of the generated screens where a field or an action appears.
///
/// Used by the `on:` parameter of `@Field` and `@EntityAction`.
enum Place {
  /// The AppBar of the generated list screen. Actions only: the function
  /// receives no entity.
  list,

  /// Each item of the generated list screen. A field fills the item's title,
  /// subtitle or trailing slot; an action is an entry of the item's menu and
  /// receives the item.
  item,

  /// The generated detail screen. A field is shown as a labelled row; an
  /// action sits in the AppBar, receives the entity that is shown and is
  /// disabled while it is loading.
  detail,

  /// The generated create and edit screens. Fields only.
  form,
}
