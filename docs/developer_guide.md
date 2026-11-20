# Developer guide

For contributors to Prefab Flutter. Users of the library should read the
[user guide](user_guide.md) instead.

## Repository layout

The repository holds four packages. Each has its own `pubspec.yaml` and is
analysed and tested on its own.

| Package | Kind | Role |
|---|---|---|
| `prefab_flutter` | Pure Dart | The public annotations (`@View`, `@Field`, `@Update`, `@Delete`, `@Parent`, `@Id`) and the `FieldWidget`/`Validator` types. It has no dependencies, so generator and app can both import it. |
| `prefab_flutter_generator` | Pure Dart, `dev_dependency` of apps | The `build_runner` builder. It reads the annotations with the analyzer and `source_gen`, and writes one `<file>.prefab.dart` per annotated source file. |
| `prefab_flutter_widgets` | Flutter | Runtime widgets and helpers that generated code calls (`PrefabDeleteDialog`, `PrefabSearchBar`, `PrefabSortMenu`, `PrefabPaginationBar`, `PrefabListAdapter`, `prefabDioProvider`). |
| `prefab_flutter_example` | Flutter app | A runnable app with an in-memory mock backend. CI runs the generator on it and analyses the output, so it proves that the generated code compiles. |

Data flows in one direction: **annotations -> generator -> generated code ->
runtime widgets**. Generated code may import `prefab_flutter_widgets`; the
generator must never import it (it is pure Dart).

### Generator internals

```
prefab_flutter_generator/
  build.yaml                        # registers prefab_builder
  lib/builder.dart                  # builder factories
  lib/src/manifest/                 # annotation -> plain Dart model
    entity_manifest.dart            #   EntityManifest, constructor params
    field_manifest.dart             #   FieldManifest
    entity_paths.dart               #   route and file path helpers
  lib/src/generators/               # one source_gen Generator per output kind
    api_client_generator.dart
    provider_generator.dart
    detail_screen_generator.dart
    list_screen_generator.dart
    form_screen_generator.dart
    routes_generator.dart
    prefab_generator.dart           # runs all of the above, merges the output
  test/                             # one test file per generator, plus feature tests
```

1. Each generator is a `source_gen` `Generator`. It finds `@View` classes with
   a `TypeChecker`, builds an `EntityManifest` from the analyzer elements, and
   returns Dart source as a string.
2. `PrefabGenerator` calls every generator, removes the imports that point at
   the other generators' files, merges and sorts the remaining imports, and
   concatenates the bodies into one `.prefab.dart` library.
3. Read annotations through the manifest (`EntityManifest`, `FieldManifest`),
   not directly in the generator, so every generator sees the same defaults
   and inference.

This structure is being replaced by artifacts, extension points and feature
modules, as decided in
[decision-1](../backlog/decisions/decision-1%20-%20Generator-architecture.md)
(core planned in PF-38, feature modules in PF-39). A throwaway prototype of
the detail screen lives in `prefab_flutter_generator/prototype/pf37/`; it is
not part of the generator and not run by CI.

## Adding a generator

Say you want to generate `{Entity}Foo` classes.

1. **Write the generator.** Create `lib/src/generators/foo_generator.dart`
   with a class that extends `Generator`. Return `''` when the library has no
   `@View` class. Build `EntityManifest`s from the annotated elements, as
   `routes_generator.dart` does, and emit Dart source. Start the output with
   the `import` lines it needs; `PrefabGenerator` merges them.
2. **Register it in `PrefabGenerator`.** Add `FooGenerator()` to the list in
   the `PrefabGenerator` constructor
   (`lib/src/generators/prefab_generator.dart`). If it generates a sibling
   file under its own extension for testing, add that extension (for example
   `foo`) to the `_siblingImport` regular expression so cross-imports are
   dropped from the merged file. The generator order is the order of the
   output.
3. **Add a test builder in `lib/builder.dart`.** Add a factory such as
   `Builder fooBuilder(BuilderOptions options) => LibraryBuilder(FooGenerator(), generatedExtension: '.foo.dart');`.
   This is only for unit tests, which exercise one generator in isolation.
4. **Keep `build.yaml` unchanged.** Only `prefab_builder` (`.dart` ->
   `.prefab.dart`, `auto_apply: dependents`, `build_to: source`) is registered,
   and it covers every generator through `PrefabGenerator`. Edit `build.yaml`
   only to add a new *builder* with a different output extension; then list its
   factory under `builder_factories` and its `build_extensions`, and note the
   new file in the user guide.
5. **Write tests** (see below), then update the
   [user guide](user_guide.md) (generated files and classes) and the root
   `README.md` if the output changes.

### Testing a generator

Generator tests use `build_test`'s `testBuilder`. They run the builder on
in-memory sources and assert on the generated text:

```dart
await testBuilder(
  fooBuilder(BuilderOptions.empty),
  {...prefabSources, 'a|lib/product.dart': productSource},
  outputs: {
    'a|lib/product.foo.dart': decodedMatches(contains('class ProductFoo')),
  },
);
```

- Import `support/prefab_sources.dart` and use `prefabSources`. It reads the
  real annotation files under `prefab_flutter/lib/` at test time, so tests
  always see the shipped annotations. Never copy annotation sources into a
  test file; when you add an annotation or parameter, nothing in the tests
  needs to change.
- Name tests after the backlog task and acceptance criterion they cover
  (`'PF-20 AC#4 - ...'`).
- To test the merged output, use `prefabBuilder` and `.prefab.dart`
  (`prefab_generator_test.dart`).
- For anything that must *compile*, add or extend an entity in
  `prefab_flutter_example`: CI generates its code and runs `flutter analyze
  --fatal-infos` on it.

### Snapshot tests

`test/snapshots_test.dart` runs `prefabBuilder` on every file in
`test/snapshots/fixtures/` and compares the **complete** generated output with
`test/snapshots/expected/<fixture>.prefab.dart`. A mismatch fails the test and
prints a line diff (`-` expected, `+` actual). Snapshots are the safety net for
refactoring the generator: output must not change by accident.

- **Add a fixture:** create `test/snapshots/fixtures/<scenario>.dart` with one
  entity scenario (it imports `package:prefab_flutter/prefab_flutter.dart`),
  then run the update command below and review the new expected file. Prefer a
  new fixture over changing an existing one, so parallel branches do not
  conflict.
- **Update snapshots** after an intended output change:

  ```bash
  cd prefab_flutter_generator
  UPDATE_SNAPSHOTS=1 dart test test/snapshots_test.dart
  ```

  Then read `git diff test/snapshots/expected` before committing.
- **Merge conflicts** in expected files: take `main`'s version, regenerate with
  the command above, and review the diff.
- Fixtures and expected files are excluded from `dart analyze`.

## Running tests

Run these from the repository root. All packages must be green before a pull
request is ready.

| Package | Commands |
|---|---|
| `prefab_flutter` | `cd prefab_flutter && dart pub get && dart analyze --fatal-infos` |
| `prefab_flutter_generator` | `cd prefab_flutter_generator && dart pub get && dart analyze --fatal-infos && dart test` |
| `prefab_flutter_widgets` | `cd prefab_flutter_widgets && flutter pub get && flutter analyze --fatal-infos && flutter test` |
| `prefab_flutter_example` | `cd prefab_flutter_example && flutter pub get && dart run build_runner build --delete-conflicting-outputs && flutter analyze --fatal-infos && flutter test` |

To run a single generator test file: `dart test test/routes_generator_test.dart`.
The CI workflow (`.github/workflows/ci.yml`) runs the same commands. Generated
`*.prefab.dart` files in the example are not committed; do not add them.

## Publishing checklist

The packages are not on pub.dev yet. Publish in dependency order:
`prefab_flutter`, then `prefab_flutter_generator` and `prefab_flutter_widgets`.
The example app is never published.

1. All CI jobs are green on `main`.
2. Bump `version` in each package's `pubspec.yaml`. In `CHANGELOG.md`, add
   the bullets of every fragment in the package's `changelog.d/` to
   "Unreleased", rename "Unreleased" to the new version with a date, and
   delete the merged fragment files.
3. Make versions consistent: the `^x.y.z` constraints that
   `prefab_flutter_generator` has on `prefab_flutter`, and the version in the
   dependency snippets of the root `README.md` and package READMEs.
4. Remove the `dependency_overrides` block from
   `prefab_flutter_generator/pubspec.yaml` (it points at `../prefab_flutter`)
   and, once published, replace the git/path references in the README quick
   start with the pub.dev version constraints. Update the "pre-release" status
   notes.
5. Check the documentation: root README, `docs/user_guide.md` (including the
   Known limitations table), package READMEs, and backlog task status.
6. In each package, run `dart pub publish --dry-run` (`flutter pub publish
   --dry-run` for `prefab_flutter_widgets`) and fix every warning.
7. Publish with `dart pub publish` in the order above, wait until each package
   appears on pub.dev before publishing the next, and tag the release in git
   (`git tag v0.1.0 && git push --tags`).
8. Add the pub.dev badges to the package READMEs (see below) if not present.

## Documentation conventions

- `README.md` and `docs/user_guide.md` describe what the code does today.
  Planned behaviour is mentioned only with its backlog task id.
- Every user-visible change updates the user guide in the same pull request.
- Backlog tasks live in `backlog/tasks`; move a task to `backlog/completed`
  with `git mv` once its status is `Done`.
  `tool/check_backlog.sh` (also run in CI) checks this and the other backlog
  rules.
- Changelog entries are written as fragments in `<package>/changelog.d/<task-id>.md`
  instead of editing `CHANGELOG.md`, so parallel branches do not conflict.
  They are merged into `CHANGELOG.md` when releasing.
