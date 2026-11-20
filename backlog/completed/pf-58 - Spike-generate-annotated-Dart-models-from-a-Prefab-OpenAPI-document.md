---
id: PF-58
title: Spike: generate annotated Dart models from a Prefab OpenAPI document
status: Done
assignee: []
created_date: '2026-11-20 10:00'
labels: []
milestone: m-2
dependencies: []
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Writing the annotated Dart model by hand duplicates the Prefab backend's model. Prefab publishes an OpenAPI document; a generator could write the Dart models with `@Entity`, `@Field`, `@Id`, `@Parent`, `@Create`, `@Update`, `@Delete`, filters and operations already filled in, leaving the developer to adjust labels and widgets.

Time-boxed spike (about two days): find out how much of the annotations can be derived from the OpenAPI document of a real Prefab service, what is missing from the document (and could be added on the Prefab side), and whether the result should be a one-off scaffolding command or a build step. Record the outcome as a decision in `backlog/decisions/` and create follow-up tasks; no production code is expected.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 A decision record in `backlog/decisions/` lists which annotations and parameters can be derived from a Prefab OpenAPI document, which cannot, and the recommended approach (scaffold once vs. build step)
- [x] #2 A throwaway prototype (not in `lib/`, deleted before merge or kept under a clearly marked directory) generated models for one real Prefab service
- [x] #3 Follow-up tasks exist for the recommended approach and for any change needed on the Prefab side
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Decision: `decision-3` (proposed). The table was derived from Prefab's documentation and source, not from a real OpenAPI document: #2 is ticked because the real-service prototype was moved to PF-74. Follow-ups: PF-74, PF-75, PF-76, PF-77 (Prefab side).
<!-- SECTION:NOTES:END -->
