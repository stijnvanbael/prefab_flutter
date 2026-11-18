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
   `@FormField`.
2. `build_runner` runs six generators over every library that contains a
   `@View` class. Each generator writes one file next to the source file.
3. You register the generated routes with GoRouter and wrap the app in a
   Riverpod `ProviderScope`.

The generated code depends on `flutter_riverpod`, `go_router`, `dio`, `material_ui` (Flutter 3.47+) and
`prefab_flutter_widgets`, so your app must depend on them too.

## Annotations

All annotations come from `package:prefab_flutter/prefab_flutter.dart`.

> `@FormField` has the same name as Flutter's `FormField` widget. In a file
> that imports both `package:material_ui/material_ui.dart` and `prefab_flutter`,
> hide one of them, e.g.
> `import 'package:material_ui/material_ui.dart' hide FormField;`. Keeping entity
> classes in files without Flutter imports avoids the problem.

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

### `@FormField` (field)

Includes a field in the generated screens. Fields without `@FormField` are
ignored by every generator.

| Parameter | Type | Default | Meaning |
|---|---|---|---|
| `label` | `String?` | field name in title case (`firstName` → `First Name`) | Label in forms and the detail screen |
| `widget` | `FieldWidget` | `FieldWidget.auto` | Which input widget the form uses (see [Field widgets](#field-widgets)) |
| `validators` | `List<Validator>` | `[]` | Checks run when the form is submitted (see [Validators](#validators)) |
| `hidden` | `bool` | `false` | Exclude the field from forms and the detail screen |

The **first** visible `@FormField` in source order is used as the item title in
the list screen and as the item name in the delete dialog.

```dart
@FormField(label: 'Description', widget: FieldWidget.multilineText)
final String description;
```

### `@Parent` (field)

Marks the field that holds the id of the owning entity, making this entity a
nested resource. The required argument is the parent entity class. See
[Nested resources](#nested-resources).

```dart
@FormField()
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

`Validator` values are combined in the field's `validators` list and checked in
order; the first failing check shows its message.

| Value | Check | Message |
|---|---|---|
| `required` | value is not empty | `Required` |
| `email` | matches `^[^@\s]+@[^@\s]+\.[^@\s]+$` | `Invalid email address` |
| `positiveNumber` | parses as a number greater than 0 | `Must be a positive number` |
| `url` | parses as an absolute URI | `Invalid URL` |

Validators are not applied to `toggle` fields. On `dropdown` fields the
generated checks assume a `String` value and do not compile (PF-31). Nothing is required by default,
including non-nullable fields (PF-15 plans to infer this). Parameterised
validators such as `min(0)` or `pattern(...)` are planned in PF-31.

## Generated files

For a source file `product.dart` the generator writes:

| File | Contents |
|---|---|
| `product.list_screen.dart` | `ProductListScreen`: a `ListView` of items; tapping one opens its detail screen |
| `product.detail_screen.dart` | `ProductDetailScreen(id:)`: one `ListTile` per visible field, plus Edit/Delete actions |
| `product.form_screen.dart` | `ProductCreateScreen` and `ProductEditScreen(id:)` (only with `@Update`) |
| `product.provider.dart` | `productDetailProvider` (`FutureProvider.autoDispose.family` on the id), `productsProvider` (`StateNotifierProvider`) with `ProductsNotifier`, and `productApiClientProvider` |
| `product.api_client.dart` | `ProductApiClient` with `list`, `getById`, `create`, `update` and `delete` |
| `product.routes.dart` | `$productRoutes` (named after the source file), a `List<RouteBase>` with the routes of every entity in the file |

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
import 'product.routes.dart';
import 'customer.routes.dart';

final router = GoRouter(
  routes: [...$productRoutes, ...$customerRoutes],
);
```

## Nested resources

An entity with a `@Parent` field is shown under its parent:

```dart
@View(title: 'Post', path: 'posts')
class Post {
  final int id;
  @FormField() final String title;
  Post({required this.id, required this.title});
}

@View(title: 'Comment', path: 'comments')
class Comment {
  final int id;
  @FormField() @Parent(Post) final int postId;
  @FormField() final String body;
  Comment({required this.id, required this.postId, required this.body});
}
```

Rules:

- `@Parent(Post)` names the parent entity explicitly. The parent must carry a
  `@View` annotation (its `path` is used in routes and API URLs); otherwise the
  build fails.
- The parent may be declared in the same file or in **another source file**.
  A child whose parent lives in another file is registered as a top-level route
  (`/posts/:postId/comments`) in its own `$prefabRoutes` instead of being
  nested inside the parent's route.
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
`flutter_riverpod` (`>=2.5.0 <3.0.0`).

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
| Responses are cast (`as Product`) instead of deserialized, so every request fails at runtime | None yet | PF-12 |
| The Save button validates and closes the form but does not save | None yet | PF-11 |
| The list screen has no button to open the create screen | Navigate to `/{path}/create` yourself | PF-26 |
| The detail screen shows stale data after an edit | Invalidate `{entity}DetailProvider` yourself | PF-28 |
| Nullable fields are not handled (`null` shows as the text "null"; prefill may not compile) | Use non-nullable fields | PF-15 |
| `Validator.required` on an enum dropdown emits `value.isEmpty` and does not compile | Leave validators off dropdown fields | PF-31 |
| `@FormField` clashes with Flutter's `FormField` | `hide FormField` on one import | PF-30 |
| Search, sort and pagination are not generated | — | PF-13 |
