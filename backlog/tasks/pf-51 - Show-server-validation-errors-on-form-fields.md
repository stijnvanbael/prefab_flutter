---
id: PF-51
title: Show server validation errors on form fields
status: To Do
assignee: []
created_date: '2026-11-20 10:00'
labels: []
milestone: m-2
dependencies:
  - PF-50
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Principle 5: server-side validation errors appear on the right field. Today a failed save shows `e.toString()` in a SnackBar. Prefab answers invalid requests with RFC 9457 Problem Details that name the invalid fields; 404 and 409 also need a meaningful UI.

Parse error responses through the backend adapter (PF-50) into a typed error (field errors by JSON field name, a general message, the status), map JSON names back to Dart fields (the same mapping as the sort parameter, PF-34), and show field errors under the matching form fields until the field is edited. A 404 on a detail or edit screen shows a "not found" state with a way back to the list; a 409 on save is handled by PF-52.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Field errors from a Problem Details response appear under the matching fields of the create and edit forms; errors for unknown fields and the general message appear above the form
- [ ] #2 JSON field renames (`@JsonKey`, `fieldRename`) are respected when mapping errors to fields
- [ ] #3 A 404 on the detail and edit screens shows a not-found state instead of a raw exception
- [ ] #4 The error shape is configurable through the backend adapter; the Simple preset documents its format
- [ ] #5 Widget tests cover field errors, a general error and a 404; `docs/user_guide/rest-contract.md` documents the error format; changelog fragments added
<!-- AC:END -->
