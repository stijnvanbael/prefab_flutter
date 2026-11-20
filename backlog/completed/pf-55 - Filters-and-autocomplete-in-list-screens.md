---
id: PF-55
title: Filters and autocomplete in list screens
status: Done
assignee: []
created_date: '2026-11-20 10:00'
labels: []
milestone: m-2
dependencies:
  - PF-50
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Lists that scale need filters, not only free-text search. Prefab declares filterable fields with `@Filter`, sent as query parameters, and offers autocomplete endpoints for filter and reference values.

Let a field be marked filterable (`@Field(filter: ...)` or a separate annotation, to decide), choose the filter control from the type (enum: chips or dropdown; bool: toggle; date: range; text: autocomplete against the backend's autocomplete endpoint when the adapter supports one), keep the filter values in the list notifier next to search and sort, and send them through the `listQueryParameters` extension point and the backend adapter.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 A field can be declared filterable; the list screen shows a filter control per filterable field, chosen from its type
- [x] #2 Filter values live in the list notifier, reset the page to the first one and are sent as query parameters named by the backend adapter (Prefab preset by default)
- [x] #3 Text filters can offer autocomplete suggestions from the backend when the adapter defines the endpoint
- [x] #4 Implemented as a feature module using the list screen and notifier extension points; tests and snapshot fixture added
- [x] #5 `docs/user_guide/annotations.md` and `rest-contract.md` document filters; changelog fragments added
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
`@Field(filterable: true)` (principle 1: smallest annotation; control inferred from the type, principle 2). Feature module `features/filters/`; backend side in `PrefabBackend` (`encodeFilters`, `autocompletePath`), so Prefab-native defaults and other REST backends share one adapter (principle 7). Not done: filtering on reference fields with autocomplete of referenced entities, numeric range filters (numbers use the text filter), `@JsonValue` names for enum filter values, and a filter on fields of other places than the list's own entity. These need a new task if wanted.
<!-- SECTION:NOTES:END -->
