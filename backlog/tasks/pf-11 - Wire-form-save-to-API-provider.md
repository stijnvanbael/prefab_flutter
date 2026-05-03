---
id: PF-11
title: Wire form save to API provider
status: To Do
assignee: []
created_date: '2026-05-03 10:30'
updated_date: '2026-05-03 10:30'
labels: []
dependencies: []
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The generated Create and Edit form screens validate the form and call context.pop() on success, but never collect field values or call the provider's create()/update() methods. The FormScreenGenerator must emit code that builds an entity object from the form field controllers/values and dispatches the correct mutation through the Riverpod provider before navigating away.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 The Create screen collects all field values and calls provider.create(entity) before popping
- [ ] #2 The Edit screen collects all field values and calls provider.update(entity) before popping
- [ ] #3 A loading indicator is shown while the async operation is in flight
- [ ] #4 Errors from create/update are surfaced to the user (e.g. SnackBar or inline message)
- [ ] #5 The generated code compiles and the round-trip works end-to-end in the example app
<!-- AC:END -->
