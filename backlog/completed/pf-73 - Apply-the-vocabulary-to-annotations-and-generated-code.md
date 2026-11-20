---
id: PF-73
title: Apply the vocabulary to annotations and generated code
status: Done
assignee: []
created_date: '2026-11-20 15:00'
labels: []
dependencies: []
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Decision-2 (`backlog/decisions/decision-2 - Vocabulary.md`) fixes the terms and naming rules of Prefab Flutter. Apply it as a hard rename, without deprecated aliases (nothing is published yet):

- `@View` becomes `@Entity` (it collided with Prefab's `@ViewOf`, a read model).
- One `Place` enum (`list`, `item`, `detail`, `form`) replaces `ActionPlace` and the `Field.views` strings; `@Field(on: ...)` replaces `views` and `hidden`.
- `FormOptions.custom` becomes `FormOptions.builder`, `Field.display` becomes `Field.displayBuilder`.
- The deprecated `@FormField` is removed; `Parent.type` becomes `Parent.entity`.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 The annotation package exposes only the names in decision-2; the old names are gone
- [x] #2 The generator reads the new names; `Place.list` on a field and `Place.form` on an action fail the build with a clear message
- [x] #3 `@Field(on: ...)` controls the list item, detail screen and form; a field without `on` appears everywhere, as before
- [x] #4 Snapshots, API summaries, tests and the example app use the new names and pass
- [x] #5 README, package READMEs, user guide and developer guide use the new names; a search for the old names finds them only in changelogs and completed tasks
- [x] #6 Changelog fragments describe the breaking renames with a before/after list
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
- `on:` mapping of the old `views`: since `views` did not affect forms, the migrated fixtures and tests add `Place.form` (`{'detail'}` → `{Place.detail, Place.form}`), so the generated output and snapshots are unchanged.
- Behaviour change: the detail screen shows exactly the fields on `Place.detail`; the old fallback to every visible field when no field was in the detail view is gone (decision-2, rule 10, "one way to say a thing").
- The `views` feature module is now `features/places/` (`PlacesFeature`); `field_views` keeps its fixture name to avoid churning the snapshot files.
- decision-1 keeps its original wording (`@Field.views`), as an accepted record of its time.
- Tests: `test/field_on_test.dart`.
<!-- SECTION:NOTES:END -->
