---
id: PF-41
title: Format generated output with dart_style
status: To Do
assignee: []
created_date: '2026-11-19 14:00'
labels: []
milestone: m-0
dependencies:
  - PF-38
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Decision-1 (generator architecture) keeps templates and decides to format the assembled `.prefab.dart` with `dart_style`, as a separate step after PF-38 so that structural moves and formatting changes are never mixed in one snapshot diff.

Today the generated code's indentation is whatever the templates write (some list screen lines are mis-indented), and every fragment must be internally indented by hand. Formatting the output makes generated code read like hand-written code (principle 4) and makes template indentation cosmetic for every later feature module.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 `prefab_flutter_generator` depends directly on `dart_style`, and the library assembled by the core is formatted with `DartFormatter` using a pinned language version, so the output does not change with the user's SDK
- [ ] #2 A source that fails to format (a template bug) fails the build with an error that names the source file and includes the unformatted output
- [ ] #3 The snapshot expected files are regenerated in one commit that contains no other change, and the pull request says that only formatting changed
- [ ] #4 Generator tests that match on whitespace-sensitive fragments are updated
- [ ] #5 `docs/developer_guide.md` "Generator internals" says that fragments need not be indented exactly; changelog fragment added
<!-- AC:END -->
