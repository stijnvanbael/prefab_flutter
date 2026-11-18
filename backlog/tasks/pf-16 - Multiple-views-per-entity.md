---
id: PF-16
title: Multiple views per entity
status: To Do
assignee: []
created_date: '2026-05-03 10:30'
updated_date: '2026-11-18 10:00'
labels: []
dependencies:
  - PF-30
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Every entity currently has a single implicit presentation: the list tile shows only the first visible field and the detail screen shows all of them. Developers need to control which fields appear in each context. Add a views parameter to @Field (PF-30) that takes the view names a field appears in.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 @Field gains a views parameter (Set<String>); omitting it means the field appears in all views
- [ ] #2 EntityManifest exposes fieldsForView(String viewName)
- [ ] #3 ListScreenGenerator uses the 'list' view to fill ListTile title, subtitle and trailing slots (first, second and third field)
- [ ] #4 DetailScreenGenerator uses the 'detail' view and falls back to all visible fields
- [ ] #5 Existing behaviour is unchanged when no field declares views
- [ ] #6 The user guide documents the view names and their slot mapping
<!-- AC:END -->
