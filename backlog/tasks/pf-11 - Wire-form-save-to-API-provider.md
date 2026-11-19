---
id: PF-11
title: Wire form save to API provider
status: To Do
assignee: []
created_date: '2026-05-03 10:30'
updated_date: '2026-11-18 10:00'
labels: []
dependencies:
  - PF-12
  - PF-15
  - PF-23
  - PF-25
  - PF-28
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The generated Create and Edit form screens validate the form and call context.pop() on success, but never build an entity or call the provider's create()/update(). The FormScreenGenerator must emit code that constructs an entity from the form state and dispatches the right mutation through the Riverpod provider before navigating away.

The hard part is entity construction. The generator calls the entity's unnamed constructor, mapping each constructor parameter to a source:
- form fields: the typed form state (parsed from text for numeric fields);
- the id: omitted/null on create (requires the id to be nullable or have a default), copied from the loaded item on edit (see PF-23);
- the @Parent field: the parent id passed to the screen (see PF-25);
- hidden or un-annotated fields: copied from the loaded item on edit; on create they must be optional or have a default, otherwise the generator emits a build-time error naming the field.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 The generator maps every constructor parameter of the entity to a source as described above, and emits a clear build-time error when a required parameter has no source
- [ ] #2 The Create screen builds the entity and calls the provider's create() before popping
- [ ] #3 The Edit screen builds the entity, preserving id, parent and non-form fields from the loaded item, and calls the provider's update() before popping
- [ ] #4 Numeric text fields are parsed to int/double before construction
- [ ] #5 A loading indicator is shown and the save button is disabled while the request is in flight
- [ ] #6 Errors from create/update are shown in a SnackBar and the screen stays open
- [ ] #7 An empty input for a nullable field is passed as `null` to the entity constructor, and non-nullable fields are parsed or required (moved from PF-15 AC#4; the nullability metadata is `FieldManifest.isNullable`)
- [ ] #8 The round-trip works end-to-end in the example app (PF-9)
<!-- AC:END -->
