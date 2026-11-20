---
id: PF-59
title: Migrate field widgets into feature modules
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
- [x] #1 One `FieldEmitter` class per `FieldWidget` live in `lib/src/features/` and the per-artifact generators no longer contain their code
- [x] #2 The snapshot tests pass without changes to the expected files
- [x] #3 The feature has its own test file; the developer guide and the registry (`features.dart`, alphabetical) are updated; changelog fragment added
- [x] #4 Annotation reading only this feature uses moves out of `entity_manifest.dart`, or the implementation notes say why it stays
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
- One `FormFieldEmitter` (extends `FieldEmitter`) per `FieldWidget` in `lib/src/features/field_widgets/`, registered in `formFieldEmitters`; `FieldEmitter` gained `stateDeclaration` and `initialValue`. `FormFieldEmitter` adds `usesController`, `isTextInput` and `parsesNumbers`, which the form template and validator callback need. The form screen generator only asks the registry. The emitters return `Code` with their imports (number input names `Libs.flutterServices`), so the generator no longer mutates its import set from the widget writers. The generated output is unchanged.
- The validator callback (`form_validation.dart`) moved with the widgets because every text widget builds it; the check of each `Validator` comes from the `validators` module (PF-60).
- `FieldWidgetsFeature` contributes nothing to artifacts; it exists so the feature is registered and discoverable in `features.dart`.
- AC#4: `FieldManifest.fieldWidget`, `isEnum` and `isNullable` stay in `lib/src/manifest/`, because they are raw annotation and type data read in one place with the defaults of every field, and the detail and list screens read them too (developer guide, "Adding a feature"). No widget-specific annotation reading was left in `entity_manifest.dart`.
<!-- SECTION:NOTES:END -->
