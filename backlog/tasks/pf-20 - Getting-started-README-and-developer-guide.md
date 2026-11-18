---
id: PF-20
title: Getting started README and developer guide
status: In Progress
assignee: []
created_date: '2026-05-03 10:30'
updated_date: '2026-11-18 10:00'
labels: []
dependencies: []
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The repository lacked user-facing documentation. The root README.md and docs/user_guide.md now exist; AGENTS.md requires them to be kept up to date with every change. What remains is a developer guide for contributors and links from the package READMEs.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 The root README.md contains a quick-start: add dependencies, annotate a model, run build_runner, register $prefabRoutes
- [x] #2 docs/user_guide.md documents all annotations with code examples
- [x] #3 docs/user_guide.md documents all FieldWidget and Validator values and the generated files
- [ ] #4 docs/developer_guide.md describes the three-package layout and the role of each package
- [ ] #5 The developer guide explains how to add a new generator: where to place it, how to register it in builder.dart and build.yaml, and how to test it
- [ ] #6 The developer guide covers running tests (dart test / flutter test per package) and the pub publish checklist
- [ ] #7 Each package's README.md links back to the root README and the user guide, and shows a pub.dev badge once published
<!-- AC:END -->
