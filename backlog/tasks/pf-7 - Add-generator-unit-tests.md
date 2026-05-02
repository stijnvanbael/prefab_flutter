---
id: PF-7
title: Add generator unit tests
status: To Do
assignee: []
created_date: '2026-05-02 06:05'
labels: []
dependencies: []
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
No tests exist for any of the five generators. Each generator must have unit tests that verify the generated source code for a representative annotated class using build_test.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 ListScreenGenerator test covers search bar presence when searchable fields exist
- [ ] #2 ListScreenGenerator test covers sort column presence when sortable fields exist
- [ ] #3 FormScreenGenerator test covers create and edit screen generation
- [ ] #4 ProviderGenerator test covers create, update and delete method generation
- [ ] #5 ApiClientGenerator test covers all HTTP method stubs
- [ ] #6 RoutesGenerator test covers route class and sub-route generation
<!-- AC:END -->
