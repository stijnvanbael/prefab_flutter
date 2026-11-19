---
id: PF-36
title: Shared test harness and snapshot tests of generated output
status: Done
assignee: []
created_date: '2026-11-19 10:00'
labels: []
milestone: m-0
dependencies: []
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Two problems slow down generator work today:

1. Each of the 14 test files in `prefab_flutter_generator/test/` has its own inline copy of the `prefab_flutter` annotation sources (`_prefabSources`). The copies drift from the real annotations, and every feature that changes an annotation edits all of them, causing merge conflicts.
2. Tests assert on fragments with `contains(...)`, so they say little about the full generated output. That makes them a weak safety net for the generator refactor (PF-38, PF-39), which must not change the output by accident.

Add a shared test harness that loads the real annotation sources, and snapshot tests that compare the complete generated `.prefab.dart` output of a set of fixture entities with checked-in expected files.

This is the safety net for M0, so it comes first.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 A helper in `prefab_flutter_generator/test/support/` provides the `prefab_flutter` sources to `testBuilder` by reading the real files under `../prefab_flutter/lib/` at test time; no test file keeps an inline copy of the annotations
- [x] #2 All existing test files use the shared helper and still pass, with assertions unchanged except where they relied on a stub that differed from the real annotation
- [x] #3 Snapshot fixtures live in `test/snapshots/fixtures/` (one entity scenario per file) and cover at least: a minimal entity, all field widgets, parameterised validators, `@Create`/`@Update`/`@Delete` combinations including read-only, a three-level `@Parent` chain, a non-paged list with search and sort, and `@Field.views`
- [x] #4 `test/snapshots_test.dart` generates each fixture and compares the full output with `test/snapshots/expected/<fixture>.prefab.dart`; a mismatch prints a readable diff
- [x] #5 Running `UPDATE_SNAPSHOTS=1 dart test test/snapshots_test.dart` rewrites the expected files
- [x] #6 `docs/developer_guide.md` explains the harness, how to add a fixture, and how to update snapshots
- [x] #7 AGENTS.md "Avoiding merge conflicts" gains a rule: when expected snapshot files conflict, take `main`'s version, then regenerate with `UPDATE_SNAPSHOTS=1` and review the diff; new features add a new fixture instead of changing an existing one where possible
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
- `test/support/prefab_sources.dart` exposes `prefabSources`, read from `../prefab_flutter/lib/` at test time. All 14 test files use it; the inline stubs are gone. Assertions are unchanged, and all existing tests pass against the real annotations.
- 10 fixtures in `test/snapshots/fixtures/` (minimal, all widgets, validators, full CRUD, create-only, update+delete, read-only, three-level parent chain, non-paged list with search and sort, `@Field.views`); `test/snapshots_test.dart` compares full output and prints a line diff.
- `path` is a new dev dependency of the generator (used by the helper). Fixtures and expected files are excluded from `dart analyze`.
- No changelog fragment: test-only change, no published behaviour changed.
<!-- SECTION:NOTES:END -->
