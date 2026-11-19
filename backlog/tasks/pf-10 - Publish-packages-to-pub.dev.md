---
id: PF-10
title: Publish packages to pub.dev
status: In Progress
assignee: []
created_date: '2026-05-02 06:06'
labels: []
dependencies: []
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The three library packages (prefab_flutter, prefab_flutter_generator and prefab_flutter_widgets) need to be published to pub.dev so they can be consumed without path dependencies.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 All packages pass dart pub publish --dry-run without warnings
- [x] #2 CHANGELOG.md and README.md are present and accurate for each package
- [ ] #3 Packages are published and resolvable via pub.dev
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Packages are prepared (metadata, CHANGELOGs, READMEs) but not published: prefab_flutter_generator still uses a dependency_overrides path dependency. Publishing waited until generated code compiled end-to-end (PF-9, PF-22, PF-25); those are done, so this task is no longer blocked.
<!-- SECTION:NOTES:END -->
