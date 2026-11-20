---
id: PF-47
title: Document and guard the public API of generated code
status: Done
assignee: []
created_date: '2026-11-20 10:00'
labels: []
milestone: m-1
dependencies:
  - PF-42
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Hand-written screens (both reference apps) build on generated providers, notifiers, API clients, screens and routes. They need a stable, documented API, and a change to it must be a deliberate, visible decision rather than a side effect of a template edit.

Write the user guide page "Using generated code" that lists, per artifact kind, the public names and signatures (`productsProvider` and its family key, `ProductsNotifier` methods such as `create`, `updateEntity`, `delete`, search/sort/page setters, `productProvider`, `ProductApiClient` methods, screen constructors, `$productRoutes`) with an example of a hand-written screen using them. PF-42 documents the signatures a *promoted* artifact must keep; link to it rather than repeating it.

Guard it with a test: extract the public declarations and their signatures from the snapshot outputs into a checked-in API summary (one file per fixture, or one file overall) and fail when it changes without the summary being regenerated, so pull requests show API changes explicitly.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 `docs/user_guide/` has a page on using generated code from hand-written code, listing every public generated name and signature per artifact kind, linked from the user guide index
- [x] #2 A test extracts the public API of the snapshot outputs into checked-in summary files and fails on any difference; `UPDATE_SNAPSHOTS=1` (or a similar switch) regenerates them
- [x] #3 `docs/developer_guide.md` explains that a change to the API summary is a breaking change that needs a changelog entry
- [x] #4 Names that are internal (private classes, helper functions) are either made private or listed as not part of the public API
<!-- AC:END -->
