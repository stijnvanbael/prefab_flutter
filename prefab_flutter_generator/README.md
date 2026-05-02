# prefab_flutter_generator

Code generator for [`prefab_flutter`](../prefab_flutter). Reads
`@View`-annotated Dart classes and emits six categories of source files:

| Builder factory       | Output extension      | Description                                         |
|-----------------------|-----------------------|-----------------------------------------------------|
| `detailScreenBuilder` | `.detail_screen.dart` | Read-only `{Entity}DetailScreen` ConsumerWidget     |
| `listScreenBuilder`   | `.list_screen.dart`   | `{Entity}ListScreen` with search, sort & pagination |
| `formScreenBuilder`   | `.form_screen.dart`   | Create & edit form screens                          |
| `providerBuilder`     | `.provider.dart`      | Riverpod providers (detail + list notifier)         |
| `apiClientBuilder`    | `.api_client.dart`    | Dio-backed API client                               |
| `routesBuilder`       | `.routes.dart`        | GoRouter TypedGoRoute declarations                  |

## Usage

Add to your app's `pubspec.yaml`:

```yaml
dependencies:
  prefab_flutter: ^0.1.0

dev_dependencies:
  build_runner: ^2.4.0
  prefab_flutter_generator: ^0.1.0
```

Annotate your entity:

```dart
import 'package:prefab_flutter/prefab_flutter.dart';

@View(title: 'Product', path: 'products')
@Update()
@Delete()
class Product {
  final int id;

  @FormField(label: 'Name', validators: [Validator.required])
  final String name;

  @FormField(label: 'Price')
  final double price;

  Product({required this.id, required this.name, required this.price});
}
```

Run the generator:

```bash
dart run build_runner build
```

This produces `product.detail_screen.dart` (and the other output files)
alongside `product.dart`.

## Running tests

```bash
cd prefab_flutter_generator
dart pub get
dart test
```
