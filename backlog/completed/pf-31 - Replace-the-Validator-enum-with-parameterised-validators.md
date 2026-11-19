---
id: PF-31
title: Replace the Validator enum with parameterised validators
status: Done
assignee: []
created_date: '2026-11-18 10:00'
updated_date: '2026-11-19 10:00'
labels: []
dependencies: []
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Validator is an enum, so it cannot carry values such as min(0), max(100) or a regex pattern. Replace it with a sealed class with const constructors that the generator can read from the annotation constant.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Validator becomes a sealed class with const constructors: required, email, url, positive, nonNegative, min(num), max(num), minLength(int), maxLength(int), pattern(String regex, {String? message})
- [x] #2 Every validator accepts an optional custom error message
- [x] #3 The generator reads validator parameters from the annotation constant and emits the matching checks
- [x] #4 Existing usages (Validator.required etc.) keep compiling, e.g. through static const instances
- [x] #5 The user guide lists all validators
- [x] #6 Generator tests cover each validator
- [x] #7 Validator checks are generated per widget kind: on dropdown fields `required` checks `value == null` (today it emits `value.isEmpty` on an enum, which does not compile), and text-only validators are rejected at build time on non-text fields
<!-- AC:END -->

## Implementation Notes

- `Validator` is a sealed class (`prefab_flutter/lib/src/enums/validator.dart`); subclasses such as `MinValidator` carry the values and message. `positiveNumber` is kept as an alias of `positive`.
- Generator reads parameters in `entity_manifest.dart` and emits checks in `form_screen_generator.dart`; text-only validators on dropdown/toggle/date picker fields throw at build time.
- Tests: `prefab_flutter_generator/test/validators_test.dart`.
