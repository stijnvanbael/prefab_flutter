[← User guide](../user_guide.md)

# Annotations

All annotations come from `package:prefab_flutter/prefab_flutter.dart`.

### `@View` (class)

Marks a class as a Prefab entity. Every other annotation only has an effect on
a class that also has `@View`.

| Parameter | Type | Required | Meaning |
|---|---|---|---|
| `title` | `String?` | no (class name in title case: `ProductOrder` → `Product Order`) | Shown in the AppBar of all generated screens |
| `path` | `String?` | no (kebab-case plural of the class name: `ProductOrder` → `product-orders`) | URL path segment for routes and the REST endpoint (e.g. `'products'`) |
| `paged` | `bool` | no (`true`) | Page the list on the server. With `false` the list is requested in one go (no `page`/`size` parameters) and the list screen has no pagination bar |

```dart
@View()                                      // title 'Product', path 'products'
class Product { ... }

@View(title: 'Product', path: 'products')    // explicit, same result
class Product { ... }
```

The default `path` pluralises the last word of the class name with a small
rule: consonant + `y` → `ies` (`Category` → `categories`); ending in `s`,
`x`, `z`, `ch` or `sh` → `es` (`Box` → `boxes`); otherwise `s` is appended.
Irregular plurals (`Person`) need an explicit `path`. Explicit values are
always used as given.

The entity needs an identifier: a field annotated with [`@Id`](#id-field) or,
failing that, a field named `id`. See [`@Id`](#id-field).

### `@Id` (field)

Marks the field that holds the entity's identifier. When no field carries
`@Id`, a field named `id` is used; when neither exists the generator fails with
a build-time error (as it does for more than one `@Id`, or an id type other than
`String` or `int`).

```dart
@Id()
final String sku;
```

The id's Dart type is used everywhere instead of `Object`: routes convert the
`:id` path parameter (`int.parse` for `int`, as-is for `String`) before passing
it to `{Entity}DetailScreen(id:)` / `{Entity}EditScreen(id:)`, and the detail
and edit providers, screens and API client `getById` take the typed id. Parent
ids (`@Parent` fields) are converted the same way based on their own type. The
id field is never shown as an editable form or detail field, and the generated
URLs use its name (e.g. `/{path}/${entity.sku}`).

### `@Create` (class)

Enables creating:

- the `create` route and `{Entity}CreateScreen`,
- the floating action button on the list screen,
- `create()` on the list notifier and the API client.

### `@Update` (class)

Enables editing:

- an **Edit** action in the detail screen's AppBar,
- the `:id/edit` route and `{Entity}EditScreen`,
- `updateEntity()` on the list notifier and the API client.

`@Create` and `@Update` are independent, so an entity can be create-only
(e.g. audit log entries), edit-only, both, or read-only (neither). Without
either annotation no form screens are generated.

> **Migration:** `@Update` used to enable creating as well. Add `@Create()`
> next to `@Update()` to keep the previous behaviour.

### `@Delete` (class)

Adds a **Delete** action to the detail screen's AppBar. It opens a
confirmation dialog (`showPrefabDeleteDialog`), calls the notifier's
`delete()` and pops back to the list. It also adds `delete()` to the list
notifier.

### `@Field` (field)

Includes a field in the generated screens. Fields without `@Field` are
ignored by every generator. Display and listing settings sit directly on
`@Field`; form-only settings go in its `form:` parameter
(`FormOptions`).

| Parameter | Type | Default | Meaning |
|---|---|---|---|
| `label` | `String?` | field name in title case (`firstName` → `First Name`) | Label in forms and the detail screen |
| `hidden` | `bool` | `false` | Exclude the field from forms and the detail screen |
| `views` | `Set<String>?` | `null` (all views) | Views the field appears in: `'list'`, `'detail'` (see [Views](#views)) |
| `searchable` | `bool` | `false` | The list screen shows a search bar (once any field is searchable); the text is sent to the server as `q` (see [Search, sorting and pagination](rest-contract.md#search-sorting-and-pagination)) |
| `sortable` | `bool` | `false` | The list screen's sort menu offers this field ascending and descending |
| `form` | `FormOptions` | `FormOptions()` | Form-only settings, below |

`FormOptions` parameters:

| Parameter | Type | Default | Meaning |
|---|---|---|---|
| `widget` | `FieldWidget` | `FieldWidget.auto` | Which input widget the form uses (see [Field widgets](field-widgets.md#field-widgets)) |
| `validators` | `List<Validator>` | `[]` | Checks run when the form is submitted (see [Validators](validators.md#validators)) |

The **first** visible `@Field` in source order is used as the item title in
the list screen (unless `views` is used, see below) and as the item name in
the delete dialog.

#### Views

`views` controls where a field is shown. A field without `views` appears in
every view. The generators use two view names:

| View | Screen | Slot mapping |
|---|---|---|
| `'list'` | List screen | The first, second and third field in the view fill the `ListTile` `title`, `subtitle` and `trailing` slots; further fields are ignored |
| `'detail'` | Detail screen | All fields in the view are listed; if none is in the view, all visible fields are shown |

When no field of an entity declares `views`, the list tile shows only the
first visible field as its title, exactly as before. Forms are not affected
by `views`.

```dart
@Field(views: {'list', 'detail'})
final String name;

@Field(views: {'detail'})
final String description;
```

```dart
@Field(label: 'Description', form: FormOptions(widget: FieldWidget.multilineText))
final String description;
```

> **Deprecated:** `@FormField(label:, widget:, validators:, hidden:)` is kept
> as a deprecated alias for one release and behaves like the equivalent
> `@Field`. It is replaced because its name clashes with Flutter's `FormField`
> widget. Migrate by renaming it and moving `widget` and `validators` into
> `form: FormOptions(...)`.

### `@Promoted` (class or variable)

Takes over one generated artifact as hand-written code: the generator stops
producing the artifact named like the annotated top-level declaration. See
[Promoting generated code](promoting.md).

### `@Parent` (field)

Marks the field that holds the id of the owning entity, making this entity a
nested resource. The required argument is the parent entity class. See
[Nested resources](nested-resources.md#nested-resources).

```dart
@Field()
@Parent(Post)
final int postId;
```
