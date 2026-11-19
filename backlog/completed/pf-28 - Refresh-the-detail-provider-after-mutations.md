---
id: PF-28
title: Refresh the detail provider after mutations
status: Done
assignee: []
created_date: '2026-11-18 10:00'
updated_date: '2026-11-18 10:00'
labels: []
dependencies:
  - PF-29
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
update() reloads the list provider but the cached {entity}DetailProvider for that id is never invalidated, so the detail screen shows stale data after editing. After delete, the detail provider for the deleted id should also be discarded.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 After a successful update, the detail provider for the entity's id is invalidated
- [x] #2 After a successful delete, the detail provider for the entity's id is invalidated
- [x] #3 Generator tests cover the invalidation calls
<!-- AC:END -->

## Implementation Notes

Notifier now receives a `Ref` and calls `_ref.invalidate({entity}DetailProvider(id))` (or `(id, parentId)` for `@Parent` entities) after `update` and `delete`, before reloading the list. Implemented on the current StateNotifier; PF-29's Notifier migration should keep the invalidation calls.
