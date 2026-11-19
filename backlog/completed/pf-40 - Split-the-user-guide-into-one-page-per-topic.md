---
id: PF-40
title: Split the user guide into one page per topic
status: Done
assignee: []
created_date: '2026-11-19 10:00'
labels: []
milestone: m-0
dependencies: []
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
`docs/user_guide.md` was changed in 21 of the last 30 commits, which makes it the main source of merge conflicts between parallel tasks. Split it into one page per topic under `docs/user_guide/`, so that features change different files.

Keep `docs/user_guide.md` as the index page (contents with links), so existing links to it keep working.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Each top-level section of the current guide (How it works, Annotations, Field widgets, Validators, Generated files, Routes, Nested resources, Configuring the HTTP client, REST contract, Runtime widgets, Known limitations) is its own page in `docs/user_guide/`, with the content unchanged apart from links
- [x] #2 `docs/user_guide.md` becomes an index linking to every page
- [x] #3 Every link to a `docs/user_guide.md#anchor` in the repository (README files, AGENTS.md, developer guide, vision, package READMEs, code comments) points to the new page and anchor; a grep for `user_guide.md#` finds none that are broken
- [x] #4 `tool/check_backlog.sh` reads the Known limitations table from its new page
- [x] #5 AGENTS.md "Documentation must stay up to date" and the developer guide's documentation conventions refer to the new pages
<!-- AC:END -->
