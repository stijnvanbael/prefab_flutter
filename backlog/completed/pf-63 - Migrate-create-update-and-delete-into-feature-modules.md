---
id: PF-63
title: Migrate create, update and delete into feature modules
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
Move the create button, edit and delete actions, the create/update/delete notifier methods and API client methods into `lib/src/features/create/`, `update/` and `delete/`. The create and update features register the create and edit screen artifact factories. Uses `floatingActionButton`, detail `appBarActions`, the notifier `methods` and the API client `methods` points.

Follow "Adding a feature" in `docs/developer_guide.md` and the pattern of `lib/src/features/list_query/` (PF-39). The snapshot tests must pass without changes to the expected files.

Expected to touch:
- `prefab_flutter_generator/lib/src/generators/api_client_generator.dart`
- `prefab_flutter_generator/lib/src/generators/provider_generator.dart`
- `prefab_flutter_generator/lib/src/generators/detail_screen_generator.dart`
- `prefab_flutter_generator/lib/src/generators/list_screen_generator.dart`
- `prefab_flutter_generator/lib/src/generators/form_screen_generator.dart`
- `prefab_flutter_generator/lib/src/generators/routes_generator.dart`
- `prefab_flutter_generator/lib/src/features/create/`
- `prefab_flutter_generator/lib/src/features/update/`
- `prefab_flutter_generator/lib/src/features/delete/`
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Create, update and delete modules live in `lib/src/features/` and the per-artifact generators no longer contain their code
- [x] #2 The snapshot tests pass without changes to the expected files
- [x] #3 The feature has its own test file; the developer guide and the registry (`features.dart`, alphabetical) are updated; changelog fragment added
- [x] #4 Annotation reading only this feature uses moves out of `entity_manifest.dart`, or the implementation notes say why it stays
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
- `lib/src/features/create/`, `update/` and `delete/` hold the modules. `create` and `update` register the create and edit screen artifact factories (`CreateScreenArtifact`, `EditScreenArtifact`); the form state template they share stays in `generators/form_screen_generator.dart` (now `FormScreenArtifact`). New extension points: API client `methods`, list screen `floatingActionButton`, routes `listChildRoutes` (create) and the existing `detailChildRoutes` (edit); contributions that need the nested-resource ids use `addLazy`; the existing list notifier `methods` and detail screen `appBarActions` carry the rest.
- Features can now add artifacts that land in kind order (the emitter groups by `ArtifactKind`), and the per-kind generators take a `kinds` filter so registering all features does not add screens to, say, the API client output. The snapshot files are unchanged.
- The API client's `delete` method is still generated for every entity, with or without `@Delete` (existing behaviour, kept so the snapshots stay unchanged); `DeleteFeature` contributes it unconditionally.
- AC#4: `hasCreate`, `hasUpdate` and `hasDelete` stay in `entity_manifest.dart` as plain flags. They are read together with the other annotations and are looked at by several features (screens, routes, providers), so they are not feature-only reads; the developer guide says so.
- The example app steps pass (`build_runner`, `flutter analyze --fatal-infos`, `flutter test`); the generated output is unchanged.
<!-- SECTION:NOTES:END -->
