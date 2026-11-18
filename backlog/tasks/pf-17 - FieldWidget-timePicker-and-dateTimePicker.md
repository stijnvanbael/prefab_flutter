---
id: PF-17
title: FieldWidget.timePicker and FieldWidget.dateTimePicker
status: To Do
assignee: []
created_date: '2026-05-03 10:30'
updated_date: '2026-11-18 10:00'
labels: []
dependencies: []
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The existing datePicker only picks a calendar day. Add timePicker and dateTimePicker. As with the existing datePicker, the selected value is kept in a typed state variable and the text controller only holds the formatted display string, so entity construction (PF-11) never parses display text.

Supported field types:
- dateTimePicker: DateTime;
- timePicker: Duration (time since midnight) and String in HH:mm format. TimeOfDay is not supported because it is a Flutter type and entity classes should stay pure Dart.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 FieldWidget gains timePicker and dateTimePicker
- [ ] #2 timePicker emits a read-only TextFormField whose onTap calls showTimePicker and stores the result in a typed state variable
- [ ] #3 dateTimePicker chains showDatePicker and showTimePicker and stores a DateTime in a typed state variable
- [ ] #4 Display text uses the locale's date/time format (MaterialLocalizations), not raw ISO-8601; the existing datePicker is switched to the same formatting
- [ ] #5 A build-time error is emitted when either widget is used on an unsupported field type
- [ ] #6 _prefillControllers populates both from existing entity values
<!-- AC:END -->
