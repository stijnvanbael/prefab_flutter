---
id: PF-27
title: Avoid $prefabRoutes name clashes across files
status: To Do
assignee: []
created_date: '2026-11-18 10:00'
updated_date: '2026-11-18 10:00'
labels: []
dependencies: []
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Each annotated source file produces its own top-level $prefabRoutes getter. An app with entities in two files that imports both generated route files gets a name conflict. Give each file a unique name and offer an easy way to combine them.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Each generated routes file exposes a uniquely named getter derived from the source file name (e.g. $productRoutes for product.dart)
- [ ] #2 The README and user guide show how to combine several route lists in one GoRouter
- [ ] #3 A migration note is added to the CHANGELOG
- [ ] #4 Generator tests are updated
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Consider generating an aggregated list across the whole package with a separate aggregating builder; this is optional and can be a follow-up.
<!-- SECTION:NOTES:END -->
