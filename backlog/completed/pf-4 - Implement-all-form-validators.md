---
id: PF-4
title: Implement all form validators
status: Done
assignee: []
created_date: '2026-05-02 06:04'
labels: []
dependencies: []
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
FormScreenGenerator only generates an empty-check validator for every field. The Validator enum defines required, email, positiveNumber and url but these are ignored during generation. Each validator must produce the correct inline validation logic.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Validator.required generates a non-empty check
- [x] #2 Validator.email generates a regex email check
- [x] #3 Validator.positiveNumber generates a > 0 numeric check
- [x] #4 Validator.url generates a Uri.tryParse validity check
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Implemented in FormScreenGenerator._writeValidatorCheck. Parameterised validators (min/max, pattern, custom) are tracked in PF-31.
<!-- SECTION:NOTES:END -->
