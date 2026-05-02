---
id: PF-2
title: Implement detail screen generator
status: Done
assignee: []
created_date: '2026-05-02 06:03'
updated_date: '2026-05-02 06:03'
labels: []
dependencies: []
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The generated routes and list screen navigate to EntityDetailScreen (e.g. ProductDetailScreen) but no DetailScreenGenerator exists. It must generate a read-only detail view populated from the detail provider.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 DetailScreenGenerator emits a ConsumerWidget showing all non-hidden fields
- [x] #2 Each field is rendered as a labelled read-only tile
- [x] #3 AppBar title uses the entity title from @View
- [x] #4 Edit and Delete actions wired from the detail screen when @Update/@Delete are present
- [x] #5 DetailScreenGenerator is registered in builder.dart alongside existing generators
<!-- AC:END -->
