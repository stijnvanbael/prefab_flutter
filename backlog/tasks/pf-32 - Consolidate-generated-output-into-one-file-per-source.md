---
id: PF-32
title: Consolidate generated output into one file per source
status: To Do
assignee: []
created_date: '2026-11-18 10:00'
updated_date: '2026-11-18 10:00'
labels: []
dependencies: []
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Each annotated source file currently produces six generated files (.detail_screen, .list_screen, .form_screen, .provider, .api_client, .routes), which users must import separately. Investigate generating a single `.prefab.dart` file (or a part file) per source, and decide before documenting the generated file layout as stable or publishing 0.1.0.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 The decision (keep six files, one combined library, or a part file) is recorded with reasons in this task's notes
- [ ] #2 If consolidating: one builder produces one file and the generated imports are simplified
- [ ] #3 The README and user guide describe the generated file layout
<!-- AC:END -->
