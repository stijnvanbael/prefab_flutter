---
id: PF-20
title: Getting started README and developer guide
status: To Do
assignee: []
created_date: '2026-05-03 10:30'
updated_date: '2026-05-03 10:30'
labels: []
dependencies: []
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The repository and its three packages lack user-facing documentation. New users have no guide explaining how to add prefab_flutter to a Flutter project, annotate their models, run build_runner, and wire up the generated code. Maintainers and contributors also need a developer guide covering the repository layout, how to add a new generator, how to run the tests, and the release process.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 The root README.md contains a quick-start section: add dependencies, annotate a model, run build_runner, register $prefabRoutes
- [ ] #2 The root README.md documents all annotations (@View, @FormField, @Update, @Delete, @Parent) with code examples
- [ ] #3 The root README.md documents all FieldWidget values and Validator values with brief descriptions
- [ ] #4 A DEVELOPER_GUIDE.md (or docs/developer_guide.md) describes the three-package layout and the role of each package
- [ ] #5 The developer guide explains how to add a new generator: where to place it, how to register it in builder.dart, and how to write a build_test unit test for it
- [ ] #6 The developer guide covers running tests (dart test in each package) and the pub publish checklist
- [ ] #7 Each package's own README.md links back to the root README and pub.dev badge once published
<!-- AC:END -->
