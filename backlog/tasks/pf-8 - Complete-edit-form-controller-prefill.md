---
id: PF-8
title: Complete edit form controller prefill
status: To Do
assignee: []
created_date: '2026-05-02 06:05'
labels: []
dependencies: []
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The FormScreenGenerator emits a _prefillControllers method with a comment placeholder instead of real field assignments. It must generate actual controller.text = item.field assignments for each @FormField-annotated field.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 _prefillControllers generates a text assignment for each String and numeric form field
- [ ] #2 bool fields prefill a Switch state variable instead of a text controller
- [ ] #3 DateTime fields prefill a date state variable
- [ ] #4 Generated edit form compiles and shows existing values when opened
<!-- AC:END -->
