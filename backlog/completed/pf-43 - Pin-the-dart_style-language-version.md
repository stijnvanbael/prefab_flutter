---
id: PF-43
title: Pin the dart_style language version
status: Done
assignee: []
created_date: '2026-11-20 10:00'
labels: []
milestone: m-0
dependencies:
  - PF-41
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
PF-41 formats the output with `dart_style` 2.3.6, which has no `languageVersion` parameter, so the language version is not pinned. `dart_style` >= 2.3.7 needs `analyzer` >= 6.5, which the current SDKs refuse (missing `_macros`), and `source_gen` 1.x caps `analyzer` below 7. Upgrade `source_gen` (and `analyzer`) so `dart_style` can be upgraded, then pass a pinned `languageVersion` to `DartFormatter` in `lib/src/core/format.dart`.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 `DartFormatter` gets a pinned `languageVersion`
- [x] #2 Snapshots are unchanged or regenerated in a separate commit
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Upgraded `source_gen` to ^4.2.0, `analyzer` to 8.x, `build` to ^3, `build_runner` to ^2.7, `build_test` to ^3.3 and `dart_style` to `>=3.1.1 <3.2.0`; `formatGenerated` passes a pinned `languageVersion` (3.0, classic style). Snapshots are unchanged. analyzer 7 was not enough: it cannot parse Flutter 3.47 sources, so the example's `build_runner` failed. The generator moved to the analyzer 8 element model (`TypeChecker.typeNamed` replaces `fromRuntime`). `build_test` 3 reports builder failures as log records, so `promoted_test.dart` checks the logged message. SDK minimum raised to 3.6.
<!-- SECTION:NOTES:END -->
