---
id: PF-43
title: Pin the dart_style language version
status: To Do
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
- [ ] #1 `DartFormatter` gets a pinned `languageVersion`
- [ ] #2 Snapshots are unchanged or regenerated in a separate commit
<!-- AC:END -->
