# PF-37 generator architecture prototype

Throwaway prototype supporting
[decision-1](../../../backlog/decisions/decision-1%20-%20Generator-architecture.md):
the detail screen built from an artifact template, extension points and three
feature modules (update, delete, breadcrumbs), with promotion skipping.

It is not part of the published generator and not run by CI. PF-38 builds the
real core in `lib/src/core/` and deletes this directory.

```bash
cd prefab_flutter_generator && dart test prototype/pf37
```
