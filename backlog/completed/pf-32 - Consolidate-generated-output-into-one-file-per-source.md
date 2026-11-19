---
id: PF-32
title: Consolidate generated output into one file per source
status: Done
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
- [x] #1 The decision (keep six files, one combined library, or a part file) is recorded with reasons in this task's notes
- [x] #2 If consolidating: one builder produces one file and the generated imports are simplified
- [x] #3 The README and user guide describe the generated file layout
<!-- AC:END -->

## Implementation Notes

Decision: one combined library, `<source>.prefab.dart`, produced by a single `prefabBuilder`.

- Six files forced users to import each file separately and made the generated files import each other; a single library removes that coupling and the import bookkeeping.
- A part file was rejected: it requires a `part` directive in the user's source and every import to live in the source file, so the generator could not manage its own imports.
- `PrefabGenerator` runs the existing generators, drops their imports of each other's output, merges and de-duplicates the remaining imports, and concatenates the bodies. The per-generator builder factories remain in `builder.dart` for unit tests but only `prefabBuilder` is registered in `build.yaml`.
- Breaking change; documented in the CHANGELOG, README and user guide.
