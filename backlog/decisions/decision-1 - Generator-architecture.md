---
id: decision-1
title: Generator architecture
date: '2026-11-19'
status: accepted
---

## Context

Today the generator is six `source_gen` generators (API client, providers,
detail, list and form screens, routes) that each build a whole library with
`StringBuffer.writeln`. `PrefabGenerator` runs all six, strips their banners,
finds `import` lines with a regular expression, drops imports of each other's
files and concatenates the rest into one `.prefab.dart`.

That has three costs that grow with every feature on the roadmap:

- **Features are spread over generators.** Nullable fields, nesting or a new
  `FieldWidget` edit several of the six files and the 668-line
  `entity_manifest.dart`. Parallel tasks conflict in the same methods
  (`form_screen_generator.dart` alone is close to 1000 lines).
- **Nothing is an artifact.** A generator writes all entities' screens in one
  buffer; there is no unit that could be skipped when a developer promotes
  `ProductDetailScreen` (principle 3, milestone M1).
- **Imports are text.** Each generator decides its imports up front from
  flags that duplicate the conditions further down (`if (hasUpdate ||
  hasDelete || hasBreadcrumbs) go_router`), and the merge relies on the
  sibling-file regular expression.

The decision has to serve the principles in `docs/vision.md`: per-artifact
emission and promotion (3), plain readable generated code (4) and feature
modules for parallel, agent-driven development (8).

## Options

**A. `package:code_builder` with `dart_style`.** Build every declaration as a
`code_builder` AST (`Class`, `Method`, `refer('Scaffold').call(...)`), let its
`Allocator` collect imports, format with `DartFormatter`.

**B. Structured string templates per artifact with an import collector.**
Every artifact is a class with a template (Dart string interpolation, close
to the generated code) and named *extension points*; features add fragments
to extension points; each fragment names the libraries it needs and the core
collects them.

**C. Hybrid.** `code_builder` for declarations (class shells, constructors,
fields, imports), templates (`Code('...')`) for method bodies and widget
trees.

What the same piece of output (the Delete action of the detail screen) looks
like in A:

```dart
refer('IconButton', Libs.materialUi).call([], {
  'icon': refer('Icon', Libs.materialUi)
      .constInstance([refer('Icons', Libs.materialUi).property('delete')]),
  'tooltip': literalString('Delete'),
  'onPressed': refer('${e}Async').property('hasValue').conditional(
        Method((m) => m
          ..modifier = MethodModifier.async
          ..body = Block.of([
            declareFinal(e).assign(refer('${e}Async').property('value').nullChecked).statement,
            declareFinal('confirmed').assign(refer('showPrefabDeleteDialog', Libs.widgets)
                .call([], {'context': refer('context'), /* ... 4 more ... */}).awaited).statement,
            // if (confirmed && context.mounted) context.pop(); -> more AST nodes
          ])).closure,
        literalNull,
      ),
})
```

and in B (from the prototype, `features/delete_action.dart`):

```dart
Code('''
IconButton(
  icon: const Icon(Icons.delete),
  tooltip: 'Delete',
  onPressed: ${e}Async.hasValue
      ? () async {
          final $e = ${e}Async.value!;
          final confirmed = await showPrefabDeleteDialog(
            context: context,
            item: $e,
            itemLabel: $e.${m.firstLabelFieldName}.toString(),
            onDelete: () => ref.read(${e}sProvider$listArg.notifier).delete($e),
          );
          if (confirmed && context.mounted) {
            context.pop();
          }
        }
      : null,
),''', imports: {Libs.goRouter, Libs.widgets})
```

### Comparison

| Criterion | A. code_builder | B. Templates + extension points | C. Hybrid |
|---|---|---|---|
| Per-artifact emission | Yes: one `Spec` per artifact | Yes: one `Artifact` per unit, emitted separately | Yes |
| Feature modules and extension points | Possible: points hold `Expression`/`Code` lists | Natural: points hold `Code` fragments or typed values | Possible, but a point is either an AST or a string, so features must know which |
| Import handling | Best: automatic from `refer(symbol, url)`, but the default allocator prefixes (`_i1.Scaffold`); unprefixed needs a custom allocator | Explicit: each fragment lists its libraries, the core merges and orders them. A forgotten import is a compile error, caught by `flutter analyze` on the example app (and visible in snapshot diffs) | Automatic only for the `code_builder` part; template parts still list imports |
| Readability of the generator for agents | Poor for widget trees: 3-5× more lines, the output shape is hidden in AST calls, agents must know the `code_builder` API | Good: the template looks like the output; agents edit Flutter code they already know | Two models in one file; the hard part (widget trees) stays a template anyway |
| Readability of generated code | Good once formatted (`dart_style` is required, `code_builder` emits one line) | As good as the template; best with `dart_style` (see below) | Good once formatted |
| Migration cost | High: rewrite ~3000 lines at once; every snapshot changes; formatting and structure change together | Low and incremental: today's `writeln` lines move into artifact templates and feature modules unchanged; snapshots stay byte-identical (proved by the prototype) | Medium: declarations rewritten, bodies moved |

## Decision

**Option B: structured templates per artifact, typed extension points, and an
import collector in the core.** No `code_builder`.

The generated code is Flutter widget trees and Riverpod declarations, which
are mostly *expressions*; that is where `code_builder` is weakest and
templates are strongest. Its one real advantage, automatic imports, is
covered by fragments that declare their libraries; the set of libraries
generated code uses is small (`material_ui`, `flutter_riverpod`, `go_router`,
`dio`, the runtime widgets, `dart:async`, `flutter/services`) and fixed per
feature. Principle 8 decides between A and B: an agent adding a feature
should edit code that looks like what it produces.

Formatting the output with `dart_style` is decided separately in PF-41: it
makes generated code readable regardless of template indentation
(principle 4), but it changes every snapshot, so it lands as its own change
after PF-38 and is not mixed with structural moves.

## Core concepts

The prototype in `prefab_flutter_generator/prototype/pf37/` implements the
sketches below; PF-38 moves them to `lib/src/core/`.

### Code fragments and imports

```dart
/// Generated source plus the libraries it needs. Written at column 0; the
/// extension point it is added to indents it. Never contains `import` lines.
class Code {
  const Code(this.text, {this.imports = const {}});
  final String text;
  final Set<String> imports;
}

abstract final class Libs {           // the libraries generated code may use
  static const materialUi = 'package:material_ui/material_ui.dart';
  static const riverpod = 'package:flutter_riverpod/flutter_riverpod.dart';
  static const goRouter = 'package:go_router/go_router.dart';
  static const widgets = 'package:prefab_flutter_widgets/prefab_flutter_widgets.dart';
  // dio, dart:async, flutter/services ...
}

/// One per generated library. render() keeps today's order: package imports
/// sorted, a blank line, other imports sorted, then exports of promoted
/// artifacts.
class Imports {
  void add(String uri);
  void export(String uri, String name);
  String render();
}
```

Imports are collected *bottom-up*: an artifact's `emit()` returns the
template's own imports plus the imports of every contribution it rendered,
and the core merges the artifacts' imports. A library is imported only if
some emitted fragment needs it, so the conditions in today's `_writeImports`
methods disappear. Generated artifacts never import each other: all
artifacts of a source file live in one library. The sibling-file regular
expression and the per-generator banners go away.

Because every artifact carries its own import set, an artifact can also be
written on its own, with exactly the imports it needs. The promotion tool in
M1 relies on that.

### Artifacts

```dart
enum ArtifactKind {
  apiClient, detailProvider, listProvider,
  detailScreen, listScreen, createScreen, editScreen, routes,
}

class ArtifactId { final ArtifactKind kind; final String entity; }

abstract class Artifact {
  ArtifactId get id;
  /// The name a developer promotes, e.g. `ProductDetailScreen`,
  /// `productsProvider`, `ProductApiClient`, `$productRoutes`.
  String get primaryName;
  /// All top-level names it declares (`productsProvider` + `ProductsNotifier`).
  List<String> get declaredNames => [primaryName];
  /// Renders the template after all features contributed.
  Code emit();
}

/// Creates the artifacts of one kind for an entity (none when not needed,
/// e.g. no edit screen without @Update).
typedef ArtifactFactory = Iterable<Artifact> Function(EntityContext entity);
```

An artifact class owns the *skeleton* of its output (class declaration,
constructor, provider watch, `Scaffold`, loading and error states) and
exposes extension points as fields. `EntityContext` gives it the
`EntityManifest`, `EntityPaths` and the source file name.

The `LibraryEmitter` assembles a `.prefab.dart`:

1. Create every artifact for every entity, **kind-major** (all API clients,
   then all providers, then detail screens...), which is today's order.
2. Drop promoted artifacts (see "Promotion").
3. Let every feature contribute to the remaining artifacts.
4. `emit()` each artifact separately, collect imports, write header, imports
   and the bodies.

### Extension points

```dart
class ExtensionPoint {
  ExtensionPoint(this.name, {this.maxContributions});
  void add(String feature, Code code, {int order = 0});
  String render(int indent);     // contributions by (order, feature name)
  Set<String> get imports;
}
```

Contributions are sorted by `order`, then feature name, so the output never
depends on the order features are registered in (registration is a list
that many branches touch; this keeps it free of meaning). Each extension
point documents the orders in use in its doc comment. A single-valued point
(`maxContributions: 1`, e.g. an AppBar `bottom`) fails the build with both
feature names when two features claim it.

Where several features must *combine* rather than append, the point holds
typed values instead of `Code`, and the artifact template renders them. For
example a list query parameter:

```dart
class QueryParameter {          // contributed by search, sort, paging, filters
  const QueryParameter(this.name, this.expression, {this.ifNotNull = false});
  final String name;            // 'search'
  final String expression;      // 'search'
  final bool ifNotNull;         // `if (search != null) 'search': search`
}
```

The extension points PF-38 and PF-39 start from (names are
`<artifact>.<point>`):

| Artifact | Extension point | Holds | Used today by |
|---|---|---|---|
| list screen | `appBarActions` | `Code` (widgets) | sort menu |
| list screen | `appBarBottom` (max 1) | `Code` | breadcrumbs |
| list screen | `aboveList`, `belowList` | `Code` (widgets in the body `Column`) | search bar; pagination bar |
| list screen | `floatingActionButton` (max 1) | `Code` | create (`@Create`) |
| list screen | `itemTile` (max 1, default from views) | `Code` | views (`@Field.views`) |
| detail screen | `appBarActions` | `Code` | edit (`@Update`), delete (`@Delete`) |
| detail screen | `appBarBottom` (max 1) | `Code` | breadcrumbs |
| detail screen | `fieldValue` | `FieldDisplay` per resolved field kind (below) | nullable fields; later custom display widgets |
| create/edit screen | `fields` | `FieldEmitter` per resolved `FieldWidget` (below) | every field widget |
| create/edit screen | `validators` | `ValidatorEmitter` per `Validator` type (below) | every validator |
| list notifier | `state`, `methods` | `Code` (fields, methods) | search, sort, paging |
| list notifier | `fetchArguments` | `NamedArgument` | search, sort, paging |
| list notifier, detail provider | `familyKey` | the ancestor key, set by nesting | nested resources |
| API client | `methods` | `Code` | create, update, delete |
| API client | `listQueryParameters` | `QueryParameter` | search, sort, paging |
| routes | `routes`, `childRoutes` | `Code` (route entries) | screens, nesting |

Artifacts are extension points too: a feature may register an
`ArtifactFactory` (the update feature adds the edit screen artifact, the
create feature the create screen).

Field widgets and validators are *registries keyed by the annotation value*,
so a new widget or validator is one new file and one registry line, without
touching the form template:

```dart
/// How one resolved FieldWidget appears in the create and edit forms.
abstract class FieldEmitter {
  const FieldEmitter();
  FieldWidget get widget;                       // FieldWidget.numberInput
  bool accepts(FieldManifest field);            // auto inference: int/double/num
  Code? stateDeclaration(FieldManifest field);  // controller or value field
  Code initialValue(FieldManifest field, String entity); // edit prefill
  Code formField(FieldManifest field, FormContext form); // the widget
  String valueExpression(FieldManifest field);  // value passed to the constructor
}

/// The Dart condition a validator adds to a field's `validator:` callback.
abstract class ValidatorEmitter<V extends Validator> {
  const ValidatorEmitter();
  Code check(FieldManifest field, V validator, String value);
}

/// How a field's value is shown in detail screens and list tiles.
abstract class FieldDisplay {
  const FieldDisplay();
  bool accepts(FieldManifest field);
  String text(FieldManifest field, String receiver); // `p.price.toString()`
}
```

### Feature modules

```dart
/// lib/src/features/<feature>/<feature>_feature.dart
abstract class Feature {
  const Feature();
  String get name;                                // 'list_query'
  List<ArtifactFactory> get artifacts => const []; // new artifacts, if any
  void contribute(EntityContext entity, ArtifactSet artifacts);
}
```

A feature looks artifacts up with
`artifacts.get<DetailScreenArtifact>(ArtifactKind.detailScreen, entity)`,
which returns `null` when the artifact is not generated or is promoted, so
features never contribute to hand-written code. A feature module may touch
only its own directory, its own test file and documentation page, and one
line in the feature registry (`lib/src/features/features.dart`, kept
alphabetical). If it needs an extension point that does not exist, adding the
point to the artifact is a separate, small change. PF-39 documents this
contract in the developer guide.

Annotation reading stays in `EntityManifest`/`FieldManifest` for now, so all
features see the same defaults and inference (principle 2). When a feature
needs data that only it uses, it may read it in its own module from
`EntityContext.element`; moving existing reading out of `entity_manifest.dart`
is done per feature group in the PF-39 follow-ups.

## Promotion

Promotion itself is M1 work; this section fixes the mechanism so PF-38 can
prepare for it and the M1 task (PF-42) can implement it.

**Marking.** A developer promotes an artifact by declaring, anywhere under
`lib/`, a top-level class or variable *with the artifact's primary name*,
annotated with `@Promoted()` (a new annotation in `prefab_flutter`):

```dart
// lib/screens/product_detail_screen.dart
import 'package:prefab_flutter/prefab_flutter.dart';
import '../product.prefab.dart';   // generated providers, routes, ...

@Promoted()
class ProductDetailScreen extends ConsumerWidget { ... }
```

The annotation is required, rather than detecting any class with a matching
name as Prefab does, because:
- a typo is reported (`@Promoted class ProductDetailScren is not a generated
  artifact; did you mean ProductDetailScreen?`) instead of silently keeping
  the generated version;
- only annotated declarations need to be collected, so the build does not
  depend on every name in the package (see below), and editing an unrelated
  file does not regenerate everything.

**Detection.** A second builder, `prefab_promoted`, runs on every `lib/**.dart`
before `prefab_builder` and writes a small summary to the build cache
(`build_to: cache`), only for files that contain `@Promoted`:

```json
// lib/screens/product_detail_screen.prefab_promoted.json
[{"name": "ProductDetailScreen", "uri": "package:shop/screens/product_detail_screen.dart"}]
```

It reads the *unresolved* syntax tree (`parseString`), not the resolved
library: a promoted file imports the generated `.prefab.dart`, so resolving
it would make the scanner depend on the output of `prefab_builder`. The
syntactic check accepts `@Promoted()` and `@prefix.Promoted()`.
`prefab_builder` declares `required_inputs: [".prefab_promoted.json"]` in
`build.yaml` and reads all summaries with
`buildStep.findAssets(Glob('lib/**.prefab_promoted.json'))`. This is the
two-phase pattern of `injectable_generator`.

**Skipping and wiring.** `LibraryEmitter` drops every artifact whose
`primaryName` is promoted (with all its `declaredNames`) before features
contribute, then:
- *imports* the promoted library, so the remaining generated artifacts
  (routes, list screens navigating to the detail screen, other providers)
  keep referring to the same name, now resolved to the hand-written class;
- *re-exports* it with `export '<uri>' show ProductDetailScreen;`, so code
  that imports the generated library (`main.dart`, routes of other files,
  other entities' generated code for breadcrumbs) keeps compiling unchanged.

Dart allows the resulting import cycle (`product.prefab.dart` ↔
`product_detail_screen.dart`).

**Contract.** Generated code refers to a promoted artifact exactly as to the
generated one, so the promoted declaration must keep the artifact's public
signature: constructor parameters of screens (`id`, ancestor ids), the
provider's type and family key, the API client's methods used by providers.
If it does not, the build reports a compile error at the generated call
site. The M1 task documents the signature per artifact kind and adds a
check with a readable error where cheap (e.g. a screen without an `id`
parameter).

**Promotion tool.** Because each artifact is emitted separately with its own
imports, M1 can offer
`dart run prefab_flutter_generator:promote ProductDetailScreen`, which writes
that one artifact to a file with its imports, the `.prefab.dart` import and
`@Promoted()`.

The prototype proves skipping, importing and re-exporting; the summary
builder is not prototyped.

## Migration

The snapshot tests (PF-36) are the safety net: every step below keeps the
expected files byte-identical, except PF-41, which only reformats.

1. **PF-38 - core and artifacts.** Add `lib/src/core/` (as above). Move each
   generator's per-entity method (`_writeDetailScreenClass`,
   `_writeListScreenClass`, ...) into an artifact class with its lines
   unchanged, and turn each `_writeImports` condition into the imports of the
   fragment that needs them. `PrefabGenerator` becomes a thin wrapper around
   `LibraryEmitter`; the regular-expression merge is deleted. The
   per-generator test builders in `builder.dart` stay as wrappers that emit
   one artifact kind, so existing tests keep working; tests that assert on
   imports of sibling files (`product.provider.dart`) are changed and listed
   in the pull request. Add the skip-by-name hook with a unit test (not yet
   user-facing).
2. **PF-41 - `dart_style`.** Format the assembled library with
   `DartFormatter` (pinned language version) and regenerate the snapshots in
   one reviewable change. From then on template indentation is cosmetic.
3. **PF-39 - first feature module.** Move search, sort and pagination into
   `lib/src/features/list_query/`, using `appBarActions`, `aboveList`,
   `belowList`, the notifier points and `listQueryParameters`. Snapshots
   unchanged. Document the contract.
4. **Follow-ups (one task per feature group, in parallel).** Field widgets
   (one `FieldEmitter` each), validators, nullable fields, nested resources and
   breadcrumbs, create/update/delete, views. Each moves code out of an
   artifact template into a module with snapshots unchanged; the
   templates shrink to the skeleton.

During the migration, old-style code inside an artifact template and feature
modules coexist; existing helpers (`breadcrumbBottom`, `EntityPaths`) can be
wrapped as contributions before they are rewritten, as the prototype does.

## Prototype

`prefab_flutter_generator/prototype/pf37/` (not in `lib/`, not run by CI;
run it with `dart test prototype/pf37` in `prefab_flutter_generator`):

- `core/`: `Code`, `Imports`, `Artifact`, `ExtensionPoint`, `Feature`,
  `ArtifactSet`, `LibraryEmitter` with promotion skipping (about 300 lines).
- `artifacts/detail_screen.dart`: the detail screen skeleton with the
  `appBarActions` and `appBarBottom` extension points (93 lines).
- `features/`: update (Edit action), delete (Delete action with dialog) and
  breadcrumbs (wraps today's `breadcrumbBottom`), 40-54 lines each.
- `detail_screen_prototype_test.dart`: for a minimal entity, an entity with
  `@Update`, `@Delete`, `@Id` and views, and a three-level `@Parent` chain in
  one file, the prototype produces exactly the same code and the same import
  set as today's `DetailScreenGenerator` (only the import *order* differs,
  because the per-generator output is unsorted and the merged file sorts).
  Two more tests show a promoted detail screen being skipped, imported and
  re-exported while the other entities' screens are still generated.

Findings:
- Moving `writeln` calls into a template list (`lines([...])` with collection
  `if`/`for`) kept the output byte-identical with no special effort; the
  243-line generator became a 93-line template plus three self-contained
  features.
- The import conditions disappeared: `go_router` is imported because the
  Edit, Delete or breadcrumb fragment says so.
- Feature registration order did not matter (features are registered in a
  deliberately shuffled order); changing one contribution's `order` made the
  comparison fail as expected.
- Indentation is the main friction: fragments are written at column 0 and the
  extension point indents them, but fragments must still be internally
  indented right. PF-41 removes that concern.

## Consequences

- PF-38 builds the core described above (no `code_builder` dependency).
- PF-41 (new) formats the output with `dart_style` after PF-38.
- PF-39 uses the extension points and registries above for the feature
  module contract.
- PF-42 (new, M1) implements promotion as described.
- Generated code stays as readable as the templates; reviewers of a feature
  read Flutter code, not AST construction.
- Import mistakes surface as compile errors in the example app (and as
  snapshot diffs) rather than being impossible by construction; this is the
  main trade-off accepted against option A.
