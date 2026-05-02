---
id: PF-10
title: Publish packages to pub.dev
status: To Do
assignee: []
created_date: '2026-05-02 06:06'
labels: []
dependencies: []
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The three packages (prefab_flutter_annotations, prefab_flutter, and the runtime widgets package) need to be published to pub.dev so they can be consumed without path dependencies.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 All packages pass dart pub publish --dry-run without warnings
- [ ] #2 CHANGELOG.md and README.md are present and accurate for each package
- [ ] #3 Packages are published and resolvable via pub.dev
<!-- AC:END -->
