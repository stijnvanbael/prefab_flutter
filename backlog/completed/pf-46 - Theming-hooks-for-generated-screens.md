---
id: PF-46
title: Theming hooks for generated screens
status: Done
assignee: []
created_date: '2026-11-20 10:00'
labels: []
milestone: m-1
dependencies:
  - PF-39
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Generated screens should follow the app's look without being promoted. They already use the ambient Material `Theme`, but the layout decisions made by the templates (paddings, list tile shape, the empty, loading and error states, the form layout and its save button, the detail field layout) can only be changed by promoting each screen.

Add a `PrefabTheme` `ThemeExtension` in `prefab_flutter_widgets` that generated screens read for these decisions, with defaults that keep today's output. Where a decision is a widget rather than a value (the empty, loading and error states), the extension holds a builder. Keep it plain Flutter (principle 4): an app sets it in `ThemeData.extensions`, and screens fall back to the defaults when it is absent.

Do not add hardcoded English strings: the empty and error builders receive what happened, and localisation of the default texts is M3.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 `PrefabTheme` exists as a `ThemeExtension` with `copyWith`, `lerp` and defaults equal to today's look; generated screens render the same without it
- [x] #2 List, detail and form screens read paddings, the empty, loading and error state builders, and the field layout from it
- [x] #3 A widget test shows a custom empty-state and error-state builder being used by a generated list screen
- [x] #4 `docs/user_guide/runtime-widgets.md` (or a new theming page linked from the index) documents every property with an example
- [x] #5 The example app sets at least one property; changelog fragments added
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
`PrefabTheme` lives in `prefab_flutter_widgets`. The list, detail and form templates read it through `PrefabTheme.of(context)`. The edit screen's error state now uses the shared `Error: <message>` text instead of the bare message. The example app sets `listPadding`; `prefab_flutter_example/test/prefab_theme_test.dart` covers custom empty and error builders on a generated list screen. Principles 4 and 6.
<!-- SECTION:NOTES:END -->
