---
id: PF-39
title: Feature module contract and first migrated feature
status: To Do
assignee: []
created_date: '2026-11-19 10:00'
labels: []
milestone: m-0
dependencies:
  - PF-38
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Define what a feature module is and migrate one feature end to end as the pattern for the rest. A feature module is a directory under `prefab_flutter_generator/lib/src/features/<feature>/` that reads its annotation data from the manifest and contributes to artifacts through the extension points from PF-38, with its own test file and its own documentation page. The contract (the `Feature` interface, `ArtifactSet` lookups that return `null` for promoted or absent artifacts, ordered contributions, the alphabetical feature registry, what a module may touch) is sketched in `backlog/decisions/decision-1 - Generator-architecture.md`, section "Feature modules".

Migrate search, sort and pagination (PF-13) first: it touches the list screen (`appBarActions`, `aboveList`, `belowList`), the list notifier (`state`, `methods`, `fetchArguments`) and the API client (`listQueryParameters`), so it exercises several extension points, including typed ones that several features combine. Then create one follow-up task per remaining feature group, so that agents can migrate them in parallel.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 The feature module contract (directory layout, registration, what a module may and may not touch) is documented in `docs/developer_guide.md` under a new "Adding a feature" section, replacing "Adding a generator"
- [ ] #2 Search, sort and pagination live in `lib/src/features/list_query/` (or a similar name) and no longer have code in the per-artifact generators
- [ ] #3 The snapshot tests pass without changes to the expected files
- [ ] #4 AGENTS.md tells agents to put new features in a feature module, following the developer guide
- [ ] #5 Follow-up tasks (milestone m-0) exist for migrating the remaining feature groups, e.g. field widgets (one `FieldEmitter` each), validators (one `ValidatorEmitter` each), nullable fields, nested resources and breadcrumbs, create/update/delete, views; each lists the files it is expected to touch
- [ ] #6 Feature-specific annotation reading that only this feature uses moves out of `entity_manifest.dart` into the module, or the developer guide explains why it stays
<!-- AC:END -->
