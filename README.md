# Prefab Flutter

Generate CRUD screens for Flutter from annotated Dart classes.

Annotate an entity class, run `build_runner`, and Prefab Flutter generates:

- a **list screen**, a **detail screen** and **create / edit form screens**,
- **Riverpod providers** that load and mutate the data,
- a **Dio API client** for a REST backend,
- **GoRouter routes** that tie the screens together.

> **Status: pre-release (0.1.0, not yet on pub.dev).** Generated code does not
> yet compile without the workarounds listed under
> [Known limitations](docs/user_guide.md#known-limitations). Work is tracked in
> [`backlog/tasks`](backlog/tasks).

## Packages

| Package | Kind | Role |
|---|---|---|
| [`prefab_flutter`](prefab_flutter) | Dart | Annotations (`@View`, `@FormField`, `@Update`, `@Delete`, `@Parent`) and enums |
| [`prefab_flutter_generator`](prefab_flutter_generator) | Dart, dev dependency | `build_runner` generators |
| [`prefab_flutter_widgets`](prefab_flutter_widgets) | Flutter | Runtime widgets used by generated code (delete dialog, search bar, sort menu, pagination bar) |

## Quick start

### 1. Add dependencies

The packages are not published yet, so reference them by git or path:

```yaml
dependencies:
  flutter:
    sdk: flutter
  dio: ^5.4.0
  flutter_riverpod: ^2.5.0
  go_router: ^14.0.0
  prefab_flutter:
    git:
      url: https://github.com/stijnvanbael/prefab_flutter
      path: prefab_flutter
  prefab_flutter_widgets:
    git:
      url: https://github.com/stijnvanbael/prefab_flutter
      path: prefab_flutter_widgets

dev_dependencies:
  build_runner: ^2.4.0
  prefab_flutter_generator:
    git:
      url: https://github.com/stijnvanbael/prefab_flutter
      path: prefab_flutter_generator
```

### 2. Annotate a model

```dart
// lib/product.dart
import 'package:prefab_flutter/prefab_flutter.dart';

@View(title: 'Product', path: 'products')
@Update()
@Delete()
class Product {
  final int id;

  @FormField(validators: [Validator.required])
  final String name;

  @FormField(label: 'Price (EUR)', validators: [Validator.positiveNumber])
  final double price;

  @FormField()
  final bool inStock;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.inStock,
  });
}
```

### 3. Run the generator

```bash
dart run build_runner build --delete-conflicting-outputs
```

This writes `product.list_screen.dart`, `product.detail_screen.dart`,
`product.form_screen.dart`, `product.provider.dart`, `product.api_client.dart`
and `product.routes.dart` next to `product.dart`.

### 4. Register the routes

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'product.routes.dart';

final router = GoRouter(initialLocation: '/products', routes: $prefabRoutes);

void main() => runApp(
      ProviderScope(child: MaterialApp.router(routerConfig: router)),
    );
```

Generated API clients read a Dio instance from a provider named `dioProvider`.
Until the runtime package provides one ([PF-22](backlog/tasks)), declare it in
the entity's source file; see
[Configuring the HTTP client](docs/user_guide.md#configuring-the-http-client).

## Documentation

- [User guide](docs/user_guide.md): every annotation, field widget and
  validator, the generated files and routes, and the current limitations.
- [Backlog](backlog/tasks): planned and in-progress work.

## Development

Each package is tested on its own:

```bash
cd prefab_flutter_generator && dart pub get && dart test
```

```bash
cd prefab_flutter_widgets && flutter pub get && flutter test
```

CI (`.github/workflows/ci.yml`) runs `analyze --fatal-infos` and the tests for
all three packages.
