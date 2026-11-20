[← User guide](../user_guide.md)

# Known limitations

These are known gaps in the current pre-release. Each has a backlog task.

| Limitation | Workaround | Task |
|---|---|---|
| Detail screens do not link to the lists of nested child entities; reach them by URL (`/products/1/reviews`) or add your own link | Navigate with `context.push` | PF-35 |
| A promoted artifact with the wrong signature gives a compile error in the generated file instead of a build error | Compare with the signatures in [Promoting](promoting.md) | PF-70 |
