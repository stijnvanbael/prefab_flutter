---
id: PF-21
title: More annotation default values
status: To Do
assignee: []
created_date: '2026-05-03 10:30'
updated_date: '2026-05-03 10:30'
labels: []
dependencies: []
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Several annotation parameters require developers to repeat information that can already be derived from the code. For example, @View requires an explicit title even though the class name can be converted to title case, and @View requires a path even though a plural kebab-case version of the class name is an obvious default. Similarly, @FormField.label already has a fallback in EntityManifest but is not documented as optional on the annotation itself. Audit all annotations and add sensible defaults so that the minimal annotation for a simple entity is as concise as possible.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 @View.title defaults to the class name converted to title case (e.g. ProductOrder → 'Product Order') when omitted
- [ ] #2 @View.path defaults to a lowercased, hyphenated plural of the class name (e.g. ProductOrder → 'product-orders') when omitted
- [ ] #3 @FormField.label is already derived from the field name in EntityManifest; this derivation is documented in the annotation's dartdoc as the default behaviour
- [ ] #4 @FormField.widget defaults are documented: auto-inference rules (bool → toggle, DateTime → datePicker, int/double → numberInput after PF-18, enum → dropdown) are captured in the FieldWidget.auto dartdoc
- [ ] #5 A minimal annotated entity compiles and generates correct screens using only @View() with no parameters
- [ ] #6 Existing entities that already supply explicit values are unaffected
<!-- AC:END -->
