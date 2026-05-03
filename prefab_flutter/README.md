# prefab_flutter

Annotations for the `prefab_flutter` code generator.

Apply these annotations to your Dart entity classes and run `build_runner` to generate list screens, detail screens, form screens, Riverpod providers, Dio API clients, and GoRouter routes.

## Annotations

| Annotation | Description |
|---|---|
| `@View` | Marks a class as a prefab entity and drives all code generation |
| `@Update` | Adds an **Edit** action to the generated detail screen |
| `@Delete` | Adds a **Delete** action backed by a confirmation dialog |
| `@FormField` | Marks a field for inclusion in generated form and detail screens |
| `@Parent` | Marks a field as a reference to the parent entity (nested resource) |

## Enums

| Enum | Values |
|---|---|
| `Validator` | `required`, `email`, `positiveNumber`, `url` |
| `FieldWidget` | `auto`, `multilineText`, `password`, `datePicker`, `dropdown`, `toggle` |

## Usage

Add to your app's `pubspec.yaml`:

```yaml
dependencies:
  prefab_flutter: ^0.1.0

dev_dependencies:
  build_runner: ^2.4.0
  prefab_flutter_generator: ^0.1.0
```

Annotate your entity class:

```dart
import 'package:prefab_flutter/prefab_flutter.dart';

@View(title: 'Product', path: 'products')
@Update()
@Delete()
class Product {
  final int id;

  @FormField(label: 'Name', validators: [Validator.required])
  final String name;

  @FormField(label: 'Price', validators: [Validator.positiveNumber])
  final double price;

  Product({required this.id, required this.name, required this.price});
}
```

Run the generator:

```bash
dart run build_runner build
```

## Related packages

| Package | Description |
|---|---|
| [`prefab_flutter_generator`](https://pub.dev/packages/prefab_flutter_generator) | `build_runner` code generator |
| [`prefab_flutter_widgets`](https://pub.dev/packages/prefab_flutter_widgets) | Runtime Flutter widgets used by generated code |
