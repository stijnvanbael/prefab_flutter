---
id: PF-70
title: Check promoted artifact signatures at build time
status: To Do
assignee: []
created_date: '2026-11-20 12:00'
labels: []
dependencies:
  - PF-42
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
A promoted artifact (`@Promoted`, PF-42) must keep the signature the rest of the generated code calls (constructor parameters of a screen, provider type and family key, API client methods). A mismatch is not detected by the generator; it shows up as a compile error at the generated call site, in a file the developer did not write and should not edit. Left open after PF-42.

Check the promoted declaration against the signature documented per artifact kind in docs/user_guide/promoting.md and fail the build with a message that names the promoted declaration, the expected signature and the difference.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 A promoted screen with wrong constructor parameters fails the build with a message naming the expected parameters
- [ ] #2 The same holds for promoted providers, API clients and routes
- [ ] #3 Tests cover one mismatch per artifact kind
- [ ] #4 docs/user_guide/promoting.md is updated and the Known limitations row is removed
<!-- AC:END -->
