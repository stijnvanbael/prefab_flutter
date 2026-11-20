---
id: PF-74
title: Catch up after an SSE stream reconnects
status: To Do
assignee: []
created_date: '2026-11-20 12:00'
labels: []
milestone: m-2
dependencies:
  - PF-56
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
`PrefabEventSource` reconnects with backoff, but events that happened while the connection was down are lost. Reload the list notifiers and detail providers of a `@Streaming` entity after a reconnect (a `reconnected` signal from the source), and optionally send `Last-Event-ID` when the backend supports it.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 After a reconnect the list and detail providers of a streaming entity reload
- [ ] #2 Tests use a fake source that drops and reconnects
- [ ] #3 The limitation row in the user guide is removed
<!-- AC:END -->
