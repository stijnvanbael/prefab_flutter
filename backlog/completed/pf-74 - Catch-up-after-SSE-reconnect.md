---
id: PF-74
title: Catch up after an SSE stream reconnects
status: Done
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
- [x] #1 After a reconnect the list and detail providers of a streaming entity reload
- [x] #2 Tests use a fake source that drops and reconnects
- [x] #3 The limitation row in the user guide is removed
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
- `PrefabEventSource` marks a gap whenever a connection fails or ends and emits `PrefabEvent.reconnected()` (new `PrefabEventType.reconnected`) as the first event of the next successful connection, so existing fakes (`prefabEventsProvider.overrideWith`) can simulate a drop by adding that event. This keeps the generated providers on the one `Stream<PrefabEvent>` they already listen to.
- The list notifier reloads with `_load()` (reset of `newItems`, short loading state with the previous page kept); `prefabLiveDetail` loads again and buffers events that arrive meanwhile. A failing detail reload is surfaced as an error (for example the entity was deleted while offline).
- `Last-Event-ID` is sent whenever the source has seen an `id:` line. `PrefabBackend.resumeWithLastEventId` (default `false`) tells the source that the server replays missed events, which skips the reload signal for a reconnect with a known id. Not verified against a real Prefab backend; PF-78 covers checking against a real service.
- Adding an enum value is a source change for code that switches exhaustively over `PrefabEventType`; noted in the changelog fragment.
- Example app: the mock backend gained `dropProductStreams()` and `changeProductSilently()`; `test/streaming_test.dart` covers list and detail catch-up.
- This task id was used twice on `main`; the OpenAPI verification task was renumbered to PF-78.
<!-- SECTION:NOTES:END -->
