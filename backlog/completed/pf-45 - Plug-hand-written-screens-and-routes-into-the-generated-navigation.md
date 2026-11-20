---
id: PF-45
title: Plug hand-written screens and routes into the generated navigation
status: Done
assignee: []
created_date: '2026-11-20 10:00'
labels: []
milestone: m-1
dependencies:
  - PF-39
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Both reference apps have a central hand-written screen (live energy flow, a study session) that belongs to an entity: `/sites/:id/live`, `/courses/:id/study`. Today a developer can append their own `GoRoute` to `$siteRoutes`, but it cannot sit under the entity's detail route with the typed id and ancestor ids, generated screens do not link to it, and breadcrumbs (PF-19) do not know it.

Let the developer declare a hand-written screen as a child of an entity, e.g. `@EntityScreen(Site, path: 'live', title: 'Live')` on a widget class whose constructor takes the entity id (and ancestor ids, for nested entities). The generator adds the route under the detail route, converting the ids as it does for generated screens, and a navigation entry on the detail screen. Use the same cross-file discovery as PF-42 and PF-44.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 A hand-written screen can be declared as a child screen of an entity; its route is generated under `/{path}/:id/{child}` and passes the typed id and ancestor ids to its constructor
- [x] #2 The entity's detail screen links to the child screen (sharing the navigation entries of PF-35 if that is done, otherwise as its own extension point contribution)
- [x] #3 The breadcrumb bar on a hand-written child screen can be built from a generated helper, so the screen looks like the generated ones
- [x] #4 A screen whose constructor does not match the expected id parameters fails the build with a readable error
- [x] #5 `docs/user_guide/routes.md` documents the declaration and the generated route; snapshot fixture and test file added; changelog fragments added
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
- New `@EntityScreen(Entity, path:, title:)` annotation (`prefab_flutter`). A `prefab_screens` builder summarises the declarations of each file from the syntax tree (`.prefab_screens.json`, same approach as `@Promoted`), so the screen may live in any file; PF-44 can reuse it when it lands.
- Feature module `features/entity_screens/` contributes the route (new `routes.detailChildRoutes` point), the detail-screen link tile (new `detailScreen.afterFields` point, own contribution since PF-35 is not done) and the `{entity}Breadcrumbs` artifact. Constructors are checked against the id parameters; path clashes (`edit`, nested entity paths, duplicates) and unknown entities fail the build.
- Verified with a snapshot fixture, `test/entity_screens_feature_test.dart` and an example screen (`ReviewSummaryScreen`, nested under Product).
- Not done: the link tile is only generated into the detail screen, not into list screens; the entity must be matched by class name (two `@View` classes with the same name in different libraries are not distinguished).
<!-- SECTION:NOTES:END -->
