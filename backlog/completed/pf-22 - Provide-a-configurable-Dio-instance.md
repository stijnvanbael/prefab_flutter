---
id: PF-22
title: Provide a configurable Dio instance
status: Done
assignee: []
created_date: '2026-11-18 10:00'
updated_date: '2026-11-18 10:00'
labels: []
dependencies: []
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Every generated {entity}ApiClientProvider calls ref.watch(dioProvider), but dioProvider is not defined anywhere, so generated code cannot compile in a real app. Provide it from prefab_flutter_widgets so apps configure the base URL, auth and interceptors in one place.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 prefab_flutter_widgets exports a prefabDioProvider that throws a descriptive UnimplementedError unless overridden
- [x] #2 Generated API client providers watch prefabDioProvider and import prefab_flutter_widgets
- [x] #3 prefab_flutter_widgets depends on dio and flutter_riverpod with documented version ranges
- [x] #4 The README quick-start and the user guide show how to override prefabDioProvider in ProviderScope
- [x] #5 Generator tests are updated
<!-- AC:END -->

## Implementation Notes

Added `prefabDioProvider` (prefab_flutter_widgets), switched the generated provider to it, updated README, user guide, CHANGELOG and tests. Dart/Flutter are not installed in the authoring environment, so tests were not run locally; rely on CI.
