---
id: decision-2
title: Vocabulary
date: '2026-11-20'
status: accepted
---

## Context

After M1 the annotations used several words for the same thing and one word
for several things:

- "view" meant the class marker (`@View`), the places a field is shown
  (`Field.views: {'list', 'detail'}`) and, in Prefab itself, a read model of
  an aggregate (`@ViewOf`). A Prefab Flutter model can mirror a Prefab view,
  so `@View` would mean something else on each side of the wire.
- Hand-written additions were called `@EntityAction` and `@EntityScreen`,
  while the class they target was marked `@View`.
- Where an action appears was a typed `ActionPlace`; where a field appears
  was a set of strings.
- Custom widgets were `FormOptions.custom` and `Field.display`, while their
  contracts are `PrefabFieldBuilder` and `PrefabDisplayBuilder`.

Nothing is published yet (pre-release, PF-10), so renaming is cheap now and
expensive once the reference apps adopt the API.

## Decision

The terms below are the vocabulary of Prefab Flutter. Annotations, parameters,
generated names, runtime classes, documentation and backlog tasks use them,
and only them, with these meanings. New features pick their names from this
list or extend it in this record first.

### Terms

| Term | Meaning | Appears as |
|---|---|---|
| **Entity** | A model class Prefab Flutter generates an app for. It mirrors a Prefab aggregate or a Prefab view on the server. | `@Entity`; `{Entity}` / `{entity}` in generated names |
| **Field** | A property of an entity that the generated screens use. | `@Field` |
| **Id** | The field that identifies an entity. | `@Id` |
| **Parent** | The entity another entity is nested under. | `@Parent(Entity)` |
| **Operation** | A change the server performs on an entity: create, update, delete, or a named operation (`send`). Names as in Prefab. | `@Create`, `@Update`, `@Delete`, `@Update(path:)`; API client and notifier methods |
| **Live update** | A change of an entity the backend pushes as a server-sent event (created, updated, deleted); the generated providers apply it. | `@Streaming`, `PrefabEvent`, `prefabEventsProvider` |
| **Job** | An entity the server keeps working on for a while after creating it (a generated summary, an import). Its status field says whether it is running, done or failed; the screens show the state and refresh until it is final. | `@JobStatus`, `PrefabJobState`, `PrefabJobBanner` |
| **Screen** | A full page. Generated: list screen, detail screen, create screen, edit screen. Hand-written: entity screen. | `{Entity}ListScreen`, `{Entity}DetailScreen`, `{Entity}CreateScreen`, `{Entity}EditScreen`, `@EntityScreen` |
| **Place** | A part of the generated screens where a field or an action appears: `list` (the list screen's app bar), `item` (each item of the list), `detail` (the detail screen), `form` (the create and edit screens). | `Place`; the `on:` parameter |
| **Action** | A hand-written function started from a generated screen. | `@EntityAction` |
| **Field widget** | The input a form uses for a field. | `FieldWidget`, `FormOptions.widget` |
| **Builder** | A hand-written widget constructor or function that replaces a generated widget. | `FormOptions.builder`, `Field.displayBuilder`, `PrefabTheme` builders |
| **Validator** | A rule a form checks before it saves. | `Validator` |
| **Artifact** | One generated top-level declaration (a screen, provider, API client or route). | The name passed to `@Promoted` and `promote` |
| **Promote** | Take over one artifact as hand-written code; the generator stops generating it. | `@Promoted`, `dart run prefab_flutter_generator:promote` |

### Naming rules

1. **Mirror Prefab.** Where Prefab has an annotation for the same concept,
   use its name (`@Create`, `@Update`, `@Delete`, `@Parent`, `@Id`; later
   `@Filter`, `@Version`, `@Autocomplete`). Never reuse a
   Prefab name with another meaning; this is why the marker is `@Entity`, not
   `@View` or `@Aggregate` (a model may mirror a Prefab view).
2. **`@Entity<Thing>` attaches hand-written code to an entity.** It
   annotates the hand-written declaration and takes the entity type as its
   first positional argument, named `entity` (`@EntityAction(Product, ...)`,
   `@EntityScreen(Product, ...)`). `@Parent(Product)` follows the same
   argument name.
3. **`title` heads a screen; `label` names something inside one.** Entities
   and entity screens have a `title`; fields and actions have a `label`.
4. **`on:` says where something appears**, as a `Set<Place>`. There is no
   other parameter for visibility.
5. **Code says the operation; the user interface says what the user does.**
   Annotations, API client methods and notifier methods say `create`,
   `update`, `delete`. Screens, routes and button texts say Create, Edit and
   Delete (`{Entity}EditScreen`, `/products/1/edit`). The notifier's
   `updateEntity` is the one exception, because Riverpod's `AsyncNotifier`
   already has `update`.
6. **A parameter that takes a builder ends in `builder`**, after the typedef
   it must match (`builder` for `PrefabFieldBuilder`, `displayBuilder` for
   `PrefabDisplayBuilder`).
7. **Closed sets are enums**, never strings (`Place`, `FieldWidget`).
8. **Runtime classes start with `Prefab`** (`PrefabTheme`, `PrefabPage`);
   annotations do not.
9. **Generated names** use the entity name: singular for one entity
   (`productDetailProvider`, `ProductApiClient`), plural for a collection
   (`productsProvider`, `ProductsNotifier`), and `{Entity}<Kind>Screen` for
   screens.
10. **One way to say a thing.** When a name is replaced, the old one is
    removed, not kept as an alias.

## Consequences

PF-73 applies this vocabulary as a hard rename (no deprecated aliases):

| Before | After |
|---|---|
| `@View(title:, path:, paged:)` | `@Entity(title:, path:, paged:)` |
| `ActionPlace.detail/list/item` | `Place.detail/list/item` |
| `@Field(views: {'list', 'detail'})` | `@Field(on: {Place.item, Place.detail, Place.form})`: `on` also covers the form; without `on` a field appears in every place |
| `@Field(hidden: true)` | `@Field(on: {})` |
| `FormOptions(custom: ...)` | `FormOptions(builder: ...)` |
| `@Field(display: ...)` | `@Field(displayBuilder: ...)` |
| `@FormField` (deprecated) | removed; use `@Field` |
| `Parent.type` | `Parent.entity` |

`AGENTS.md` points every agent to this record. Reviews treat a new name that
does not follow it like any other bug.
