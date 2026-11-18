---
id: PF-30
title: Split @FormField into @Field and form configuration
status: To Do
assignee: []
created_date: '2026-11-18 10:00'
updated_date: '2026-11-18 10:00'
labels: []
dependencies: []
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
@FormField already controls what the list and detail screens show, and PF-13 (searchable, sortable) and PF-16 (views) would add more display concerns to it. Its name also clashes with Flutter's own FormField widget, so any file importing both material.dart and prefab_flutter needs a `hide`. Rename it to @Field for display and listing concerns, and keep form-only settings separate.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 @Field replaces @FormField and holds label, hidden, and the attributes added later by PF-13 and PF-16
- [ ] #2 Form-only settings (widget, validators) are kept in @Field's own form parameter (e.g. form: FormOptions(widget: ..., validators: [...])) or a separate annotation; the choice is recorded in this task's notes
- [ ] #3 @FormField remains as a deprecated alias for one release
- [ ] #4 All generators, tests, the README and the user guide are updated
<!-- AC:END -->
