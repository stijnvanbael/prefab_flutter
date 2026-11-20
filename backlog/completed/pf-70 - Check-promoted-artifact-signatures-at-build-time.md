---
id: PF-70
title: Check promoted artifact signatures at build time
status: Done
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
- [x] #1 A promoted screen with wrong constructor parameters fails the build with a message naming the expected parameters
- [x] #2 The same holds for promoted providers, API clients and routes
- [x] #3 Tests cover one mismatch per artifact kind
- [x] #4 docs/user_guide/promoting.md is updated and the Known limitations row is removed
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
The promoted builder now stores a syntactic shape of each `@Promoted` declaration in its summary; `LibraryEmitter.promotedMismatches` compares it with the signature derived from the entity manifest (`lib/src/promoted/signature_check.dart`). The check is lenient on purpose: only differences visible in the syntax fail the build (principle: no false alarms on valid hand-written code). Not checked: method return types and the notifier members of a list provider; they stay compile errors at the call site (documented in promoting.md). The example app has no promoted artifact with a wrong signature by design (it would not build); the check is covered by `test/promoted_signature_test.dart`, which also promotes the generated code of three fixtures unchanged.
<!-- SECTION:NOTES:END -->
