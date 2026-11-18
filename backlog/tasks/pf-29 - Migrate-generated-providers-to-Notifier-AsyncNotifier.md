---
id: PF-29
title: Migrate generated providers to Notifier / AsyncNotifier
status: To Do
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
- [ ] #1 List notifiers extend (Family)AsyncNotifier and expose create/update/delete methods
- [ ] #2 Detail providers remain FutureProvider.autoDispose.family
- [ ] #3 Generated code depends only on the non-legacy Riverpod API
- [ ] #4 The supported flutter_riverpod version range is documented in the README
- [ ] #5 Generator tests are updated
<!-- AC:END -->
