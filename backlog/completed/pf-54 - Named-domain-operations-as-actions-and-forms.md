---
id: PF-54
title: Named domain operations as actions and forms
status: Done
assignee: []
created_date: '2026-11-20 10:00'
labels: []
milestone: m-2
dependencies:
  - PF-44
  - PF-53
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Prefab exposes domain operations beyond CRUD as named update endpoints (`@Update(path = ...)` in Java), e.g. `POST /invoices/{id}/send`, `/chargers/{id}/start`). Both reference apps need them (start/stop charging, submit an answer). Principle 1: declare the operation on the model and get the button.

Mirror Prefab: a named operation is declared on the model (e.g. `@Update(path: 'send', label: 'Send')` repeated, or a dedicated `@Operation` annotation, to decide) with optional parameters. An operation without parameters becomes an action (rendered like PF-44's actions, with an optional confirmation); one with parameters opens a generated form with those parameters. The API client gets one method per operation, and the detail and list providers refresh afterwards.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 An entity can declare named operations; each gets an API client method calling `{path}/{id}/{operation}` with the method and body the backend adapter defines (Prefab preset by default)
- [x] #2 Operations without parameters appear as actions on the detail screen (and optionally list items), with an optional confirmation dialog
- [x] #3 Operations with parameters open a generated form for the parameters, using the existing field widgets and validators
- [x] #4 The entity is refreshed after the operation; errors use the Problem Details handling of PF-51
- [x] #5 Feature module, tests, snapshot fixture and user guide section; changelog fragments added
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
- Design (principle 1, "mirror Prefab", naming rule 1): no new annotation. `@Update(path: 'send', ...)` is repeatable and declares a named operation; `@Update()` without a path still means the edit screen (`hasUpdate` ignores annotations with a path). New `@Update` parameters: `path`, `label`, `icon`, `on` (`Place.detail`/`Place.item`), `confirm`, `parameters`, `order`.
- Parameters (AC#3, principle 2): a plain class with `@Field` fields, an unnamed constructor and `toJson()`. `EntityManifest` now reads its fields through the same `_readField` as entity fields, so every field widget, validator and custom builder works. The form is `{Entity}{Operation}Screen`, a route below the detail route (new `ArtifactKind.operationScreen`; the artifact id is `Entity.path` because an entity can have several).
- Runtime (AC#1): `PrefabBackend.operationMethod` (`POST`) and `operationBody(json)` (identity) in both presets; `runPrefabOperation` in `prefab_flutter_widgets` confirms, runs and shows the Problem Details message in a snack bar (AC#4).
- The buttons reuse `action_rendering.dart` of PF-44 and sort together with the operations only (not with `@EntityAction`s of the same screen, which are a separate group, order 50). Orders: 40 on the shared points of the API client, notifier, app bar actions and item actions; 6 on `detailChildRoutes`.
- Detail screens that are promoted do not show operations; the build warns like it does for actions. Whether `promote` copies the buttons into a promoted file was not verified.
- Example app: `Product` has `discontinue` and `discount` (item menu), with `test/named_operations_test.dart`. Not covered: an operation inside a nested entity in the example (the snapshot fixture `named_operations` covers `@Parent`).
<!-- SECTION:NOTES:END -->
