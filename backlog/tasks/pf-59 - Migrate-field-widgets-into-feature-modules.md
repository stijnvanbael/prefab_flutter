---
id: PF-59
title: Migrate field widgets into feature modules
status: To Do
assignee: []
created_date: '2026-11-20 10:00'
labels: []
milestone: m-0
dependencies:
  - PF-39
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Move the per-widget switches of `form_screen_generator.dart` (state declaration, prefill, form field, value expression) into one `FieldEmitter` per `FieldWidget` under `lib/src/features/field_widgets/`, registered in the `FieldEmitters` registry. Add `stateDeclaration` and `initialValue` to `FieldEmitter` as sketched in decision-1.

Follow "Adding a feature" in `docs/developer_guide.md` and the pattern of `lib/src/features/list_query/` (PF-39). The snapshot tests must pass without changes to the expected files.

Expected to touch:
- `prefab_flutter_generator/lib/src/core/field_registries.dart`
- `prefab_flutter_generator/lib/src/generators/form_screen_generator.dart`
- `prefab_flutter_generator/lib/src/features/field_widgets/`
- `prefab_flutter_generator/test/field_widgets_test.dart`
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 One `FieldEmitter` class per `FieldWidget` live in `lib/src/features/` and the per-artifact generators no longer contain their code
- [ ] #2 The snapshot tests pass without changes to the expected files
- [ ] #3 The feature has its own test file; the developer guide and the registry (`features.dart`, alphabetical) are updated; changelog fragment added
- [ ] #4 Annotation reading only this feature uses moves out of `entity_manifest.dart`, or the implementation notes say why it stays
<!-- AC:END -->
