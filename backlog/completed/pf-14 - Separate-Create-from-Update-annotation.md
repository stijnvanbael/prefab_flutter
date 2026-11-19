---
id: PF-14
title: Separate @Create from @Update annotation
status: Done
assignee: []
created_date: '2026-05-03 10:30'
updated_date: '2026-11-18 10:00'
labels: []
dependencies:
  - PF-26
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The @Update annotation currently gates both the create and the edit screen, while the provider always generates create(). Developers need entities that are create-only (e.g. audit log entries), edit-only, or read-only. Split into independent @Create and @Update annotations so each capability can be toggled separately.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 A new @Create annotation is added to the prefab_flutter package
- [x] #2 EntityManifest exposes separate hasCreate and hasUpdate flags
- [x] #3 FormScreenGenerator emits CreateScreen only when @Create is present, and EditScreen only when @Update is present
- [x] #4 RoutesGenerator emits the create route only with @Create and the edit route only with @Update
- [x] #5 The list screen's create button (PF-26) appears only with @Create
- [x] #6 DetailScreenGenerator shows the Edit action only with @Update
- [x] #7 ProviderGenerator and ApiClientGenerator emit create() only with @Create and update() only with @Update
- [x] #8 Existing tests, the example app, the README and the user guide are updated
<!-- AC:END -->

## Implementation Notes

Added `@Create`; `EntityManifest.hasCreate` and `hasUpdate` are independent. Form screens, routes, list FAB, provider and API client are gated per annotation. Existing tests now carry `@Create()` next to `@Update()`; `create_update_split_test.dart` covers create-only, update-only and read-only. Docs, READMEs and changelog updated.
