---
id: PF-62
title: Migrate nested resources and breadcrumbs into feature modules
status: Done
assignee: []
created_date: '2026-11-20 10:00'
labels: []
milestone: m-0
dependencies:
  - PF-39
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Move `@Parent` handling (ancestor ids, `familyKey`, child routes, `ancestorImports`) into `lib/src/features/nested_resources/` and `breadcrumbs.dart` into `lib/src/features/breadcrumbs/`, using `appBarBottom`, `familyKey`, `routes` and `childRoutes` points. The artifacts need those points first (small, separate change per artifact).

Follow "Adding a feature" in `docs/developer_guide.md` and the pattern of `lib/src/features/list_query/` (PF-39). The snapshot tests must pass without changes to the expected files.

Expected to touch:
- `prefab_flutter_generator/lib/src/generators/breadcrumbs.dart`
- `prefab_flutter_generator/lib/src/generators/routes_generator.dart`
- `prefab_flutter_generator/lib/src/generators/detail_screen_generator.dart`
- `prefab_flutter_generator/lib/src/generators/list_screen_generator.dart`
- `prefab_flutter_generator/lib/src/generators/provider_generator.dart`
- `prefab_flutter_generator/lib/src/generators/api_client_generator.dart`
- `prefab_flutter_generator/lib/src/features/nested_resources/`
- `prefab_flutter_generator/lib/src/features/breadcrumbs/`
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Nested resources and breadcrumbs modules live in `lib/src/features/` and the per-artifact generators no longer contain their code
- [x] #2 The snapshot tests pass without changes to the expected files
- [x] #3 The feature has its own test file; the developer guide and the registry (`features.dart`, alphabetical) are updated; changelog fragment added
- [x] #4 Annotation reading only this feature uses moves out of `entity_manifest.dart`, or the implementation notes say why it stays
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
- New feature modules `features/nested_resources/` and `features/breadcrumbs/`; `generators/breadcrumbs.dart` is gone, and the API client, providers, list/detail screens and routes no longer read `@Parent` ancestors themselves.
- New points: `appBarBottom` (list and detail screen, single-valued), `familyKey` (API client, detail and list provider, list and detail screen; a `ValuePoint<FamilyId>` rendered by `FamilyKey` in `core/family_key.dart`), `routes`, `childRoutes` and `screenArguments` (routes). Nested and root routes now share one route writer.
- List query's notifier statement uses a `{{providerRef}}` placeholder replaced when the list screen is emitted, so it does not depend on feature registration order.
- `hasBreadcrumbs` moved from `EntityManifest` into the breadcrumbs module. AC #4: the `@Parent` reading (`ancestors`, `hasParent`, `parentKeyExpr`, ...) stays in `entity_manifest.dart` and `entity_paths.dart` because the create/edit form screens and the path helpers still use it; it moves with the create/update migration (PF-63).
- The two `entity_actions_test.dart` failures (unknown entity / other entity) also fail on `main` and are unrelated.
<!-- SECTION:NOTES:END -->
