---
id: m-1
title: "M1 - Escape hatches and promotion"
---

## Description

No app has to abandon generation because one screen or one field is special.
Both reference apps (energy balancing, self-study) have a central
hand-written screen that must build on generated parts.

Scope:
- Promote one generated artifact (screen, provider, API client, route) into
  the codebase; the generator detects it, stops generating it, and the rest
  wires to the promoted version (PF-42), with a command that writes the
  artifact to a file (PF-49)
- Custom field widgets, used in forms and detail views (PF-65)
- Custom actions on list and detail screens (PF-44)
- Hand-written screens and routes plugged into the generated navigation (PF-45)
- Theming hooks for generated screens (PF-46)
- A documented, stable public API of generated providers, API clients and
  runtime widgets for hand-written screens (PF-47)
- An example with one hand-written screen built on generated parts (PF-48)
