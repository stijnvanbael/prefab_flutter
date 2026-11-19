---
id: PF-25
title: Fix nested resource screens
status: Done
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
- [x] #1 FormScreenGenerator adds the parent id parameter to create and edit screens of nested entities and passes it to providers
- [x] #2 The edit screen of a nested entity watches the detail provider with the (id, parentId) record
- [x] #3 The detail screen's Edit action navigates to the nested edit path
- [x] #4 The detail screen's Delete action uses the family list provider with the parent id
- [x] #5 Navigation paths are built in one shared helper used by all generators, instead of being duplicated per generator
- [x] #6 Generator tests cover create, edit, delete and navigation for a nested entity
<!-- AC:END -->

## Implementation Notes

- Added `EntityPaths` (`manifest/entity_paths.dart`), used by the list and detail generators; a missing parent entity now fails generation instead of guessing `{parent}s`.
- `DetailScreenGenerator` and `FormScreenGenerator` are now library-level generators (like the list generator). Before, a source file with two `@View` classes (any nested entity) emitted the header and imports twice and produced invalid Dart.
- Tests: `test/nested_screens_test.dart`.
- `RoutesGenerator` now validates parents through `EntityPaths` too (a nested entity whose parent is missing used to silently lose its routes). Its route tree stays relative because GoRouter nests routes; the absolute paths used by `context.push` all come from `EntityPaths`.
- Former #7 (example app's nested entity compiles and works) is covered by PF-9 AC #6 and #5, since the example app does not exist yet.
