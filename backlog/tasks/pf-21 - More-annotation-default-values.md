---
id: PF-21
title: More annotation default values
status: To Do
assignee: []
created_date: '2026-05-03 10:30'
updated_date: '2026-11-18 10:00'
labels: []
milestone: m-3
dependencies: []
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Several annotation parameters repeat information that can be derived from the code. @View requires a title even though the class name can be converted to title case, and a path even though a plural kebab-case version of the class name is an obvious default. Audit all annotations and add defaults so the minimal annotation for a simple entity is as short as possible.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 @View.title defaults to the class name in title case (ProductOrder -> 'Product Order')
- [ ] #2 @View.path defaults to the kebab-case plural of the class name (ProductOrder -> 'product-orders', Category -> 'categories'), using a small documented pluralisation rule
- [ ] #3 The label default (field name in title case) is documented in the field annotation's dartdoc
- [ ] #4 The FieldWidget.auto inference rules are documented in its dartdoc and in the user guide
- [ ] #5 A minimal entity with only @View() and no parameters generates correct, compiling screens
- [ ] #6 Entities that already supply explicit values are unaffected
<!-- AC:END -->
