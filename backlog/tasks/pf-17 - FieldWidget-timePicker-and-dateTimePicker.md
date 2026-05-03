---
id: PF-17
title: FieldWidget.timePicker and FieldWidget.dateTimePicker
status: To Do
assignee: []
created_date: '2026-05-03 10:30'
updated_date: '2026-05-03 10:30'
labels: []
dependencies: []
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The existing datePicker widget only picks a calendar day and stores an ISO-8601 date string, discarding time information. Add two new FieldWidget values: timePicker (uses showTimePicker, stores a TimeOfDay represented as HH:mm string) and dateTimePicker (opens a date picker then a time picker in sequence, stores a full DateTime ISO-8601 string). FormScreenGenerator must emit the correct widget code for each new value.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 FieldWidget enum gains timePicker and dateTimePicker values
- [ ] #2 FormScreenGenerator emits a read-only TextFormField with an onTap that calls showTimePicker for FieldWidget.timePicker
- [ ] #3 The timePicker field stores the selected time as a HH:mm string in the controller
- [ ] #4 FormScreenGenerator emits a read-only TextFormField with an onTap that chains showDatePicker then showTimePicker for FieldWidget.dateTimePicker
- [ ] #5 The dateTimePicker field stores the combined value as a full ISO-8601 DateTime string in the controller
- [ ] #6 _prefillControllers correctly populates timePicker and dateTimePicker fields from existing entity values
<!-- AC:END -->
