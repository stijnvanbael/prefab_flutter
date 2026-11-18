---
id: PF-31
title: Replace the Validator enum with parameterised validators
status: To Do
assignee: []
created_date: '2026-11-18 10:00'
updated_date: '2026-11-18 10:00'
labels: []
dependencies: []
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Validator is an enum, so it cannot carry values such as min(0), max(100) or a regex pattern. Replace it with a sealed class with const constructors that the generator can read from the annotation constant.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Validator becomes a sealed class with const constructors: required, email, url, positive, nonNegative, min(num), max(num), minLength(int), maxLength(int), pattern(String regex, {String? message})
- [ ] #2 Every validator accepts an optional custom error message
- [ ] #3 The generator reads validator parameters from the annotation constant and emits the matching checks
- [ ] #4 Existing usages (Validator.required etc.) keep compiling, e.g. through static const instances
- [ ] #5 The user guide lists all validators
- [ ] #6 Generator tests cover each validator
- [ ] #7 Validator checks are generated per widget kind: on dropdown fields `required` checks `value == null` (today it emits `value.isEmpty` on an enum, which does not compile), and text-only validators are rejected at build time on non-text fields
<!-- AC:END -->
