---
id: PF-16
title: Multiple views per entity
status: Done
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
- [x] #1 @Field gains a views parameter (Set<String>); omitting it means the field appears in all views
- [x] #2 EntityManifest exposes fieldsForView(String viewName)
- [x] #3 ListScreenGenerator uses the 'list' view to fill ListTile title, subtitle and trailing slots (first, second and third field)
- [x] #4 DetailScreenGenerator uses the 'detail' view and falls back to all visible fields
- [x] #5 Existing behaviour is unchanged when no field declares views
- [x] #6 The user guide documents the view names and their slot mapping
<!-- AC:END -->

## Implementation Notes

`views` is a nullable `Set<String>` (null = all views). The list screen only uses the three slots when at least one field declares `views`; otherwise behaviour is unchanged. Forms ignore views.
