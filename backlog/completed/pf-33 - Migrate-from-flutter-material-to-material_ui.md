---
id: PF-33
title: Migrate from flutter/material.dart to material_ui
status: Done
assignee: []
created_date: '2026-11-18 20:20'
updated_date: '2026-11-18 20:20'
labels: []
dependencies: []
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Flutter 3.50 deprecates `package:flutter/material.dart` in favour of the separate `material_ui` package (requires Flutter >= 3.47). With `--fatal-infos`, CI for prefab_flutter_widgets fails on the deprecation, so CI is pinned to Flutter 3.47.9 for now. Generated screens also import `package:flutter/material.dart`, so apps on Flutter 3.50+ get deprecation warnings in generated code.

Decide the minimum supported Flutter version, then migrate both the runtime widgets and the generated imports.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 The minimum supported Flutter version is decided and set in prefab_flutter_widgets/pubspec.yaml
- [x] #2 prefab_flutter_widgets imports package:material_ui instead of package:flutter/material.dart and depends on material_ui
- [x] #3 The list, detail and form screen generators emit package:material_ui imports, and the README tells apps to add the dependency
- [x] #4 The Flutter version pin in .github/workflows/ci.yml is removed (or moved to the new minimum) and CI is green on current stable
- [x] #5 Generator tests, the README and the user guide are updated
<!-- AC:END -->

## Implementation Notes

Minimum Flutter is 3.47.0 (required by material_ui ^1.11.1). CI runs on current stable; not verified locally (no Flutter SDK in the authoring environment).

