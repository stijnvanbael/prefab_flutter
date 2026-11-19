---
id: m-1
title: "M1 - Escape hatches and promotion"
---

## Description

No app has to abandon generation because one screen or one field is special.
Both reference apps (energy balancing, self-study) have a central
hand-written screen that must build on generated parts.

Scope (tasks to be created when M0's architecture decision is made):
- Promote one generated artifact (screen, provider, API client, route) into
  the codebase; the generator detects it, stops generating it, and the rest
  wires to the promoted version
- Custom field widgets, used in forms and detail views
- Custom actions on list and detail screens
- Hand-written screens and routes plugged into the generated navigation
- Theming hooks for generated screens
- A documented, stable public API of generated providers, API clients and
  runtime widgets for hand-written screens
- An example with one hand-written screen built on generated parts
