---
id: PF-6
title: Implement nested resource support via @Parent
status: To Do
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
- [ ] #1 RoutesGenerator nests entity routes under the parent entity route when @Parent is present
- [ ] #2 ApiClientGenerator injects parent ID path parameters into list, getById, create, update and delete calls
- [ ] #3 ProviderGenerator accepts and threads the parent ID through all operations
- [ ] #4 ListScreenGenerator reads the parent ID from the route and passes it to the provider
<!-- AC:END -->
