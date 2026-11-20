---
id: decision-3
title: Scaffold annotated models from a Prefab OpenAPI document
date: '2026-11-20'
status: proposed
---

## Context

PF-58 asks whether annotated Dart models can be derived from the OpenAPI
document of a Prefab service. Findings come from reading Prefab
(`stijnvanbael/prefab`, commit `0b14289`): its `openapi` module only provides
a default SpringDoc `OpenAPI` bean (title, description, version); the paths and
schemas are produced by SpringDoc from the generated controllers and request
records. **No Prefab service was run and no real document was inspected**, so
the table below is derived from Prefab's documented REST conventions
(`backlog/docs/feature-guides.md` 7.1, 7.17, 7.18) and must be verified against
a real document (see PF-78).

## What can be derived

| Annotation / parameter | Derivable | From |
|---|---|---|
| `@Entity(path)` | yes | collection path (`/products`) |
| `@Entity(title)` | yes | schema name |
| `@Entity(paged)` | likely | `page`/`size` parameters on the list operation |
| `@Create`, `@Update`, `@Delete` | yes | `POST`, `PUT`, `DELETE` operations |
| `@Update(path:)` (PF-54) | likely | extra `PUT /{id}/<name>` operations |
| `@Id` | partly | `{id}` path parameter (name and type) |
| `@Version` | partly | a `version` property |
| `@Field` and Dart type | yes | schema properties, `type`, `format`, `nullable`/`required` |
| `readOnly` | yes | `readOnly: true` |
| Create vs. update shapes (PF-53) | yes | separate request body schemas |
| `FormOptions(on:)` | yes | fields present in only one request schema |
| `@Parent` | yes | nested paths (`/posts/{postId}/comments`) |
| `@Filter` (PF-55) | likely | per-field list query parameters |
| `sortable` | partly | enum on the `sort` parameter, if documented |
| validators | partly | `minimum`, `maxLength`, `pattern`, `format: email` |
| `FieldWidget` | partly | enum, date, boolean, `@Text`-style long strings |
| `searchable` | no | only a generic `q` parameter |
| `label`, `on:` places, item title field | no | UI choices; defaults apply |
| `displayBuilder`, `builder` | no | hand-written code |

## Missing in the document (candidates for the Prefab side)

- Which operations belong to one entity (grouping by tag or an
  `x-prefab-aggregate` extension).
- Searchable fields, default sort and the title field.
- Human-readable labels (`title` on properties).
- Internal (`Exposure.INTERNAL`) aggregates and `@ViewOf` views appear as
  plain read endpoints; views have no link to their aggregate.

## Options

**A. One-off scaffolding command** that writes `.dart` models once. The
developer owns the file afterwards.

**B. Build step** that regenerates models on every build.

## Decision (proposed)

**A, scaffold once**, plus an optional `--check` mode that reports drift
between the Dart models and the document without writing. Vision principles
3 (promotion: the developer takes over) and 4 (plain readable code) favour a
file that the developer edits; a build step would overwrite labels, widgets and
validators that cannot be derived. Everything not derivable gets the defaults
of `@Field()`.

## Consequences

- Follow-up: PF-78 (verify against a real document), PF-75 (scaffolding
  command), PF-76 (drift check), PF-77 (Prefab-side metadata).
- Acceptance criterion #2 of PF-58 (prototype against a real service) is not
  met; PF-78 covers it.
