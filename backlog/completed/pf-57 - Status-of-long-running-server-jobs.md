---
id: PF-57
title: Status of long-running server jobs
status: Done
assignee: []
created_date: '2026-11-20 10:00'
labels: []
milestone: m-2
dependencies:
  - PF-54
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The self-study backend generates summaries and quizzes in jobs that take minutes; the UI must show that a job is running and when it is done or failed, and survive a page reload. Prefab models such jobs as resources with a status.

Define how a model declares a job-like status (e.g. a status field of an enum with running, done and failed values, inferred where possible), show it in the list and detail screens (progress indicator, failure message), and refresh the entity until it is final, by polling or through live updates (PF-56) when the entity streams. An operation (PF-54) that starts a job navigates to or highlights the job.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 A model can declare its job status field; list tiles and the detail screen show running, done and failed states
- [x] #2 While a job is running its detail and list providers refresh (polling with a configurable interval, or live updates when available) and stop when it is final
- [x] #3 Failures show the server's message; tests cover the state transitions with a fake backend
- [x] #4 User guide section added; changelog fragments added
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
- Declaration: `@JobStatus()` on an enum field (a marker like `@Id`/`@Version`, new vocabulary term **Job**; Prefab has no such annotation). The values are classified by name (`queued`, `running`, `done`, `failed`, ...), explicitly with `running:`, `done:`, `failed:`; the message field is found by name or named with `message:`; `pollInterval` configures the polling. The status field is implicitly `readOnly`. Read in `features/job_status/`; the manifest only gained the `readOnly` inference.
- Screens: new extension points `detailScreen.beforeFields` (banner) and `listScreen.itemStatus` (indicator in front of the trailing slot). Runtime in `prefab_flutter_widgets`: `PrefabJobState`, `PrefabJobIndicator`, `PrefabJobBanner`, `PrefabJobPoller`, `prefabPolledDetail`.
- Refreshing: the list notifier polls through `PrefabJobPoller` (`listenSelf`), the detail provider becomes a `StreamProvider` (breaking for code that depends on its type, noted in the changelog). A `@Streaming` entity does not poll: the live events refresh it. A poll that fails is ignored and retried; a poll can overwrite a concurrent reload of the same list (rare, not handled).
- Operations: `@Update(startsJob: true)`; from a list item the detail screen opens after the operation (or its form) succeeded, on the detail screen the banner switches to running.
- Not done: custom job states beyond running, done and failed (a `cancelled` value must be mapped to done or failed), and a backoff of the polling interval.
- The example app has `Report` (`lib/report.dart`) with a mock backend whose jobs advance with each read; tests in `test/job_status_test.dart`.
<!-- SECTION:NOTES:END -->
