---
id: PF-68
title: Keep feature contributions when promoting a screen
status: Done
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
- [x] #1 `promote` output for a list or detail screen includes the actions and screen links the generated screen has
- [x] #2 A contribution that targets a promoted screen produces a build warning naming the screen and the contribution
- [x] #3 Tests cover the promote output with actions and screen links, and the warning
- [x] #4 docs/user_guide/promoting.md and actions.md describe the behaviour; the Known limitations row is removed
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
- `promote` scans `lib/` for `@EntityAction` and `@EntityScreen` (`scanPackageContributions`) and passes them to the emitter, so the file contains them.
- `ArtifactSet.promotedName` / `warn`: the actions and entity_screens features warn (`log.warning`) for a promoted screen. The warning appears on every build, since the generator cannot tell whether the promoted screen already calls the function.
- Example app: it has no promoted screen with contributions and the change is a command and a build warning; covered by generator tests instead.
<!-- SECTION:NOTES:END -->
