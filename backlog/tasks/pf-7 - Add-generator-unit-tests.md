---
id: PF-7
title: Add generator unit tests
status: Done
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
- [x] #3 FormScreenGenerator test covers create and edit screen generation
- [x] #4 ProviderGenerator test covers create, update and delete method generation
- [x] #5 ApiClientGenerator test covers all HTTP method stubs
- [x] #6 RoutesGenerator test covers route class and sub-route generation
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Tests exist for all six generators. AC #1 and #2 (search/sort) depend on features that do not exist yet; they moved to PF-13. Note: the tests only assert on generated strings and do not prove the output compiles; see PF-9.
<!-- SECTION:NOTES:END -->
