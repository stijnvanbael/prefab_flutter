---
id: PF-18
title: FieldWidget.numberInput with range validators
status: Done
assignee: []
created_date: '2026-05-03 10:30'
updated_date: '2026-11-18 10:00'
labels: []
dependencies:
  - PF-31
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Numeric fields (int, double) render a plain text field with no numeric keyboard. Add FieldWidget.numberInput, inferred automatically for int and double. Range checks depend on parameterised validators (PF-31), because the Validator enum cannot carry values like minValue(n).
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 FieldWidget gains numberInput, and FieldWidget.auto infers it for int and double
- [x] #2 int fields use TextInputType.numberWithOptions(signed: true) and an input formatter that allows an optional leading minus and digits
- [x] #3 double fields use TextInputType.numberWithOptions(signed: true, decimal: true) and an input formatter that allows an optional leading minus, digits and at most one decimal separator
- [x] #4 A type check rejects values that do not parse as the field's type
- [x] #5 Range validators are available through PF-31: nonNegative, min(n) and max(n)
- [x] #6 _prefillControllers populates numberInput fields with .toString()
<!-- AC:END -->

## Implementation Notes

Range validators (nonNegative, min, max) came with PF-31. `num` fields are treated like `double`. The formatter allows only `.` as decimal separator because `double.parse` rejects `,`. Prefill already used `.toString()` for non-String fields.
