---
id: PF-5
title: Implement specialized form widgets
status: To Do
assignee: []
created_date: '2026-05-02 06:04'
updated_date: '2026-05-02 06:04'
labels: []
dependencies: []
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
FormScreenGenerator always generates TextFormField regardless of FieldWidget hint or Dart type. The FieldWidget enum defines multilineText, password, datePicker, dropdown and toggle. The generator must select the correct widget based on the annotation or infer it from the Dart type when FieldWidget.auto is used.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 bool fields render a Switch widget by default
- [ ] #2 DateTime fields render a date picker by default
- [ ] #3 FieldWidget.multilineText renders a multi-line TextFormField
- [ ] #4 FieldWidget.password renders an obscured TextFormField
- [ ] #5 enum fields render a DropdownButtonFormField
- [ ] #6 FieldWidget.toggle renders a Switch regardless of type
<!-- AC:END -->
