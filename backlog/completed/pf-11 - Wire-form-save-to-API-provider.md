---
id: PF-11
title: Wire form save to API provider
status: Done
assignee: []
created_date: '2026-05-03 10:30'
updated_date: '2026-11-19 10:00'
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
- [x] #1 The generator maps every constructor parameter of the entity to a source as described above, and emits a clear build-time error when a required parameter has no source
- [x] #2 The Create screen builds the entity and calls the provider's create() before popping
- [x] #3 The Edit screen builds the entity, preserving id, parent and non-form fields from the loaded item, and calls the provider's update() before popping
- [x] #4 Numeric text fields are parsed to int/double before construction
- [x] #5 A loading indicator is shown and the save button is disabled while the request is in flight
- [x] #6 Errors from create/update are shown in a SnackBar and the screen stays open
- [x] #7 An empty input for a nullable field is passed as `null` to the entity constructor, and non-nullable fields are parsed or required (moved from PF-15 AC#4; the nullability metadata is `FieldManifest.isNullable`)
- [x] #8 The round-trip works end-to-end in the example app (PF-9) — moved to PF-9 AC#8
<!-- AC:END -->

## Implementation Notes

- `EntityManifest.constructorParams` records the unnamed constructor's parameters. `FormScreenGenerator` emits a `_save()` method per screen that builds the entity, calls `{entity}sProvider(.notifier).create/update` (parent-family aware) and pops on success.
- Value sources: id → `widget.id` (edit) / omitted (create); `@Parent` → `widget.<parent>`; form field → typed state (`int/double/num.parse`, empty nullable → `null`); hidden/un-annotated → `_item!.<field>` (edit) / omitted (create). A required, non-nullable parameter with no source, or a form field of an unsupported type, fails the build with an `InvalidGenerationSourceError` naming it.
- The id must therefore be nullable or defaulted (`final int? id; Entity({this.id, ...})`); README, guides and test fixtures were updated.
- Numeric text fields get a parseability validator so `parse` cannot throw. The provider is kept alive with `ref.listenManual` while the request runs. Save shows a progress indicator and disables the button; errors go to a SnackBar.
- AC#8 (end-to-end in the example app) cannot be verified yet because the example app does not exist; moved to PF-9 AC#8. Verified by generator tests (`form_save_test.dart`) only; the generated code was not compiled in a Flutter app.
