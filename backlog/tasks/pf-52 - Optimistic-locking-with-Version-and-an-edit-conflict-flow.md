---
id: PF-52
title: Optimistic locking with @Version and an edit-conflict flow
status: To Do
assignee: []
created_date: '2026-11-20 10:00'
labels: []
milestone: m-2
dependencies:
  - PF-51
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Prefab entities carry a version for optimistic locking; an update with a stale version is rejected with 409 Conflict. Principle 5 lists edit conflicts as something handled out of the box.

Recognise the version field (by a `@Version` annotation in `prefab_flutter`, inferred from a field named `version` per principle 2), send it with updates as the backend adapter says (body field or `If-Match` header), and on 409 show a "changed by someone else" dialog that offers to reload the latest version (discarding or keeping the user's input where fields did not change) or to cancel.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 `@Version` exists and a field named `version` is used when no field carries it; the version field is never shown as an editable form field
- [ ] #2 Updates send the version as configured by the backend adapter (Prefab preset decides the default)
- [ ] #3 A 409 on save shows a conflict dialog with reload and cancel; reload refreshes the detail provider and the form
- [ ] #4 Tests cover the version being sent and the conflict flow; `docs/user_guide/annotations.md` documents `@Version`; changelog fragments added
<!-- AC:END -->
