---
id: PF-44
title: Custom actions on list and detail screens
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
Business apps need actions beyond Edit and Delete ("Duplicate", "Send invoice", "Start charging"). Today the only way to add one is to promote the screen. Let the developer add a hand-written action to the generated list screen (per item and in the AppBar) and detail screen, without promoting them.

Design to settle in the task, following principles 1 and 4: an annotation on a top-level function, e.g.

```dart
@EntityAction(Product, label: 'Duplicate', icon: Icons.copy, on: {ActionPlace.detail})
Future<void> duplicateProduct(BuildContext context, WidgetRef ref, Product product) async { ... }
```

The generator must find these functions in other files of the package; reuse the summary-builder pattern of PF-42 (`prefab_promoted`) instead of resolving every library. Contribute the actions through the detail screen's `appBarActions` extension point and a list-screen point for item actions (add the point if it is missing, as a separate small change).

Named domain operations from Prefab (`@Update(path = ...)`, M2, PF-54) will appear in the same places, so the rendering (icon button vs. overflow menu, ordering, disabled while loading) is shared.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 A hand-written function can be declared as an action of an entity on the detail screen, the list screen AppBar or each list item, with a label and an optional icon
- [x] #2 The detail screen shows up to two actions as icon buttons and the rest in an overflow menu; list item actions appear in a trailing menu; the order follows a documented rule (e.g. declaration order, then name)
- [x] #3 The action receives the `BuildContext`, a `WidgetRef` and the entity (detail, item) or nothing (list AppBar); after it completes the list and detail providers can be refreshed with a documented call
- [x] #4 Actions on a promoted screen are not contributed (the `ArtifactSet` lookup returns null) and the build says nothing
- [x] #5 An action function with the wrong signature fails the build with a readable error
- [x] #6 Feature module, test file and a snapshot fixture; `docs/user_guide/` gets an "Actions" section on the annotations page or its own page; changelog fragments added
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
- `@EntityAction(Entity, label:, icon:, on:, order:)` and `ActionPlace` (`detail`, `list`, `item`) live in `prefab_flutter`. `icon` is the name of a member of `Icons` as a string, because `prefab_flutter` is a pure Dart package and cannot reference `IconData` (principle: keep the annotation package free of Flutter). `order` is an addition to the task text so that ordering across files is deterministic: sorted by order, label, function name.
- Discovery follows PF-42: the `prefab_actions` builder scans the unresolved syntax tree and writes `<file>.prefab_actions.json` only for files with `@EntityAction`; `prefab_builder` requires them. Signature errors (AC#5) are raised by that builder; an unknown entity is raised by the generator.
- New feature module `features/actions/` with the shared rendering (`action_rendering.dart`: two icon buttons, the rest in an overflow menu), which PF-54 can reuse for named operations. New extension points: `detailScreen.appBarActions`, `listScreen.itemActions`.
- The `promote` command does not copy actions into the promoted file; documented on the Actions page; task PF-68.
- Example app: `prefab_flutter_example/lib/actions.dart` with widget tests in `test/crud_flow_test.dart`.
<!-- SECTION:NOTES:END -->
