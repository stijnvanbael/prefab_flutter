---
id: PF-14
title: Separate @Create from @Update annotation
status: To Do
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
- [ ] #1 A new @Create annotation is added to the prefab_flutter package
- [ ] #2 EntityManifest exposes separate hasCreate and hasUpdate flags
- [ ] #3 FormScreenGenerator emits CreateScreen only when @Create is present, and EditScreen only when @Update is present
- [ ] #4 RoutesGenerator emits the create route only with @Create and the edit route only with @Update
- [ ] #5 The list screen's create button (PF-26) appears only with @Create
- [ ] #6 DetailScreenGenerator shows the Edit action only with @Update
- [ ] #7 ProviderGenerator and ApiClientGenerator emit create() only with @Create and update() only with @Update
- [ ] #8 Existing tests, the example app, the README and the user guide are updated
<!-- AC:END -->
