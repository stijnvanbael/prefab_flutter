# prefab_flutter_generator

Code generator for [`prefab_flutter`](https://pub.dev/packages/prefab_flutter). Reads
`@View`-annotated Dart classes and emits **one** library per source file:

| Builder factory | Output extension | Description |
|-----------------|------------------|-------------|
| `prefabBuilder` | `.prefab.dart`   | Detail, list and form screens, Riverpod providers, Dio API client and GoRouter routes for every `@View` class in the file |

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
  final int? id;

  @Field(label: 'Name', form: FormOptions(validators: [Validator.required]))
  final String name;

  @Field(label: 'Price')
  final double price;

  Product({this.id, required this.name, required this.price});
}
```

Run the generator:

```bash
dart run build_runner build
```

This produces `product.prefab.dart` alongside `product.dart`.

## Running tests

```bash
cd prefab_flutter_generator
dart pub get
dart test
```
