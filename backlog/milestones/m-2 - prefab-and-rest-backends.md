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
  parameters, `Reference<T>` string ids (PF-50)
- Server validation errors (Problem Details) shown on the form fields;
  404 and 409 handled in the UI (PF-51)
- Optimistic locking with `@Version`, including a "changed by someone else" flow (PF-52)
- Separate create and update request shapes (Prefab `@Create` constructor
  parameters differ from the entity fields) (PF-53)
- Named domain operations (`@Update(path = ...)`) as actions or forms (PF-54)
- Filters and autocomplete endpoints in list screens (PF-55)
- JSON field renames in the sort parameter (PF-34, done)
- Live updates over Prefab SSE streams (`@Streaming`) (PF-56)
- Status of long-running server jobs (PF-57)
- Spike: generate annotated Dart models from a Prefab OpenAPI document (PF-58)
