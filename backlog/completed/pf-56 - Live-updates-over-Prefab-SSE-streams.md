---
id: PF-56
title: Live updates over Prefab SSE streams
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
The energy balancing app shows what is happening now (device states, measurements). Prefab offers server-sent event streams for entities annotated `@Streaming`. Generated list and detail providers should update live when the entity is streaming, without the developer writing a subscription.

Add an opt-in on the model (e.g. `@Entity(live: true)` or a `@Streaming` annotation mirroring Prefab, to decide), an SSE client on top of the configured Dio in `prefab_flutter_widgets` (reconnect with backoff, closed when no provider listens), and providers that apply created, updated and deleted events to their state. The event format belongs to the backend adapter.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 An entity can opt in to live updates; its list and detail providers apply created, updated and deleted events from the stream
- [x] #2 The SSE client reconnects with backoff, stops when no widget listens, and uses the configured Dio (authentication interceptors apply)
- [x] #3 Paged and filtered lists handle events for items outside the current page in a documented way (e.g. a "new items" indicator instead of inserting)
- [x] #4 Tests use a fake stream; the example app's mock backend emits events for one entity
- [x] #5 User guide documents the opt-in and the event format; changelog fragments added
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
- Opt-in is `@Streaming()` (mirrors Prefab, vocabulary rule 1), a marker like `@Delete`; read inside `features/streaming/` with a `TypeChecker`, not in the manifest. The manifest only gained `idJsonName`.
- Runtime (`prefab_flutter_widgets`): `PrefabEventSource` (SSE over the configured Dio, backoff 1 s to 30 s, closed on cancel), `prefabEventsProvider` (one shared connection per URL), `applyPrefabEvent`, `prefabLiveDetail`, `PrefabNewItemsBanner`. The event format is in `PrefabBackend` (`streamPath`, event names, `parseEvent`).
- AC#3: created items outside the page (or while a search/sort is active) raise `PrefabPage.newItems`; the list screen shows a banner. Updated/deleted events for items off the page are ignored.
- The detail provider of a streaming entity becomes a `StreamProvider` (same `AsyncValue` API). A `deleted` event fails it with `PrefabEntityDeleted`.
- Tests that use a failing Dio against a streaming entity must unmount the app: the reconnect timer is pending otherwise (`prefab_theme_test.dart`).
- Not done: catching up after a reconnect, moved to PF-74.
<!-- SECTION:NOTES:END -->
