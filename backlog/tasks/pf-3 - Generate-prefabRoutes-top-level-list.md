---
id: PF-3
title: Generate $prefabRoutes top-level list
status: To Do
assignee: []
created_date: '2026-05-02 06:04'
labels: []
dependencies: []
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The router.dart in the example uses $prefabRoutes to register all routes with GoRouter, but this list is never generated. RoutesGenerator must emit a top-level const list collecting all TypedGoRoute declarations across all @View entities.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 $prefabRoutes list is generated and contains all entity routes
- [ ] #2 The example router.dart compiles and navigates correctly using $prefabRoutes
- [ ] #3 Multiple entities produce one combined $prefabRoutes list
<!-- AC:END -->
