---
id: PF-64
title: Migrate views into a feature module
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
Move `@Field.views` handling (list tile slots, detail fields per view) into `lib/src/features/views/` using the `itemTile` point of the list screen and the `fieldValue` point of the detail screen.

Follow "Adding a feature" in `docs/developer_guide.md` and the pattern of `lib/src/features/list_query/` (PF-39). The snapshot tests must pass without changes to the expected files.

Expected to touch:
- `prefab_flutter_generator/lib/src/generators/list_screen_generator.dart`
- `prefab_flutter_generator/lib/src/generators/detail_screen_generator.dart`
- `prefab_flutter_generator/lib/src/features/views/`
- `prefab_flutter_generator/lib/src/manifest/entity_manifest.dart`
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 A views module live in `lib/src/features/` and the per-artifact generators no longer contain their code
- [ ] #2 The snapshot tests pass without changes to the expected files
- [ ] #3 The feature has its own test file; the developer guide and the registry (`features.dart`, alphabetical) are updated; changelog fragment added
- [ ] #4 Annotation reading only this feature uses moves out of `entity_manifest.dart`, or the implementation notes say why it stays
<!-- AC:END -->
