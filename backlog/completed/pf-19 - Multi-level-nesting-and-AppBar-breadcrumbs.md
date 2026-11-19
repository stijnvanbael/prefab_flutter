---
id: PF-19
title: Multi-level nesting and AppBar breadcrumbs
status: Done
assignee: []
created_date: '2026-05-03 10:30'
updated_date: '2026-11-19 10:00'
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
- [x] #1 EntityManifest resolves the full ancestor chain from @Parent(Type) references (PF-24)
- [x] #2 RoutesGenerator nests routes for chains of depth >= 2 with unique path parameter names per level
- [x] #3 ApiClientGenerator injects all ancestor ids as path parameters
- [x] #4 ProviderGenerator threads all ancestor ids through list, detail, create, update and delete
- [x] #5 List and detail screens show a breadcrumb row in the AppBar bottom when depth >= 2; ancestor labels come from the ancestors' detail providers
- [x] #6 A unit test covers a three-level chain
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
- `EntityManifest.ancestors` resolves the whole `@Parent` chain (outermost first, cross-file, cycle detection). Direct-parent id parameters keep the `@Parent` field name; other ancestors use `<entity>Id`, which is also the unique route path parameter per level.
- List provider families are keyed on the parent id (one ancestor) or a positional record of ancestor ids; detail providers on `(id, ancestor ids...)`.
- Breadcrumbs (`PrefabBreadcrumbBar`, new in `prefab_flutter_widgets`) show for entities with two or more ancestors, labelled with the ancestor's first visible field from its detail provider.
- The example app gained `Reply` (Product -> Review -> Reply) with a widget test covering breadcrumbs and jumping back.
- Not done: detail screens still do not link to nested child lists (listed in the user guide's known limitations, no task yet).
- Behaviour change: the path parameter of a parent declared in another file is now named `<entity>Id` instead of the `@Parent` field name.
<!-- SECTION:NOTES:END -->
