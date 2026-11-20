---
id: PF-57
title: Status of long-running server jobs
status: To Do
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
- [ ] #1 A model can declare its job status field; list tiles and the detail screen show running, done and failed states
- [ ] #2 While a job is running its detail and list providers refresh (polling with a configurable interval, or live updates when available) and stop when it is final
- [ ] #3 Failures show the server's message; tests cover the state transitions with a fake backend
- [ ] #4 User guide section added; changelog fragments added
<!-- AC:END -->
