[← User guide](../user_guide.md)

# Annotations

All annotations come from `package:prefab_flutter/prefab_flutter.dart`.

### `@Entity` (class)

Marks a class as a Prefab entity. Every other annotation only has an effect on
a class that also has `@Entity`.

| Parameter | Type | Required | Meaning |
|---|---|---|---|
| `title` | `String?` | no (class name in title case: `ProductOrder` → `Product Order`) | Shown in the AppBar of all generated screens |
| `path` | `String?` | no (kebab-case plural of the class name: `ProductOrder` → `product-orders`) | URL path segment for routes and the REST endpoint (e.g. `'products'`) |
| `paged` | `bool` | no (`true`) | Page the list on the server. With `false` the list is requested in one go (no `page`/`size` parameters) and the list screen has no pagination bar |

```dart
@Entity()                                      // title 'Product', path 'products'
class Product { ... }

@Entity(title: 'Product', path: 'products')    // explicit, same result
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

### `@Version` (field)

Marks the field that holds the entity's version for optimistic locking. When no
field carries `@Version`, a field named `version` is used; an entity with
neither is not locked. More than one `@Version` field, or one that is also the
`@Id`, is a build-time error.

```dart
@Version()
final int? version;
```

The version field is never shown as an editable form or detail field. The edit
form sends the version of the item it loaded, so an update of a stale item is
rejected by the server with `409 Conflict`. How the version travels is set by
the [backend adapter](rest-contract.md#optimistic-locking): in the JSON body
(the default of the Prefab preset) or in the `If-Match` header. On a 409 the
edit screen shows a "Changed by someone else" dialog: **Reload** refreshes the
detail provider and refills the form with the latest version (the input is
discarded), **Cancel** keeps the form as it is. Merging the user's input into
the latest version is not done.

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

#### Named operations: `@Update(path: ...)`

With a `path`, `@Update` declares a **named operation** instead of marking the
entity as editable (Prefab's `@Update(path = "send")`). It is repeatable and
needs no `@Update()` without a path, and it does not generate the edit screen.

```dart
class ScheduleParameters {
  @Field(form: FormOptions(validators: [Validator.required]))
  final DateTime sendOn;
  const ScheduleParameters({required this.sendOn});
  Map<String, dynamic> toJson() => {'sendOn': sendOn.toIso8601String()};
}

@Entity()
@Update(path: 'send', label: 'Send', icon: 'send', confirm: 'Send the invoice?')
@Update(path: 'schedule', parameters: ScheduleParameters, on: {Place.item})
class Invoice { ... }
```

| Parameter | Meaning |
|---|---|
| `path` | The URL segment after the id (`/invoices/1/send`). Letters and digits, words separated by `-` or `_` (`mark-paid`). The method name is the camel-cased path (`markPaid`). `edit`, `create` and the names of the generated methods (`update`, `delete`, `list`, ...) are not allowed |
| `label` | Button text and tooltip; default: the path in words (`mark-paid` gives `Mark paid`) |
| `icon` | A member of Flutter's `Icons` as a string; default `Icons.bolt` |
| `on` | `{Place.detail}` (default) and/or `Place.item` |
| `confirm` | The question of a confirmation dialog; without it the operation runs at once. Only for operations without `parameters` |
| `parameters` | A class with `@Field` fields (same field widgets and validators as an entity), an unnamed constructor and a `toJson()` method. Its JSON is the request body |
| `order` | Sort key among the operations and the [actions](actions.md), default `0` |

Every operation adds:

- `Future<void> send(id)` (and `send(id, parameters)`) on the API client, which
  calls `POST {path}/{id}/send` (method and body come from the backend adapter,
  see [REST contract](rest-contract.md#named-operations));
- the same method on the list notifier, which refreshes the detail provider
  of the entity and reloads the list;
- a button in the detail screen's AppBar and/or the menu of each list item,
  rendered like [actions](actions.md);
- for an operation **without** `parameters`: the button confirms (when
  `confirm` is set), runs the operation and shows a failure's Problem Details
  message in a snack bar (`runPrefabOperation`);
- for an operation **with** `parameters`: the button opens
  `{Entity}{Operation}Screen` (`InvoiceScheduleScreen`, route
  `/invoices/:id/schedule`), a form with the fields of the parameters class.
  Server validation errors (`errors` in the Problem Details) appear under
  their field.

A promoted detail screen does not show the operations; the build warns, and
`on: {Place.item}` still works.

### `@Delete` (class)

Adds a **Delete** action to the detail screen's AppBar. It opens a
confirmation dialog (`showPrefabDeleteDialog`), calls the notifier's
`delete()` and pops back to the list. It also adds `delete()` to the list
notifier.

### `@Streaming` (class)

Opts the entity in to **live updates**: the backend streams its changes as
server-sent events and the generated providers apply them, so list and detail
screens update without a refresh. Mirrors Prefab's `@Streaming`. Without the
annotation nothing changes. The URL and the event format are described in
[Live updates](rest-contract.md#live-updates-streaming).

* The **detail provider** becomes a `StreamProvider` (still read with
  `ref.watch(productDetailProvider(id))`): it loads the entity, then follows
  its `created` and `updated` events. A `deleted` event fails the provider
  with `PrefabEntityDeleted`.
* The **list notifier** applies the events to the page it holds and has a
  `reload()` method. Events for items that do not belong on the page are not
  inserted, see [Live updates](rest-contract.md#live-updates-streaming).
* The **list screen** shows a `PrefabNewItemsBanner` ("2 new items", with a
  Refresh button) while `PrefabPage.newItems` is above 0.
* The **API client** gets `eventsUrl()` (with the ancestor ids of a nested
  entity).

The stream is open only while a screen listens to one of these providers.

### `@Field` (field)

Includes a field in the generated screens. Fields without `@Field` are
ignored by every generator. Display and listing settings sit directly on
`@Field`; form-only settings go in its `form:` parameter
(`FormOptions`).

| Parameter | Type | Default | Meaning |
|---|---|---|---|
| `label` | `String?` | field name in title case (`firstName` → `First Name`) | Label in forms and the detail screen |
| `on` | `Set<Place>?` | `null` (every place) | Places the field appears in: `Place.item`, `Place.detail`, `Place.form`; `{}` shows it nowhere (see [Places](#places)) |
| `searchable` | `bool` | `false` | The list screen shows a search bar (once any field is searchable); the text is sent to the server as `q` (see [Search, sorting and pagination](rest-contract.md#search-sorting-and-pagination)) |
| `sortable` | `bool` | `false` | The list screen's sort menu offers this field ascending and descending |
| `filterable` | `bool` | `false` | The list screen shows a filter control for the field, chosen from its type: enum chips, Yes / No chips for `bool`, a date range for `DateTime`, a text field (with suggestions when the backend has an autocomplete endpoint) for other types. The value is sent as a query parameter named by the JSON name (see [Filters](rest-contract.md#filters)) |
| `displayBuilder` | `Function?` | `null` | A hand-written widget (`ColorSwatch.new`) that shows the value in the detail screen and list tile (see [Custom widgets](field-widgets.md#custom-widgets-for-one-field)) |
| `readOnly` | `bool` | `false` | The server owns the value (timestamps, status, totals): shown in the list and detail screens, never in a form or a request body (see [Request bodies](#request-bodies)) |
| `form` | `FormOptions` | `FormOptions()` | Form-only settings, below |

`FormOptions` parameters:

| Parameter | Type | Default | Meaning |
|---|---|---|---|
| `widget` | `FieldWidget` | `FieldWidget.auto` | Which input widget the form uses (see [Field widgets](field-widgets.md#field-widgets)) |
| `validators` | `List<Validator>` | `[]` | Checks run when the form is submitted (see [Validators](validators.md#validators)) |
| `builder` | `Function?` | `null` | A hand-written form widget (`ColorField.new`) that replaces the generated one; `widget` is then ignored (see [Custom widgets](field-widgets.md#custom-widgets-for-one-field)) |
| `on` | `Set<FormMode>?` | `null` (both forms) | `{FormMode.create}` limits the field to the create form, `{FormMode.update}` to the edit form (see [Request bodies](#request-bodies)) |

The **first** visible `@Field` in source order is used as the item title in
the list screen (unless a field names its places, see below) and as the item name in
the delete dialog.

#### Request bodies

The create and the update request carry only the fields that belong to them.
Prefab Flutter infers this; the annotations only say where the model differs:

| Field | Create form and body | Edit form | Update body |
|---|---|---|---|
| the id | never | never | sent (it is also in the URL) |
| the `@Parent` field | sent | never | sent |
| a `@Field` | yes | yes | yes |
| `FormOptions(on: {FormMode.create})` | yes | no | **no** |
| `FormOptions(on: {FormMode.update})` | no | yes | yes |
| `@Field(readOnly: true)` | no | no | **no** |
| a field outside the form (`on` without `Place.form`) | no | no | yes (the loaded value) |
| un-annotated | no | no | yes (the loaded value) |

The create body is a whitelist: a field that no form of the create screen
shows (including every un-annotated one) is not sent. The names in the body are
the JSON names (`@JsonKey`, `fieldRename`). A required constructor parameter
that the create form does not fill, such as a server-set timestamp, gets a
placeholder in the generated create screen (`''`, `0`, `0.0`, `false`,
`DateTime.fromMillisecondsSinceEpoch(0)`, `Duration.zero` or the first enum
value) so you need no dummy values; the placeholder is never sent. Other types
still fail the build; make such a parameter nullable. The id of a
version-checked entity is planned in PF-52.

```dart
@Field(form: FormOptions(on: {FormMode.create}))
final String sku;          // set once at creation

@Field(readOnly: true)
final DateTime createdAt;  // shown, never sent
```

#### Places

`on` controls where a field is shown. A field without `on` appears in every
place. Fields use three of the four `Place` values:

| Place | Screen | Fields |
|---|---|---|
| `Place.item` | Each item of the list screen | The first, second and third field on `item` fill the `title`, `subtitle` and `trailing` slots of the item (a `ListTile` unless [`PrefabTheme.listItemBuilder`](runtime-widgets.md#theming) says otherwise); further fields are ignored |
| `Place.detail` | Detail screen | All fields on `detail` are listed |
| `Place.form` | Create and edit screens | All fields on `form` get an input; on edit, the other fields keep their stored value |

`Place.list` (the list screen's AppBar) is for [actions](actions.md) only; on
a field it fails the build. When no field of an entity names its places, the
list item shows only the first visible field as its title. `on: {}` keeps
the field in the model (and in the edit request) but shows it nowhere.

```dart
@Field(on: {Place.item, Place.detail, Place.form})
final String name;

@Field(on: {Place.detail, Place.form})
final String description;
```

```dart
@Field(label: 'Description', form: FormOptions(widget: FieldWidget.multilineText))
final String description;
```

### `@Promoted` (class or variable)

Takes over one generated artifact as hand-written code: the generator stops
producing the artifact named like the annotated top-level declaration. See
[Promoting generated code](promoting.md).

### `@EntityScreen` (class)

Declares a hand-written screen as a child of an entity: `@EntityScreen(Site,
path: 'live', title: 'Live')`. The generator adds its route below the entity's
detail route, a link on the detail screen and a breadcrumb helper. See
[Hand-written screens below an entity](routes.md#hand-written-screens-below-an-entity).

### `@Parent` (field)

Marks the field that holds the id of the owning entity, making this entity a
nested resource. The required argument is the parent entity class. See
[Nested resources](nested-resources.md#nested-resources).

```dart
@Field()
@Parent(Post)
final int postId;
```
