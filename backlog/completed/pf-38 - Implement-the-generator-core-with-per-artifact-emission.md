---
id: PF-38
title: Implement the generator core with per-artifact emission
status: Done
assignee: []
created_date: '2026-11-19 10:00'
labels: []
milestone: m-0
dependencies:
  - PF-36
  - PF-37
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Implement the core of the architecture chosen in PF-37 (`backlog/decisions/decision-1 - Generator-architecture.md`: structured templates per artifact, extension points, an import collector; no `code_builder`): the artifact model, the extension points feature modules contribute to, and import collection. `PrefabGenerator` assembles the `.prefab.dart` file from artifacts instead of merging the text output of six generators with regular expressions.

Follow the "Migration" section of the decision record, step 1: move each generator's per-entity method into an artifact class with its lines unchanged, turn the `_writeImports` conditions into the imports of the fragments that need them, and emit artifacts kind-major so the output stays byte-identical. The prototype in `prefab_flutter_generator/prototype/pf37/` is the starting point for `lib/src/core/`. Moving features into modules is PF-39; formatting with `dart_style` is PF-41.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 The artifact model and extension points from the PF-37 decision record exist in `prefab_flutter_generator/lib/src/`
- [x] #2 Imports are collected through the core; the regular-expression import merging in `prefab_generator.dart` is removed
- [x] #3 Each artifact is emitted separately, and the core has a (not yet user-facing) way to skip an artifact, covered by a unit test, ready for promotion in M1
- [x] #4 The snapshot tests pass without changes to the expected files, or each change is explained in the pull request and is not user-visible
- [x] #5 All existing generator tests and the example app CI job pass
- [x] #6 `docs/developer_guide.md` "Generator internals" describes the new structure
- [x] #7 The single-valued extension points and the registries for field widgets, validators and field display (`FieldEmitter`, `ValidatorEmitter`, `FieldDisplay` in the decision record) exist, even if the first implementation of each just wraps today's code
- [x] #8 The prototype directory `prefab_flutter_generator/prototype/` is deleted
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
- The core is in `prefab_flutter_generator/lib/src/core/` (`Code`/`Libs`/`Imports`, `Artifact`, `ExtensionPoint`, `Feature`, `EntityContext`/`ArtifactSet`, `LibraryEmitter`, `ArtifactGenerator`, `field_registries.dart`). Each generator file now holds the artifact classes of its kind with the template methods moved over unchanged; the per-kind `*Generator` classes are thin `ArtifactGenerator`s kept for the per-kind test builders.
- The snapshots are unchanged. To keep them byte-identical, the three provider artifacts of an entity (detail provider, list provider and notifier, API client provider) share one factory, and so do the create and edit screen of an entity, so they stay together per entity instead of becoming strictly kind-major. `ArtifactKind.apiClientProvider` was added to the decision record's list.
- Imports: the detail screen adds `go_router` / `prefab_flutter_widgets` where the Edit, Delete and breadcrumb fragments are written, and the form screens add `flutter/services` in the number field. The other artifacts name their libraries in `emit()`. The sibling-file regular expression is gone, so tests that asserted imports of `product.provider.dart` etc. were replaced by tests that the per-kind output does not import sibling files (form_screen and routes tests).
- Skipping: `LibraryEmitter(promoted: [...])` drops an artifact by any of its declared names and imports and re-exports the replacement; covered by `test/generator_core_test.dart`. Not reachable from annotations yet (PF-42).
- Registries: `FieldEmitters`, `ValidatorEmitters` and `FieldDisplays` exist and are used by the form, detail and list templates. The first implementations wrap the old writers. `FieldEmitter` has `formField` and `valueExpression`; `stateDeclaration` and `initialValue` from the decision record are added when the inline state and prefill switches of the form template move out (PF-39 follow-ups for field widgets).
- The templates do not expose extension points yet and no feature module exists; that is PF-39.
<!-- SECTION:NOTES:END -->
