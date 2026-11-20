---
id: PF-66
title: Link hand-written entity screens from list screens
status: Done
assignee: []
created_date: '2026-11-20 12:00'
labels: []
dependencies:
  - PF-45
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
A screen declared with `@EntityScreen(Entity, path:, title:)` gets a link tile on the generated detail screen only. List screens do not link to it, so a hand-written screen that applies to one item (e.g. statistics of a product) is one extra tap away from the list. Left open after PF-45.

Offer the link in the list screen, for example as an item menu entry next to the `Place.item` actions of PF-44, so both share the rendering in `features/actions/action_rendering.dart`.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 A list item offers a navigation entry per `@EntityScreen` of its entity, labelled with the screen's `title`, that pushes the screen's route with the item's ids
- [x] #2 The entry is ordered and rendered consistently with item actions (PF-44)
- [x] #3 Works for nested entities (all ancestor ids are passed)
- [x] #4 A snapshot fixture or feature test covers it, and the example app shows it with a widget test
- [x] #5 docs/user_guide/routes.md describes it and the Known limitations row is removed
<!-- AC:END -->
