---
id: PF-49
title: Promote command that writes one artifact to a file
status: To Do
assignee: []
created_date: '2026-11-20 10:00'
labels: []
milestone: m-1
dependencies:
  - PF-42
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Promoting an artifact (PF-42) means writing a class with the artifact's exact public signature. Because every artifact is emitted separately with its own imports (PF-38), the generator can write the starting point: `dart run prefab_flutter_generator:promote ProductDetailScreen` writes the generated code of that one artifact to a file with its imports, the import of the `.prefab.dart` library and `@Promoted()`, after which `build_runner` stops generating it. Suggested in decision-1, section "Promotion tool", and left out of PF-42.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 `dart run prefab_flutter_generator:promote <Name>` writes `lib/<entity folder or a --to path>/<snake_name>.dart` with the artifact's code, its imports, the `.prefab.dart` import and `@Promoted()`, and refuses to overwrite an existing file
- [ ] #2 An unknown name fails with the closest artifact name as a suggestion (shared with PF-42's check)
- [ ] #3 After running the command and `build_runner build`, the app compiles and behaves the same; covered by a test on a fixture package
- [ ] #4 The output is formatted (PF-41) and contains no generator-internal comments
- [ ] #5 `docs/user_guide/` promotion section documents the command; changelog fragment added
<!-- AC:END -->
