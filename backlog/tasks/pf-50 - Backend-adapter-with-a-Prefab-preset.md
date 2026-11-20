---
id: PF-50
title: Backend adapter with a Prefab preset
status: To Do
assignee: []
created_date: '2026-11-20 10:00'
labels: []
milestone: m-2
dependencies: []
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Principle 7: a Prefab backend must work with zero configuration and other REST backends with configuration only. Today the list contract (`q`, `sort=-price`, `page`/`size`, `{ "items", "total" }`) is neither Prefab's nor configurable beyond `PrefabListAdapter` (see `docs/user_guide/rest-contract.md`), and ids, errors and filters have no adapter at all.

Grow `PrefabListAdapter` into a backend adapter (name to decide, e.g. `PrefabBackend`) that owns the list query parameters, the page response shape, the sort encoding, the id encoding in URLs and the parsing of error responses, and ship two presets:
- **Prefab** (the default): Spring `PagedModel` responses (`content`, `page.totalElements`, `page.number`), `sort=field,desc`, `page`/`size`, and `Reference<T>` string ids.
- **Simple**: today's contract, for existing users and plain backends.

Making Prefab the default changes behaviour for current users; the changelog entry says how to keep the old contract. Filters (PF-55) and Problem Details errors (PF-51) build on this adapter.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 A backend adapter class in `prefab_flutter_widgets` replaces `PrefabListAdapter` (kept as a deprecated alias or migrated with a changelog note) and is read by every generated API client through one provider
- [ ] #2 A Prefab preset is the default and matches Prefab's paging, sorting and id conventions, verified against recorded Prefab responses in tests
- [ ] #3 A Simple preset reproduces today's contract; the example app's mock backend uses one of the two presets explicitly
- [ ] #4 `docs/user_guide/rest-contract.md` describes both presets and how to write a custom adapter; README status updated
- [ ] #5 Changelog fragments describe the breaking default and the migration
<!-- AC:END -->
