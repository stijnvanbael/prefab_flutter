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
The three packages (prefab_flutter_annotations, prefab_flutter, and the runtime widgets package) need to be published to pub.dev so they can be consumed without path dependencies.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 All packages pass dart pub publish --dry-run without warnings
- [x] #2 CHANGELOG.md and README.md are present and accurate for each package
- [ ] #3 Packages are published and resolvable via pub.dev
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Packages are prepared (metadata, CHANGELOGs, READMEs) but not published: prefab_flutter_generator still uses a dependency_overrides path dependency. Publishing should wait until generated code compiles end-to-end (PF-9, PF-22, PF-25), otherwise 0.1.0 would ship code that cannot build.
<!-- SECTION:NOTES:END -->
