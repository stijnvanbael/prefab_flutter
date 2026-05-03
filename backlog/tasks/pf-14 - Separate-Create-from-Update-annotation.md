---
id: PF-14
title: Separate @Create from @Update annotation
status: To Do
assignee: []
created_date: '2026-05-03 10:30'
updated_date: '2026-05-03 10:30'
labels: []
dependencies: []
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The @Update annotation currently gates both the create form screen and the edit form screen. Developers need to express entities that are create-only (e.g. audit log entries), edit-only, or neither (read-only). Split into independent @Create and @Update annotations so each capability can be toggled separately. Update all generators and EntityManifest accordingly.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 A new @Create annotation is added to the prefab_flutter package
- [ ] #2 EntityManifest exposes separate hasCreate and hasUpdate flags
- [ ] #3 FormScreenGenerator emits CreateScreen only when @Create is present, and EditScreen only when @Update is present
- [ ] #4 RoutesGenerator emits the create route only when @Create is present, and the edit route only when @Update is present
- [ ] #5 DetailScreenGenerator shows the Edit action button only when @Update is present
- [ ] #6 ProviderGenerator generates a create() method only when @Create is present, and update() only when @Update is present
- [ ] #7 Existing tests and the example app are updated to use the new annotations
<!-- AC:END -->
