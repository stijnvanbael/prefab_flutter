---
id: PF-18
title: FieldWidget.numberInput with range validators
status: To Do
assignee: []
created_date: '2026-05-03 10:30'
updated_date: '2026-05-03 10:30'
labels: []
dependencies: []
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Numeric fields (int, double) currently render a plain TextFormField with TextInputType.text and no numeric keyboard or formatting. Add FieldWidget.numberInput (auto-inferred for int and double when FieldWidget.auto is used) that sets keyboardType: TextInputType.number and attaches a FilteringTextInputFormatter. Extend the Validator enum with nonNegativeNumber, minValue, and maxValue to cover common range constraints.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 FieldWidget enum gains a numberInput value
- [ ] #2 FieldWidget.auto infers numberInput for int and double Dart types
- [ ] #3 The generated numberInput field sets keyboardType: TextInputType.numberWithOptions and a FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
- [ ] #4 Validator enum gains nonNegativeNumber (value >= 0), minValue(n) (value >= n), and maxValue(n) (value <= n) entries
- [ ] #5 FormScreenGenerator emits the correct inline validator checks for the new Validator values
- [ ] #6 _prefillControllers correctly populates numberInput fields from int/double entity values using .toString()
<!-- AC:END -->
