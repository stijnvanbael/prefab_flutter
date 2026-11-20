---
id: PF-54
title: Named domain operations as actions and forms
status: To Do
assignee: []
created_date: '2026-11-20 10:00'
labels: []
milestone: m-2
dependencies:
  - PF-44
  - PF-53
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Prefab exposes domain operations beyond CRUD as named update endpoints (`@Update(path = ...)` in Java), e.g. `POST /invoices/{id}/send`, `/chargers/{id}/start`). Both reference apps need them (start/stop charging, submit an answer). Principle 1: declare the operation on the model and get the button.

Mirror Prefab: a named operation is declared on the model (e.g. `@Update(path: 'send', label: 'Send')` repeated, or a dedicated `@Operation` annotation, to decide) with optional parameters. An operation without parameters becomes an action (rendered like PF-44's actions, with an optional confirmation); one with parameters opens a generated form with those parameters. The API client gets one method per operation, and the detail and list providers refresh afterwards.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 An entity can declare named operations; each gets an API client method calling `{path}/{id}/{operation}` with the method and body the backend adapter defines (Prefab preset by default)
- [ ] #2 Operations without parameters appear as actions on the detail screen (and optionally list items), with an optional confirmation dialog
- [ ] #3 Operations with parameters open a generated form for the parameters, using the existing field widgets and validators
- [ ] #4 The entity is refreshed after the operation; errors use the Problem Details handling of PF-51
- [ ] #5 Feature module, tests, snapshot fixture and user guide section; changelog fragments added
<!-- AC:END -->
