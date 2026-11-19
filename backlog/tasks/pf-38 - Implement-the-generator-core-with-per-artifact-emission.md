---
id: PF-38
title: Implement the generator core with per-artifact emission
status: To Do
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
- [ ] #1 The artifact model and extension points from the PF-37 decision record exist in `prefab_flutter_generator/lib/src/`
- [ ] #2 Imports are collected through the core; the regular-expression import merging in `prefab_generator.dart` is removed
- [ ] #3 Each artifact is emitted separately, and the core has a (not yet user-facing) way to skip an artifact, covered by a unit test, ready for promotion in M1
- [ ] #4 The snapshot tests pass without changes to the expected files, or each change is explained in the pull request and is not user-visible
- [ ] #5 All existing generator tests and the example app CI job pass
- [ ] #6 `docs/developer_guide.md` "Generator internals" describes the new structure
- [ ] #7 The single-valued extension points and the registries for field widgets, validators and field display (`FieldEmitter`, `ValidatorEmitter`, `FieldDisplay` in the decision record) exist, even if the first implementation of each just wraps today's code
- [ ] #8 The prototype directory `prefab_flutter_generator/prototype/` is deleted
<!-- AC:END -->
