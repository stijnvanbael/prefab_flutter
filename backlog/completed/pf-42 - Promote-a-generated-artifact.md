---
id: PF-42
title: Promote a generated artifact
status: Done
assignee: []
created_date: '2026-11-19 14:00'
labels: []
milestone: m-1
dependencies:
  - PF-38
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Let a developer take over one generated artifact (a screen, provider, API client or routes list) as ordinary code; the generator stops producing it and everything else keeps working with the promoted version (principle 3). The mechanism is fixed in decision-1 (section "Promotion"):

- The developer declares, anywhere under `lib/`, a top-level class or variable with the artifact's primary name (e.g. `ProductDetailScreen`, `productsProvider`) annotated with a new `@Promoted()` annotation from `prefab_flutter`.
- A new `prefab_promoted` builder reads the unresolved syntax of each `lib/**.dart` and writes a `.prefab_promoted.json` summary (build cache) for files with `@Promoted`. `prefab_builder` declares it in `required_inputs` and reads the summaries with `findAssets`.
- The core skips the promoted artifact (and all its declared names), imports the promoted library and re-exports the name with `export '<uri>' show <Name>;`.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 `@Promoted()` exists in `prefab_flutter` and is documented
- [x] #2 Promoting any artifact kind (API client, detail provider, list provider with its notifier, each screen, routes) skips it in the generated library, imports the promoted library and re-exports the name; the other artifacts compile against it
- [x] #3 A `@Promoted` declaration whose name is not a generated artifact fails the build with the closest artifact name as a suggestion
- [x] #4 Editing a file without `@Promoted` does not change any summary (no full regeneration)
- [x] #5 The user guide documents the public signature each promoted artifact kind must keep (screen constructor parameters, provider type and family key, API client methods)
- [x] #6 The example app promotes one screen, and CI compiles it
- [x] #7 Snapshot tests cover a promoted artifact; changelog fragments added
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
A command that writes one artifact to a file with its imports and `@Promoted()` (`dart run prefab_flutter_generator:promote ProductDetailScreen`) is suggested in decision-1 but not part of this task.

Implemented as in decision-1. Deviations and notes:
- Only the primary name is matched; the notifier or private state class is skipped with its artifact.
- Unknown-name detection runs in `prefab_builder`: names the file does not generate are looked up in the package's other `@View` libraries (resolved), so it costs extra resolution only when a promotion exists.
- Signature checks with custom errors were not added; a wrong signature is a compile error at the generated call site (documented per kind in the user guide).
- The `promote` command is not implemented; task PF-49.
- Signature checks with build errors: task PF-70.
<!-- SECTION:NOTES:END -->
