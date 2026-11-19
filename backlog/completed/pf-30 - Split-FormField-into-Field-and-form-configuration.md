---
id: PF-30
title: Split @FormField into @Field and form configuration
status: Done
assignee: []
created_date: '2026-11-18 10:00'
updated_date: '2026-11-19 10:00'
labels: []
dependencies: []
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
@FormField already controls what the list and detail screens show, and PF-13 (searchable, sortable) and PF-16 (views) would add more display concerns to it. Its name also clashes with Flutter's own FormField widget, so any file importing both material.dart and prefab_flutter needs a `hide`. Rename it to @Field for display and listing concerns, and keep form-only settings separate.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 @Field replaces @FormField and holds label, hidden, and the attributes added later by PF-13 and PF-16
- [x] #2 Form-only settings (widget, validators) are kept in @Field's own form parameter (e.g. form: FormOptions(widget: ..., validators: [...])) or a separate annotation; the choice is recorded in this task's notes
- [x] #3 @FormField remains as a deprecated alias for one release
- [x] #4 All generators, tests, the README and the user guide are updated
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
- Decision (AC#2): form-only settings live in `@Field`'s own `form` parameter (`FormOptions(widget:, validators:)`) rather than a separate annotation, so one annotation marks a field and PF-13/PF-16 can add display attributes directly on `@Field`.
- `@FormField` stays as a `@Deprecated` class with its old parameters; the generator reads either annotation (`@Field` wins).
- Generators, tests (incl. a legacy-alias test), README files, CHANGELOG and user guide updated; the known-limitation row was removed.
<!-- SECTION:NOTES:END -->
