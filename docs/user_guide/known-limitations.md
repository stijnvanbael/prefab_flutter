[← User guide](../user_guide.md)

# Known limitations

These are known gaps in the current pre-release. Each has a backlog task.

| Limitation | Workaround | Task |
|---|---|---|
| Detail screens do not link to the lists of nested child entities; reach them by URL (`/products/1/reviews`) or add your own link | Navigate with `context.push` | PF-35 |
| `@EntityScreen` and `@EntityAction` match their entity by class name; two `@Entity` classes with the same name in different libraries are not distinguished | Give the entities distinct names | PF-67 |
| A promoted list or detail screen loses its actions and `@EntityScreen` links without a message; the `promote` command does not copy them | Add them to the promoted screen by hand | PF-68 |
| A promoted artifact with the wrong signature gives a compile error in the generated file instead of a build error | Compare with the signatures in [Promoting](promoting.md) | PF-70 |
