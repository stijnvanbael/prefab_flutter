---
id: PF-9
title: Make example app runnable end-to-end
status: Done
assignee: []
created_date: '2026-05-02 06:06'
labels: []
dependencies:
  - PF-22
  - PF-12
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The prefab_flutter_example cannot compile or run because the runtime widgets library is missing, dio_provider.g.dart is not committed, and product.g.dart (json_serializable) is absent. Once the dependent tasks are complete, the example must build, run and demonstrate a full CRUD flow against a local backend.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 flutter pub run build_runner build succeeds without errors
- [x] #2 App launches and displays the Products list screen
- [x] #3 Create, edit and delete product flows work against a mock or local backend
- [x] #4 README documents how to run the example
- [x] #5 CI runs build_runner on the example app and `flutter analyze --fatal-infos` on the result, so generated code that does not compile fails the build
- [x] #6 The example covers at least one top-level entity and one nested (@Parent) entity
- [x] #7 The example entity uses json_serializable (`fromJson`/`toJson`) and the generated client deserializes responses correctly (moved from PF-12 AC #6)
- [x] #8 Creating and editing an entity in the example app round-trips through the generated form save (create()/update()) against the backend (moved from PF-11 AC#8)
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
- Added `prefab_flutter_example` (Product + nested Review, in-memory Dio mock backend, web scaffold). Generated files are not committed; CI runs `build_runner`, `flutter analyze --fatal-infos` and `flutter test` on it.
- `test/crud_flow_test.dart` drives create/edit/delete for products and create/edit for nested reviews through the generated screens (covers AC #2, #3, #7, #8). The app was not launched in a real browser in this session; the widget tests are the evidence.
- Bugs found and fixed in the generator: notifier `update` clashed with `AsyncNotifier.update` (renamed `updateEntity`); nullable ids (`int? id`) were passed to non-null providers; `/create` was shadowed by `/:id` (create route now first); unused `_item` lint in the edit screen.
- Not done: detail screens do not link to nested child lists (tracked under PF-19).
<!-- SECTION:NOTES:END -->
