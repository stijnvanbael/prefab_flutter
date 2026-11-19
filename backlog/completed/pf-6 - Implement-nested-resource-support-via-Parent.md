---
id: PF-6
title: Implement nested resource support via @Parent
status: Done
assignee: []
created_date: '2026-05-02 06:05'
labels: []
dependencies: []
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The @Parent annotation is parsed in FieldManifest.isParent but none of the generators use it. When a field is annotated with @Parent, list and detail screens must be scoped under the parent route and the API path must inject the parent ID as a path parameter.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 RoutesGenerator nests entity routes under the parent entity route when @Parent is present
- [x] #2 ApiClientGenerator injects parent ID path parameters into list, getById, create, update and delete calls
- [x] #3 ProviderGenerator accepts and threads the parent ID through all operations
- [x] #4 ListScreenGenerator reads the parent ID from the route and passes it to the provider
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Merged in PR #5/#6. Known gaps found during the 2026-11 review: the form screens ignore @Parent, and the detail screen's Edit/Delete actions use the un-nested path and provider, so nested create/edit/delete does not compile. Tracked in PF-25. The parent is identified by field-name convention ({parent}Id) and must live in the same source file; a type-safe replacement is tracked in PF-24.
<!-- SECTION:NOTES:END -->
