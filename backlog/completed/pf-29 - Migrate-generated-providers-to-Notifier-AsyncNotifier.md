---
id: PF-29
title: Migrate generated providers to Notifier / AsyncNotifier
status: Done
assignee: []
created_date: '2026-11-18 10:00'
updated_date: '2026-11-18 10:00'
labels: []
dependencies: []
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Generated providers use StateNotifier and StateNotifierProvider, which recent Riverpod versions treat as legacy. Migrate to AsyncNotifier (with a family for nested entities) before search, sort, paging and multi-level nesting add more state.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 List notifiers extend (Family)AsyncNotifier and expose create/update/delete methods
- [x] #2 Detail providers remain FutureProvider.autoDispose.family
- [x] #3 Generated code depends only on the non-legacy Riverpod API
- [x] #4 The supported flutter_riverpod version range is documented in the README
- [x] #5 Generator tests are updated
<!-- AC:END -->

## Implementation Notes

Uses the Riverpod 2.x `AutoDisposeAsyncNotifier` / `AutoDisposeFamilyAsyncNotifier` API. Riverpod 3 (which removes the `AutoDispose*` base classes) is not supported; range stays `>=2.5.0 <3.0.0`.
