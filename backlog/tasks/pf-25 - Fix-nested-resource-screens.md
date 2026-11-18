---
id: PF-25
title: Fix nested resource screens
status: To Do
assignee: []
created_date: '2026-11-18 10:00'
updated_date: '2026-11-18 10:00'
labels: []
dependencies: []
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Nested (@Parent) entities only work for list and detail viewing. Found during the 2026-11 review:
- RoutesGenerator passes the parent id to {Entity}CreateScreen and {Entity}EditScreen, but FormScreenGenerator never declares that parameter;
- the edit screen calls {entity}DetailProvider(widget.id) while nested detail providers expect an (id, parentId) record;
- the detail screen's Edit action pushes /{path}/{id}/edit instead of the nested path;
- the detail screen's Delete action reads {entity}sProvider.notifier without the parent id family argument;
- the list screen's item tap fallback path guesses `{parent}s` when the parent manifest is missing.
Each of these is a compile or navigation error.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 FormScreenGenerator adds the parent id parameter to create and edit screens of nested entities and passes it to providers
- [ ] #2 The edit screen of a nested entity watches the detail provider with the (id, parentId) record
- [ ] #3 The detail screen's Edit action navigates to the nested edit path
- [ ] #4 The detail screen's Delete action uses the family list provider with the parent id
- [ ] #5 Navigation paths are built in one shared helper used by all generators, instead of being duplicated per generator
- [ ] #6 Generator tests cover create, edit, delete and navigation for a nested entity
- [ ] #7 The example app's nested entity compiles and works (PF-9)
<!-- AC:END -->
