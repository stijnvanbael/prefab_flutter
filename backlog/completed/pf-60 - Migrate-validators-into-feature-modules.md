---
id: PF-60
title: Migrate validators into feature modules
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
Move the validator checks out of `form_screen_generator.dart` into one `ValidatorEmitter` per `Validator` under `lib/src/features/validators/`, registered in `ValidatorEmitters`.

Follow "Adding a feature" in `docs/developer_guide.md` and the pattern of `lib/src/features/list_query/` (PF-39). The snapshot tests must pass without changes to the expected files.

Expected to touch:
- `prefab_flutter_generator/lib/src/core/field_registries.dart`
- `prefab_flutter_generator/lib/src/generators/form_screen_generator.dart`
- `prefab_flutter_generator/lib/src/features/validators/`
- `prefab_flutter_generator/test/validators_test.dart`
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 One `ValidatorEmitter` class per `Validator` live in `lib/src/features/` and the per-artifact generators no longer contain their code
- [x] #2 The snapshot tests pass without changes to the expected files
- [x] #3 The feature has its own test file; the developer guide and the registry (`features.dart`, alphabetical) are updated; changelog fragment added
- [x] #4 Annotation reading only this feature uses moves out of `entity_manifest.dart`, or the implementation notes say why it stays
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
- `lib/src/features/validators/validator_emitters.dart` holds one emitter per `Validator` and the `validatorEmitters` registry; `ValidatorsFeature` is registered in `features.dart` but contributes no extension-point code (the form template looks the emitters up per field).
- The `ValidatorEmitters` class stays in `core/field_registries.dart`, next to the other registries.
- AC #4: `_readValidator` and `FieldManifest.validators` stay in `lib/src/manifest/`: the validators are read together with the other `@Field.form` values and the form template (`required`, widget checks) uses them too.
- The text-only-validator check and the `required`/numeric-parse prologue stay in the form template; they depend on the widget kind and move with the field widgets (PF-59).
<!-- SECTION:NOTES:END -->
