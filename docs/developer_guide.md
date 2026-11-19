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
  {..._prefabSources, 'a|lib/product.dart': productSource},
  outputs: {
    'a|lib/product.foo.dart': decodedMatches(contains('class ProductFoo')),
  },
);
```

- Copy the `_prefabSources` map from an existing test (for example
  `routes_generator_test.dart`). It supplies stub annotation sources so the
  resolver can resolve `package:prefab_flutter/...`. When you add an
  annotation or parameter, extend the stubs in each test file that needs it.
- Name tests after the backlog task and acceptance criterion they cover
  (`'PF-20 AC#4 - ...'`).
- To test the merged output, use `prefabBuilder` and `.prefab.dart`
  (`prefab_generator_test.dart`).
- For anything that must *compile*, add or extend an entity in
  `prefab_flutter_example`: CI generates its code and runs `flutter analyze
  --fatal-infos` on it.

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
2. Bump `version` in each package's `pubspec.yaml`, and move the matching
   `CHANGELOG.md` entries from "Unreleased" to the new version with a date.
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
