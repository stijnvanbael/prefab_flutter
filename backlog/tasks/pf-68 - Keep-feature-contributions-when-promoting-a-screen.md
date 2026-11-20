---
id: PF-68
title: Keep feature contributions when promoting a screen
status: To Do
assignee: []
created_date: '2026-11-20 12:00'
labels: []
dependencies:
  - PF-42
  - PF-49
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Features contribute to generated screens through extension points: custom actions (PF-44, `detailScreen.appBarActions`, `listScreen.itemActions`) and links to hand-written screens (PF-45, `detailScreen.afterFields`). When a screen is promoted, these contributions are skipped without a message, and the `promote` command does not copy them into the promoted file. Promoting a screen therefore silently loses behaviour, and every milestone that adds contributions (M2: server errors on fields, edit conflicts, named operations) makes promotion more expensive. This works against principle 3, "promotable at any time".

Make promotion lossless or loud:
- The `promote` command writes the screen *with* its current contributions (actions, screen links) as plain code, so the promoted file behaves the same as the generated screen it replaces.
- When a contribution is added later for a screen that is already promoted (a new `@EntityAction` or `@EntityScreen`), the build logs a warning naming the promoted screen and what it does not show.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 `promote` output for a list or detail screen includes the actions and screen links the generated screen has
- [ ] #2 A contribution that targets a promoted screen produces a build warning naming the screen and the contribution
- [ ] #3 Tests cover the promote output with actions and screen links, and the warning
- [ ] #4 docs/user_guide/promoting.md and actions.md describe the behaviour; the Known limitations row is removed
<!-- AC:END -->
