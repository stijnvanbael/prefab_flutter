---
id: PF-19
title: Multi-level nesting and AppBar breadcrumbs
status: To Do
assignee: []
created_date: '2026-05-03 10:30'
updated_date: '2026-11-18 10:00'
labels: []
dependencies:
  - PF-24
  - PF-25
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The @Parent mechanism supports one level of nesting (e.g. Post -> Comment). Extend all generators to arbitrarily deep chains (e.g. Order -> OrderLine -> OrderLineNote), and show breadcrumbs in list and detail screens from depth two, so users can jump back to any ancestor.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 EntityManifest resolves the full ancestor chain from @Parent(Type) references (PF-24)
- [ ] #2 RoutesGenerator nests routes for chains of depth >= 2 with unique path parameter names per level
- [ ] #3 ApiClientGenerator injects all ancestor ids as path parameters
- [ ] #4 ProviderGenerator threads all ancestor ids through list, detail, create, update and delete
- [ ] #5 List and detail screens show a breadcrumb row in the AppBar bottom when depth >= 2; ancestor labels come from the ancestors' detail providers
- [ ] #6 A unit test covers a three-level chain
<!-- AC:END -->
