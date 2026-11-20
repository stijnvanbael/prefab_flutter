---
id: PF-66
title: Migrate the generator to the new analyzer element model
status: To Do
assignee: []
created_date: '2026-11-20 12:00'
labels: []
milestone: m-0
dependencies:
  - PF-43
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
PF-43 moved the generator to `source_gen` 2.x and `analyzer` 7, which deprecate the old element model (`Element`, `ClassElement`, `.library`, `getNamedConstructor`, ...). The `deprecated_member_use` lint is ignored in `prefab_flutter_generator/analysis_options.yaml` until the generator uses the new model (`Element2` / analyzer 8+ with `source_gen` 3+). Migrate, then remove the ignore.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 The generator uses the new element model and `dart analyze --fatal-infos` passes without the `deprecated_member_use` ignore
- [ ] #2 Snapshots are unchanged
<!-- AC:END -->
