---
id: PF-19
title: Multi-level nesting and AppBar breadcrumbs
status: To Do
assignee: []
created_date: '2026-05-03 10:30'
updated_date: '2026-05-03 10:30'
labels: []
dependencies: []
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The @Parent mechanism currently supports exactly one level of nesting (e.g. Post → Comment). Extend RoutesGenerator, ApiClientGenerator, ProviderGenerator, and the list/detail screen generators to handle arbitrarily deep chains (e.g. Order → OrderLine → OrderLineNote). Additionally, generate an AppBar breadcrumb trail in list and detail screens when the nesting depth is two or more, so users can navigate back to any ancestor level without using the back button repeatedly.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 EntityManifest resolves the full ancestor chain for an entity with multiple levels of @Parent references
- [ ] #2 RoutesGenerator nests routes correctly for chains of depth >= 2
- [ ] #3 ApiClientGenerator injects all ancestor ID path parameters for deeply nested entities
- [ ] #4 ProviderGenerator threads all ancestor IDs through list, detail, create, update, and delete operations
- [ ] #5 ListScreenGenerator and DetailScreenGenerator emit a breadcrumb row (e.g. TextButton chain) in the AppBar bottom when depth >= 2
- [ ] #6 A unit test covers a three-level chain (grandparent → parent → child)
<!-- AC:END -->
