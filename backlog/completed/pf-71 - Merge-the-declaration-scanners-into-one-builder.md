---
id: PF-71
title: Merge the declaration scanners into one builder
status: Done
assignee: []
created_date: '2026-11-20 12:00'
labels: []
dependencies: []
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
`prefab_promoted` (PF-42), `prefab_actions` (PF-44) and `prefab_screens` (PF-45) are three builders that each scan the unresolved syntax tree of every file and write their own JSON summary (`.prefab_promoted.json`, `.prefab_actions.json`, `.prefab_screens.json`), which `prefab_builder` requires. Named operations (PF-54) and later features are likely to add more. Each new declaration type then edits `build.yaml` and the builder wiring, which are shared, conflict-prone files (principle 8), and every file is parsed once per scanner.

Merge them into one declarations builder with one summary file per source file, where a feature module registers the declarations it scans for, following the feature module contract in docs/developer_guide.md.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 One builder scans each file once and writes one summary file for all declaration types
- [x] #2 A feature module adds a declaration type without editing `build.yaml` or the builder
- [x] #3 Existing promoted, action and screen behaviour, errors and snapshots are unchanged
- [x] #4 docs/developer_guide.md ("Adding a feature") describes how to add a declaration type
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
`DeclarationScanner` and `DeclarationsBuilder` live in `lib/src/core/declarations.dart`; `Feature.declarationScanners` registers them. `@Promoted` got a small `PromotedFeature` (scanner only) so every declaration type is registered the same way. The example app needs no change (internal builder wiring; its `build.yaml` use is automatic). Nothing left undone.
<!-- SECTION:NOTES:END -->
