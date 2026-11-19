---
id: m-4
title: "M4 - Production readiness"
---

## Description

The first reference app goes to production.

Scope:
- Security review of generated code (token storage, no secrets in the
  client, input handling)
- Accessibility (semantics, keyboard navigation on web and desktop)
- Error, retry and connection-loss handling; performance with large lists
- Crash and error reporting hooks
- Publish the packages to pub.dev (PF-10), once a reference app is close to
  production
