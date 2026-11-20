---
id: PF-37
title: Decide the generator architecture (ADR)
status: Done
assignee: []
created_date: '2026-11-19 10:00'
labels: []
milestone: m-0
dependencies: []
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The generators build Dart code by concatenating strings. `PrefabGenerator` merges the outputs of six generators by matching import lines with regular expressions, and `form_screen_generator.dart` is about 950 lines. A feature such as nullable fields has to edit all six generators, so parallel tasks conflict and each feature costs more than it should.

Decide how the generator is structured before the roadmap adds many more features. The decision must support the principles in `docs/vision.md`, in particular:
- **Per-artifact emission and promotion (principle 3):** every artifact (each screen, provider, notifier, API client, routes list) is emitted separately, so that a promoted artifact can be skipped and the rest wired to the promoted version (M1).
- **Feature modules (principle 8):** a feature (search, nullable fields, a field widget, a validator) lives in its own directory and contributes to several artifacts through defined extension points, instead of editing each generator.
- **Readable generated code (principle 4).**

Options to compare at least: `package:code_builder` with `dart_style`; structured string templates per artifact with an import collector; a hybrid (`code_builder` for declarations and imports, templates for widget trees).

This is a decision task, not an implementation: PF-38 implements it.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 A decision record `backlog/decisions/decision-1 - Generator-architecture.md` (front matter: `id: decision-1`, `title`, `date`, `status: accepted`) compares the options against: per-artifact emission, feature modules and their extension points, import handling, readability of the generator code for agents, readability of the generated code, and migration cost
- [x] #2 The record defines the core concepts with short Dart sketches: the artifact model, the extension points a feature module can contribute to (e.g. list app bar actions, form field emitters per `FieldWidget`, provider methods, API client methods), and how imports are collected
- [x] #3 The record describes how a promoted artifact is detected and skipped (e.g. a class with the artifact's name in the package, or an annotation on it) and how generated code then refers to it, at the level of detail PF-38 and the M1 promotion task need
- [x] #4 The record describes how features are migrated incrementally while the snapshot tests (PF-36) keep the output stable
- [x] #5 A small prototype (one artifact, e.g. the detail screen) supports the choice; it is described in the record and not merged into `lib/`
- [x] #6 PF-38 and PF-39 are updated if the decision changes their scope
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Decision: structured templates per artifact with extension points and an import collector (option B), recorded in `backlog/decisions/decision-1 - Generator-architecture.md`. Promotion uses a `@Promoted()` declaration with the artifact's name, found by a syntactic summary builder; the generated library imports and re-exports it.

Prototype: `prefab_flutter_generator/prototype/pf37/` (run with `dart test prototype/pf37`); the detail screen built from an artifact template and three feature modules matches today's `DetailScreenGenerator` output for three scenarios, and promoted screens are skipped. PF-38 deletes it.

Follow-ups: PF-38 and PF-39 updated with the decision's concepts; new PF-41 (format output with `dart_style`, after PF-38) and PF-42 (promotion, milestone m-1). The summary builder for promotion was not prototyped (PF-42).
<!-- SECTION:NOTES:END -->
