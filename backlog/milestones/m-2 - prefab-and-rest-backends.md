---
id: m-2
title: "M2 - Prefab and REST backends"
---

## Description

A Prefab backend works with zero configuration; other REST backends with
configuration only.

Scope:
- A backend adapter (paging, sorting, search, filters, errors, ids) with a
  Prefab preset: Spring `PagedModel` responses (`content`,
  `page.totalElements`), `sort=field,desc`, `page`/`size`, `@Filter` query
  parameters, `Reference<T>` string ids
- Server validation errors (Problem Details) shown on the form fields;
  404 and 409 handled in the UI
- Optimistic locking with `@Version`, including a "changed by someone else" flow
- Separate create and update request shapes (Prefab `@Create` constructor
  parameters differ from the entity fields)
- Named domain operations (`@Update(path = ...)`) as actions or forms
- Filters and autocomplete endpoints in list screens
- JSON field renames in the sort parameter (PF-34)
- Live updates over Prefab SSE streams (`@Streaming`)
- Status of long-running server jobs
- Spike: generate annotated Dart models from a Prefab OpenAPI document
