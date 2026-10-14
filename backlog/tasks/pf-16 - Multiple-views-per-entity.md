---
id: PF-16
title: Multiple views per entity
status: To Do
assignee: []
created_date: '2026-05-03 10:30'
updated_date: '2026-05-03 10:30'
labels: []
dependencies: []
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Every entity currently has a single implicit presentation used for both the list tile and the detail screen. Developers need to control which fields appear in each context and how they are rendered. Introduce a @ViewField annotation (or extend @FormField) with a views parameter that accepts a set of view names (e.g. {'list', 'detail', 'card'}), then add a @ViewType annotation on the class to declare named view layouts. ListScreenGenerator should use the 'list' view to render richer list tiles (title, subtitle, trailing), while DetailScreenGenerator uses the 'detail' view. A 'card' view could drive a card-style widget in future screens.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 A views parameter is added to @FormField accepting a list of view-name strings; omitting it means the field appears in all views
- [ ] #2 EntityManifest exposes a fieldsForView(String viewName) helper returning only the fields that belong to that view
- [ ] #3 ListScreenGenerator uses the 'list' view fields to populate ListTile title, subtitle, and trailing slots
- [ ] #4 DetailScreenGenerator uses the 'detail' view fields (falls back to all visible fields when no 'detail' view is declared)
- [ ] #5 A 'card' view name is reserved and documented for future card-layout generators
- [ ] #6 Existing behaviour is unchanged when no views parameter is specified on any field
<!-- AC:END -->
