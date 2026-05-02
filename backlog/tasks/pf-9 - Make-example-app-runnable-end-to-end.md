---
id: PF-9
title: Make example app runnable end-to-end
status: To Do
assignee: []
created_date: '2026-05-02 06:06'
labels: []
dependencies: []
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The prefab_flutter_example cannot compile or run because the runtime widgets library is missing, dio_provider.g.dart is not committed, and product.g.dart (json_serializable) is absent. Once the dependent tasks are complete, the example must build, run and demonstrate a full CRUD flow against a local backend.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 flutter pub run build_runner build succeeds without errors
- [ ] #2 App launches and displays the Products list screen
- [ ] #3 Create, edit and delete product flows work against a mock or local backend
- [ ] #4 README documents how to run the example
<!-- AC:END -->
