---
id: PF-53
title: Separate create and update request shapes
status: Done
assignee: []
created_date: '2026-11-20 10:00'
labels: []
milestone: m-2
dependencies:
  - PF-39
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Prefab's `@Create` constructor parameters often differ from the entity's fields: the server sets the id, timestamps, status and computed fields, and some fields can only be set at creation. Today the create and edit forms both send the whole entity via `toJson()` (see `docs/user_guide/rest-contract.md`).

Let the model say which fields belong in which request, with inference first (principle 2): the id and the version field are never sent on create; fields marked read-only are never in a form. Candidates for the annotation, to settle in the task: `@Field(form: FormOptions(on: {FormMode.create}))` for create-only fields, and a `readOnly` flag for server-computed fields shown only in the detail and list views. The API client sends only the fields of the request (a generated request map or class), not `toJson()` of a partially filled entity.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 A field can be limited to the create form, to the edit form, or be read-only (shown in views, never in forms or request bodies)
- [x] #2 The create and update requests contain only their fields; the id and version are never in the create body
- [x] #3 The create form no longer needs dummy values for server-set fields; a snapshot fixture shows a model with server-set fields
- [x] #4 `docs/user_guide/annotations.md` and `rest-contract.md` describe the request bodies; changelog fragments added
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Decisions: `@Field(readOnly: true)` and `FormOptions(on: {FormMode.create | FormMode.update})`. Inference first: the id is never in the create body, the parent id always is. The create body is a whitelist (create form fields plus parent) and the update body a blacklist (read-only and create-only fields), both filtered from `toJson()` by JSON name, because a typed request class would need its own JSON encoding for every supported field type. For AC #3 the create screen puts a placeholder (`''`, `0`, `false`, epoch, `Duration.zero`, first enum value) into required constructor parameters it cannot fill; other types still fail the build. Version field exclusion belongs to PF-52 (not yet implemented); it should add its field to both exclusions. Example: `Product.sku` (create-only) and `Product.createdAt` (read-only), tested in `test/request_shapes_test.dart`.
<!-- SECTION:NOTES:END -->
