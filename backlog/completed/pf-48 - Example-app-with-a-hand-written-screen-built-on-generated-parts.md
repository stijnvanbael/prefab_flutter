---
id: PF-48
title: Example app with a hand-written screen built on generated parts
status: Done
assignee: []
created_date: '2026-11-20 10:00'
labels: []
milestone: m-1
dependencies:
  - PF-45
  - PF-47
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Show, and keep compiling in CI, how the 20% is written: a hand-written screen in `prefab_flutter_example` that uses generated providers and runtime widgets, reached through the generated navigation. For example a product statistics screen under `/products/:id/stats` that watches `productProvider(id)` and the reviews list provider, uses `PrefabBreadcrumbBar`, and offers a hand-written action (PF-44) on the product detail screen.

This is the end-to-end check of M1: if the screen needs anything the documented API (PF-47) does not offer, that is a bug in M1, not in the example.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 The example app has a hand-written screen that uses at least one generated provider, one runtime widget and the generated navigation (PF-45)
- [x] #2 A widget test in the example app opens the screen from the generated detail screen and checks it shows data from the mock backend
- [x] #3 The example README (or the getting-started section of `README.md`) points to the screen as the reference for hand-written code
- [x] #4 Anything that needed a workaround is fixed or recorded as a new task with a Known limitations row
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
- `ProductStatsScreen` (`@EntityScreen(Product, path: 'stats')`) watches `productDetailProvider` and `reviewsProvider`, uses the generated `productBreadcrumbs`; the promoted detail screen links to it (a promoted detail screen gets no generated tile). Test: `test/product_stats_screen_test.dart`.
- The example also shows an enum dropdown, multi-line text, date picker, number input with `min`/`max`, `maxLength`, and `views`.
- Workaround found: generated validators and dropdowns failed `--fatal-infos`; fixed by an `ignore_for_file` line in the generated banner (changelog PF-48).
- `AGENTS.md` now requires keeping the example app up to date.
<!-- SECTION:NOTES:END -->
