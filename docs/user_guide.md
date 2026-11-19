# Prefab Flutter user guide

This guide describes what Prefab Flutter generates **today** and how to use it.
Planned changes are tracked in [`backlog/tasks`](../backlog/tasks); where a
limitation has a planned fix, the task id (e.g. PF-13) is mentioned.

For installation and a minimal example, see the [README](../README.md#quick-start).

## Contents

1. [How it works](#how-it-works)
2. [Annotations](#annotations)
3. [Field widgets](#field-widgets)
4. [Validators](#validators)
5. [Generated files](#generated-files)
6. [Routes](#routes)
7. [Nested resources](#nested-resources)
8. [Configuring the HTTP client](#configuring-the-http-client)
9. [REST contract](#rest-contract)
10. [Runtime widgets](#runtime-widgets)
11. [Known limitations](#known-limitations)

## How it works

1. You annotate a plain Dart class with `@View` and its fields with
   `@Field`.
2. `build_runner` runs six generators over every library that contains a
   `@View` class. Each generator writes one file next to the source file.
3. You register the generated routes with GoRouter and wrap the app in a
   Riverpod `ProviderScope`.

The generated code depends on `flutter_riverpod`, `go_router`, `dio`, `material_ui` (Flutter 3.47+) and
`prefab_flutter_widgets`, so your app must depend on them too.

## Annotations

All annotations come from `package:prefab_flutter/prefab_flutter.dart`.

### `@View` (class)

Marks a class as a Prefab entity. Every other annotation only has an effect on
a class that also has `@View`.

| Parameter | Type | Required | Meaning |
|---|---|---|---|
| `title` | `String` | yes | Shown in the AppBar of all generated screens |
| `path` | `String` | yes | URL path segment for routes and the REST endpoint (e.g. `'products'`) |

```dart
@View(title: 'Product', path: 'products')
class Product { ... }
```

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

### `@Update` (class)

Enables editing **and** creating:

- an **Edit** action in the detail screen's AppBar,
- the `create` and `:id/edit` routes,
- `{Entity}CreateScreen` and `{Entity}EditScreen`,
- an `update()` method on the list notifier.

Without `@Update` no form screens are generated. (Separate `@Create` and
`@Update` annotations are planned in PF-14.)

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
| `form` | `FormOptions` | `FormOptions()` | Form-only settings, below |

`FormOptions` parameters:

| Parameter | Type | Default | Meaning |
|---|---|---|---|
| `widget` | `FieldWidget` | `FieldWidget.auto` | Which input widget the form uses (see [Field widgets](#field-widgets)) |
| `validators` | `List<Validator>` | `[]` | Checks run when the form is submitted (see [Validators](#validators)) |

The **first** visible `@Field` in source order is used as the item title in
the list screen and as the item name in the delete dialog.

```dart
@Field(label: 'Description', form: FormOptions(widget: FieldWidget.multilineText))
final String description;
```

> **Deprecated:** `@FormField(label:, widget:, validators:, hidden:)` is kept
> as a deprecated alias for one release and behaves like the equivalent
> `@Field`. It is replaced because its name clashes with Flutter's `FormField`
> widget. Migrate by renaming it and moving `widget` and `validators` into
> `form: FormOptions(...)`.

### `@Parent` (field)

Marks the field that holds the id of the owning entity, making this entity a
nested resource. The required argument is the parent entity class. See
[Nested resources](#nested-resources).

```dart
@Field()
@Parent(Post)
final int postId;
```

## Field widgets

`FieldWidget` selects the input widget in the create and edit forms.

| Value | Generated widget | Used automatically for |
|---|---|---|
| `auto` | Inferred from the Dart type (see the right-hand column) | — |
| `multilineText` | `TextFormField` with `maxLines: null` | — |
| `password` | `TextFormField` with `obscureText: true` | — |
| `datePicker` | Read-only `TextFormField` that opens `showDatePicker` (years 2000–2100) | `DateTime` |
| `dropdown` | `DropdownButtonFormField` over `Type.values`, labelled with `name` | enum types |
| `toggle` | `SwitchListTile` | `bool` |

With `auto`, any other type (`String`, `int`, `double`, …) gets a plain
`TextFormField`. A numeric keyboard for `int`/`double` is planned in PF-18;
time and date-time pickers in PF-17.

## Validators

`Validator` is a sealed class. Parameterless rules are static constants
(`Validator.email`); rules with a value are const factories
(`Validator.min(0)`). Rules are combined in the field's `form: FormOptions(validators: [...])` list and
checked in order; the first failing check shows its message.

| Validator | Check | Default message |
|---|---|---|
| `Validator.required` | value is not empty | `Required` |
| `Validator.email` | matches `^[^@\s]+@[^@\s]+\.[^@\s]+$` | `Invalid email address` |
| `Validator.url` | parses as an absolute URI | `Invalid URL` |
| `Validator.positive` | parses as a number greater than 0 (`positiveNumber` is a kept alias) | `Must be a positive number` |
| `Validator.nonNegative` | parses as a number >= 0 | `Must not be negative` |
| `Validator.min(n)` | parses as a number >= `n` | `Must be at least n` |
| `Validator.max(n)` | parses as a number <= `n` | `Must be at most n` |
| `Validator.minLength(n)` | at least `n` characters | `Must be at least n characters` |
| `Validator.maxLength(n)` | at most `n` characters | `Must be at most n characters` |
| `Validator.pattern(regex)` | matches the regular expression | `Invalid format` |

Every validator accepts a custom message. The factories take
`message:` (`Validator.min(0, message: 'No negatives')`,
`Validator.pattern(r'^[A-Z]+$', message: 'Capitals only')`); for the constants
use the class constructor, e.g. `RequiredValidator(message: 'Name needed')`,
`EmailValidator(message: ...)`, `UrlValidator`, `PositiveValidator`,
`NonNegativeValidator`.

Checks depend on the rendered widget:

- Text, multiline and password fields support every validator.
- On `dropdown` fields (and nullable `toggle` fields) only `required` applies;
  it checks `value == null`.
- Using any other validator on a dropdown, toggle or date picker field fails the
  build with an error naming the field.

### Nullable and optional fields

The nullability of the Dart type decides whether a field is required:

| Field type | Form behaviour | Detail screen |
|---|---|---|
| Non-nullable (`String`, `int`, `DateTime`, enum) | Required automatically (`Required`), no `Validator.required` needed | Value |
| Nullable (`String?`, `int?`, `DateTime?`, enum?) | Optional: empty input is valid and other validators are skipped when empty. Add `Validator.required` to require it | `—` (em dash) when `null` |
| `bool` | `SwitchListTile`, starts `false` | Value |
| `bool?` | Dropdown with an empty, `Yes` and `No` option; starts `null` | `—` when `null` |
| Nullable enum | Dropdown with an empty option; starts `null` | `—` when `null` |
| Nullable `DateTime` | Date picker, starts empty | `—` when `null` |

The edit form prefills nullable fields null-safely (`item.x ?? ''`).

### Saving

The Save button validates the form and builds the entity by calling the
entity's **unnamed constructor**. Each constructor parameter gets its value from:

| Parameter | Create screen | Edit screen |
|---|---|---|
| the id (`@Id` / `id`) | omitted | `widget.id` |
| the `@Parent` field | `widget.<parentId>` | `widget.<parentId>` |
| a visible `@Field` | typed form state | typed form state |
| a hidden or un-annotated field | omitted | copied from the loaded item |

Form values are converted by type: `int` / `double` / `num` are parsed from the
text field (the form rejects non-numeric input first), `DateTime`, enums and
`bool` come from their pickers, and an **empty input for a nullable field is
passed as `null`**.

Parameters that are omitted on create must be nullable, optional or have a
default value. Otherwise the generator fails with a build-time error naming the
parameter (so the id must be e.g. `final int? id;` with `this.id`). A form field
of a type the form cannot convert (anything other than `String`, `int`,
`double`, `num`, `bool`, `DateTime` or an enum) also fails the build, naming the
field.

The entity is then passed to the list notifier's `create()` (create screen) or
`update()` (edit screen) and the screen pops on success. While the request is
in flight the button is disabled and shows a progress indicator; an error is
shown in a `SnackBar` and the screen stays open.

## Generated files

For a source file `product.dart` the generator writes one library,
`product.prefab.dart`. Import that single file to use everything below; it
contains:

| Generated code | Contents |
|---|---|
| `ProductListScreen` | A `ListView` of items (or a "No items found" message when empty); tapping one opens its detail screen. With `@Update`, a floating action button opens the create screen (nested route for nested entities) and the list reloads on return |
| `ProductDetailScreen(id:)` | One `ListTile` per visible field, plus Edit/Delete actions |
| `ProductCreateScreen` and `ProductEditScreen(id:)` | Only with `@Update` |
| `productDetailProvider`, `productsProvider`, `ProductsNotifier`, `productApiClientProvider` | `productDetailProvider` (`FutureProvider.autoDispose.family` on the id), `productsProvider` (`AsyncNotifierProvider.autoDispose`) with `ProductsNotifier` (an `AutoDisposeAsyncNotifier<List<Product>>`; nested entities use `AutoDisposeFamilyAsyncNotifier` keyed on the parent id) exposing `create`, `update` and `delete` (`update` and `delete` invalidate the entity's `productDetailProvider` so detail screens refetch), and `productApiClientProvider` |
| `ProductApiClient` | `list`, `getById`, `create`, `update` and `delete`; responses are read with `Product.fromJson` and request bodies are sent as `product.toJson()` |
| `$productRoutes` | Named after the source file; a `List<RouteBase>` with the routes of every entity in the file |

A file without `@View` classes produces no output. The previous layout of six
files per source (`.list_screen.dart`, `.detail_screen.dart`, `.form_screen.dart`,
`.provider.dart`, `.api_client.dart`, `.routes.dart`) was replaced by the single
`.prefab.dart` file (PF-32); delete the old files when migrating.

### JSON serialization requirement

Every `@View` class needs a `fromJson(Map<String, dynamic> json)` factory and a
`toJson()` method; the generated API client uses them instead of casting
`response.data`. The easiest way is `json_serializable`:

```dart
@JsonSerializable()
@View(title: 'Product', path: 'products')
class Product {
  // ...fields...
  factory Product.fromJson(Map<String, dynamic> json) => _$ProductFromJson(json);
  Map<String, dynamic> toJson() => _$ProductToJson(this);
}
```

Add `json_annotation` and `json_serializable` to your `pubspec.yaml` and add
`part 'product.g.dart';`. Hand-written implementations work too. If either is
missing the build fails with an error naming the entity. List responses are
decoded with `(response.data as List).map((e) => Product.fromJson(e as Map<String, dynamic>))`.

Several `@View` classes may live in one source file; their code is combined
in the same generated files.

The edit screen loads the entity through the detail provider and fills the
form fields from it before showing the form.

## Routes

For `@View(path: 'products')` with `@Update`:

| Path | Screen |
|---|---|
| `/products` | `ProductListScreen` |
| `/products/create` | `ProductCreateScreen` |
| `/products/:id` | `ProductDetailScreen` |
| `/products/:id/edit` | `ProductEditScreen` |

Register them with:

```dart
GoRouter(routes: $productRoutes)
```

The getter name is derived from the source file name: `product.dart` gives
`$productRoutes`, `user_account.dart` gives `$userAccountRoutes`. Because every
file has a unique name, an app with entities in several source files can import
all the routes files without prefixes and concatenate the lists:

```dart
import 'product.prefab.dart';
import 'customer.prefab.dart';

final router = GoRouter(
  routes: [...$productRoutes, ...$customerRoutes],
);
```

## Nested resources

An entity with a `@Parent` field is shown under its parent:

```dart
@View(title: 'Post', path: 'posts')
class Post {
  final int? id;
  @Field() final String title;
  Post({this.id, required this.title});
}

@View(title: 'Comment', path: 'comments')
class Comment {
  final int? id;
  @Field() @Parent(Post) final int postId;
  @Field() final String body;
  Comment({this.id, required this.postId, required this.body});
}
```

Rules:

- `@Parent(Post)` names the parent entity explicitly. The parent must carry a
  `@View` annotation (its `path` is used in routes and API URLs); otherwise the
  build fails.
- The parent may be declared in the same file or in **another source file**.
  A child whose parent lives in another file is registered as a top-level route
  (`/posts/:postId/comments`) in its own routes getter (e.g. `$commentRoutes`)
  instead of being nested inside the parent's route. Register both getters.
- The type of the `@Parent` field must equal the type of the parent's `id`
  field, otherwise the build fails.
- Only one level of nesting is supported (PF-19 plans deeper chains).
- The parent field is not shown in forms or the detail screen.

Effects:

- Routes: `/posts/:postId/comments` and `/posts/:postId/comments/:id`.
- The API client calls `/posts/{postId}/comments[/{id}]`, and every method
  takes a named `postId` argument.
- `commentsProvider` is a family keyed on `postId`; `commentDetailProvider` is
  keyed on the record `(id, postId)`.

- `CommentCreateScreen` and `CommentEditScreen` take a required `postId`;
  the edit screen watches `commentDetailProvider((id, postId))`.
- The detail screen's Edit action opens `/posts/$postId/comments/$id/edit`, and
  its Delete action uses `commentsProvider(postId).notifier`.
- List and detail navigation paths are built by one shared helper, so they
  always match the routes.

## Configuring the HTTP client

Every generated `{entity}ApiClientProvider` reads
`ref.watch(prefabDioProvider)`, and the generated provider file imports
`package:prefab_flutter_widgets/prefab_flutter_widgets.dart`. `prefabDioProvider`
has no default: reading it before it is overridden throws a descriptive
`UnimplementedError`. Override it once in your root `ProviderScope`:

```dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prefab_flutter_widgets/prefab_flutter_widgets.dart';

void main() => runApp(
      ProviderScope(
        overrides: [
          prefabDioProvider.overrideWithValue(
            Dio(BaseOptions(baseUrl: 'https://api.example.com'))
              ..interceptors.add(MyAuthInterceptor()),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
```

`prefab_flutter_widgets` depends on `dio` (`>=5.4.0 <6.0.0`) and
`flutter_riverpod` (`>=2.5.0 <3.0.0`). The generated providers use the
`AsyncNotifier` API of Riverpod 2.x and no longer depend on the legacy
`StateNotifier`. Riverpod 3 is not supported yet because it removes the
`AutoDispose*` notifier base classes.

## REST contract

The generated client expects this API, relative to the Dio base URL:

| Method | URL | Body | Response |
|---|---|---|---|
| `list()` | `GET /{path}` | — | JSON array of entities |
| `getById(id)` | `GET /{path}/{id}` | — | entity |
| `create(e)` | `POST /{path}` | entity | entity |
| `update(e)` | `PUT /{path}/{e.id}` | entity | entity |
| `delete(e)` | `DELETE /{path}/{e.id}` | — | ignored |

After `create`, `update` or `delete` the list notifier reloads the whole list.

## Runtime widgets

`package:prefab_flutter_widgets/prefab_flutter_widgets.dart` exports:

| Widget / class | Used by generated code | Purpose |
|---|---|---|
| `showPrefabDeleteDialog` / `PrefabDeleteDialog<T>` | yes (detail screen) | Delete confirmation; returns `true` when the item was deleted |
| `PrefabSearchBar` | not yet (PF-13) | Search text field with an `onChanged` callback |
| `PrefabSortMenu<T>` / `PrefabSortOption<T>` | not yet (PF-13) | Popup menu to choose a sort option |
| `PrefabPaginationBar` / `PrefabPageNotifier` | not yet (PF-13) | Previous/next page controls |
| `PrefabPage<T>` | not yet (PF-13) | A page of items with total count and page metadata |

You can use these widgets in hand-written screens too.

## Known limitations

These are known gaps in the current pre-release. Each has a backlog task.

| Limitation | Workaround | Task |
|---|---|---|
| The save round-trip is covered by generator tests only; it is not yet exercised end-to-end in a running example app | — | PF-9 |
| Search, sort and pagination are not generated | — | PF-13 |
