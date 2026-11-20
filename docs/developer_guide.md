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
  lib/src/core/                     # the generator core (no feature knowledge)
    code.dart                       #   Code, Libs, Imports
    artifact.dart                   #   Artifact, ArtifactId, ArtifactKind
    entity_context.dart             #   EntityContext (reads @View classes), ArtifactSet
    extension_point.dart            #   ExtensionPoint (ordered, optionally single-valued)
    feature.dart                    #   Feature (feature module contract)
    library_emitter.dart            #   LibraryEmitter: assembles a .prefab.dart
    format.dart                     #   formatGenerated: dart_style step
    artifact_generator.dart         #   ArtifactGenerator: source_gen wrapper
    field_registries.dart           #   FieldEmitter, ValidatorEmitter, FieldDisplay + registries
  lib/src/features/                 # feature modules, one directory each
    features.dart                   #   registeredFeatures (alphabetical)
    list_query/                     #   search, sort and pagination
  lib/src/generators/               # the artifacts, one file per output kind
    api_client_generator.dart       #   ApiClientArtifact
    provider_generator.dart         #   DetailProvider-, ListProvider-, ApiClientProviderArtifact
    detail_screen_generator.dart    #   DetailScreenArtifact
    list_screen_generator.dart      #   ListScreenArtifact
    form_screen_generator.dart      #   CreateScreenArtifact, EditScreenArtifact
    routes_generator.dart           #   RoutesArtifact (one per source file)
    prefab_generator.dart           #   PrefabGenerator: all artifact factories
  test/                             # one test file per generator, plus feature tests
```

The architecture is decided in
[decision-1](../backlog/decisions/decision-1%20-%20Generator-architecture.md):
structured templates per artifact, extension points that feature modules
contribute to, and an import collector. There is no `code_builder`.

1. **Entities.** `EntityContext.readAll` finds the `@View` classes of a source
   file with a `TypeChecker` and builds an `EntityManifest` per class from the
   analyzer elements. Read annotations through the manifest
   (`EntityManifest`, `FieldManifest`), not directly in a template, so every
   artifact sees the same defaults and inference.
2. **Artifacts.** An `Artifact` is one independently emitted unit: an API
   client, a provider, a screen, the routes. It has an `ArtifactId` (kind and
   entity), a `primaryName` (`ProductDetailScreen`), the `declaredNames` it
   introduces, and `emit()`, which returns a `Code`: the text of the
   artifact plus the libraries (`Libs.materialUi`, a relative file name, ...)
   it needs. Each artifact class owns the template of its output. An
   `ArtifactFactory` creates the artifacts of one entity.
3. **Imports.** Fragments name the libraries they need; nothing writes
   `import` lines. `LibraryEmitter` merges the imports of the artifacts it
   emits (package imports sorted, a blank line, other imports sorted). A
   library is imported only if some emitted artifact needs it. All artifacts
   of a source file live in one library, so they never import each other.
4. **Emission.** `PrefabGenerator` is an `ArtifactGenerator` with the
   factories of every kind. `LibraryEmitter.emit` creates the artifacts
   kind-major (all API clients, then all provider groups, ...; a factory may
   return several artifacts of an entity that must stay together), lets
   features contribute, emits each artifact separately and writes banner,
   imports and bodies. The emitter can skip artifacts by name
   (`LibraryEmitter.promoted`); the skipped artifact is replaced by an import
   and a re-export of the hand-written declaration. The promoted names come
   from `@Promoted` annotations through the `prefab_promoted` builder
   (`lib/src/promoted/`), which summarises `@Promoted` declarations of each
   file in `.prefab_promoted.json`; `prefab_builder` reads them and checks that
   every promoted name is a generated artifact of some file.
   `ArtifactGenerator` then formats the assembled library with `dart_style`
   (`lib/src/core/format.dart`), so fragments need not be indented exactly; the
   builders in `lib/builder.dart` switch `source_gen`'s own formatting off so
   there is one formatter. A fragment that is not valid Dart fails the build
   with the source file name and the unformatted output.
5. **Extension points.** An `ExtensionPoint` collects `Code` contributions from
   features, rendered by `order`, then feature name, so the registration
   order of features never matters. A single-valued point
   (`maxContributions: 1`) fails with both feature names when two features
   claim it. A `ValuePoint<T>` holds typed values (`NamedArgument`,
   `QueryParameter`) that several features combine and the template renders.
   A `Feature` (`lib/src/core/feature.dart`) adds artifacts and contributes to
   the extension points of the artifacts it finds in the `ArtifactSet`; see
   "Adding a feature". The points that exist today are in the table there.
6. **Registries.** `FieldEmitters` (how a `FieldWidget` appears in the forms),
   `ValidatorEmitters` (the check a `Validator` adds) and `FieldDisplays` (how a
   value is shown in detail screens and list tiles) look up the emitter by the
   annotation value. The validators are one class per `Validator` in
   `lib/src/features/validators/` (PF-60). The field emitters still wrap the
   code that used to live in the form template and the display code in the
   detail and list templates; they move into one class per widget in the
   follow-ups of PF-39 (PF-59, PF-62 to PF-64).
7. **Tests.** The per-kind generators (`ApiClientGenerator`, ...,
   `RoutesGenerator`) are `ArtifactGenerator`s with the factories of one kind.
   They back the per-kind builders in `lib/builder.dart` that unit tests use;
   their output is one library with exactly the imports of its artifacts.

## Adding an artifact

Say you want to generate `{Entity}Foo` classes.

1. **Write the artifact.** Create `lib/src/generators/foo_generator.dart` with
   a class `FooArtifact extends Artifact` that takes an `EntityContext`.
   Implement `id`, `primaryName` and `emit()`: write the template (from the
   manifest) and return `Code(text.trim(), imports: {...})` with every library
   the text uses (`Libs.*`, `entity.sourceFileName`). Add a factory
   (`static Iterable<Artifact> create(EntityContext entity)`) that returns an
   empty list when the entity has no `Foo`. Add a value to `ArtifactKind`.
2. **Register it in `PrefabGenerator`.** Add `FooArtifact.create` to the list
   in `lib/src/generators/prefab_generator.dart`. The order of the list is the
   order of the output.
3. **Add a test builder in `lib/builder.dart`.** Add a `FooGenerator extends
   ArtifactGenerator` with `FooArtifact.create` and a factory such as
   `Builder fooBuilder(BuilderOptions options) => LibraryBuilder(FooGenerator(), generatedExtension: '.foo.dart');`.
   This is only for unit tests, which exercise one kind in isolation.
4. **Keep `build.yaml` unchanged.** Only `prefab_builder` (`.dart` ->
   `.prefab.dart`, `auto_apply: dependents`, `build_to: source`) is registered,
   and it covers every artifact through `PrefabGenerator`. Edit `build.yaml`
   only to add a new *builder* with a different output extension; then list its
   factory under `builder_factories` and its `build_extensions`, and note the
   new file in the user guide.
5. **Write tests** (see below), then update the
   [user guide](user_guide.md) (generated files and classes) and the root
   `README.md` if the output changes.

## Adding a feature

A feature is behaviour declared on the model (search, sort, create, ...). It
lives in a **feature module** and adds code to the artifacts through extension
points, so adding or changing it does not touch the other features. Search,
sort and pagination (`lib/src/features/list_query/`) are the reference module.

1. **Create the module.** `lib/src/features/<feature>/<feature>_feature.dart`
   with a `const` class extending `Feature`. `name` is the directory name.
   `contribute(entity, artifacts)` looks up the artifacts it needs with
   `artifacts.get<ListScreenArtifact>(ArtifactKind.listScreen, entityName)`.
   The lookup returns `null` when the artifact is not generated or is promoted:
   skip it then, and never write to hand-written code.
2. **Contribute through points.** Add `Code` (written at column 0; the point
   indents it) with `point.add(name, Code(text, imports: {...}), order: n)`.
   Name every library the text uses in `imports`; never write `import` lines.
   Use a distinct `order` per contribution; ties are broken by feature name.
   Typed points (`ValuePoint<T>`) take values instead of code.
3. **Register it.** Add one line to `registeredFeatures` in
   `lib/src/features/features.dart`, kept alphabetical. The order has no
   meaning.
4. **Test it.** One test file per feature (`test/<feature>_test.dart`), plus a
   snapshot fixture for new output (see "Snapshot tests").
5. **Document it** in the user guide page of its topic.

What a module may touch: its own directory, its own test file and
documentation, and its one registry line. It reads annotation data from the
manifest (`EntityContext.manifest`); data that only the feature uses is read
inside the module (for list query: the `ListQueryManifest` extension). If it
needs an extension point that does not exist, add the point to the artifact as
a separate, small change (the artifact owns its skeleton and renders the
point). It may not edit another feature's directory or the templates beyond
adding a point.

`FieldManifest` and the raw flags (`searchable`, `sortable`, `@View.paged`)
stay in `lib/src/manifest/`: they are read in one place with the defaults and
inference of every field (principle 2), and several features look at the same
field. Derived getters used by one feature move into its module.

Extension points that exist today (all contributions are at column 0):

| Artifact | Point | Holds | Orders in use |
|---|---|---|---|
| list screen | `buildStatements` (indent 4) | `Code` | 10 list query |
| list screen | `appBarActions`, `aboveList`, `belowList` (indent 10) | `Code` | 10 list query |
| list screen, detail screen | `fieldValue` | `ValuePoint<FieldValue>` | 10 nullable fields |
| list notifier | `state`, `onBuild`, `methods` (indent 2, 4, 2) | `Code` | 10 list query |
| list notifier | `fetchArguments` | `ValuePoint<NamedArgument>` | 10 search, 20 sort, 30 descending, 40 page, 50 page size |
| API client | `listQueryParameters` | `ValuePoint<QueryParameter>` | 10 search, 20 sort, 30 descending, 40 page, 50 page size |

The other points sketched in decision-1 are added by the migration tasks
PF-59, PF-60 and PF-62 to PF-64. The nullable handling of the create and edit
forms stays in the form screen until PF-59 splits it per `FieldWidget`.

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
5. Check the documentation: root README, `docs/user_guide/` (including the
   Known limitations page), package READMEs, and backlog task status.
6. In each package, run `dart pub publish --dry-run` (`flutter pub publish
   --dry-run` for `prefab_flutter_widgets`) and fix every warning.
7. Publish with `dart pub publish` in the order above, wait until each package
   appears on pub.dev before publishing the next, and tag the release in git
   (`git tag v0.1.0 && git push --tags`).
8. Add the pub.dev badges to the package READMEs (see below) if not present.

## Documentation conventions

- `README.md` and the pages in `docs/user_guide/` describe what the code does today.
  Planned behaviour is mentioned only with its backlog task id.
- Every user-visible change updates the matching user guide page in the same
  pull request. `docs/user_guide.md` is only the index; add a page there (and
  to the index) only for a new topic.
- Backlog tasks live in `backlog/tasks`; move a task to `backlog/completed`
  with `git mv` once its status is `Done`.
  `tool/check_backlog.sh` (also run in CI) checks this and the other backlog
  rules.
- Changelog entries are written as fragments in `<package>/changelog.d/<task-id>.md`
  instead of editing `CHANGELOG.md`, so parallel branches do not conflict.
  They are merged into `CHANGELOG.md` when releasing.
