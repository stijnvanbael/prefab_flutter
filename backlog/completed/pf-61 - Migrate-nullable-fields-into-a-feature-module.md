---
id: PF-61
title: Migrate nullable fields into a feature module
status: Done
assignee: []
created_date: '2026-11-20 10:00'
labels: []
milestone: m-0
dependencies:
  - PF-39
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Move the nullable-field handling (form fields, detail display via `FieldDisplay`, list tiles) into `lib/src/features/nullable_fields/`, using the `fieldValue` and form field extension points. Add the `fieldValue` point to the detail screen if missing.

Follow "Adding a feature" in `docs/developer_guide.md` and the pattern of `lib/src/features/list_query/` (PF-39). The snapshot tests must pass without changes to the expected files.

Expected to touch:
- `prefab_flutter_generator/lib/src/generators/detail_screen_generator.dart`
- `prefab_flutter_generator/lib/src/generators/form_screen_generator.dart`
- `prefab_flutter_generator/lib/src/generators/list_screen_generator.dart`
- `prefab_flutter_generator/lib/src/features/nullable_fields/`
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 A nullable-fields module live in `lib/src/features/` and the per-artifact generators no longer contain their code
- [x] #2 The snapshot tests pass without changes to the expected files
- [x] #3 The feature has its own test file; the developer guide and the registry (`features.dart`, alphabetical) are updated; changelog fragment added
- [x] #4 Annotation reading only this feature uses moves out of `entity_manifest.dart`, or the implementation notes say why it stays
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
- `lib/src/features/nullable_fields/` contributes a `FieldValue` (order 10) to the new `fieldValue` point of the detail screen and list screen; `DefaultFieldDisplay` no longer knows about nullability.
- The nullable branches of the create/edit form (nullable bool dropdown, empty dropdown option, `null` for empty text, prefill) are interleaved with the per-widget switches, so they move with the `FieldEmitter` split in PF-59, not here. Hence the form screen generator is unchanged.
- No annotation reading moved: `FieldManifest.isNullable` comes from the Dart type, is shared with the forms and stays in `manifest/` (see "Adding a feature").
<!-- SECTION:NOTES:END -->
