# prefab_flutter

Annotations for the `prefab_flutter` code generator.

Apply these annotations to your Dart entity classes and run `build_runner` to generate list screens, detail screens, form screens, Riverpod providers, Dio API clients, and GoRouter routes.

## Annotations

| Annotation | Description |
|---|---|
| `@View` | Marks a class as a prefab entity and drives all code generation |
| `@Update` | Adds an **Edit** action to the generated detail screen |
| `@Delete` | Adds a **Delete** action backed by a confirmation dialog |
| `@Field` | Marks a field for inclusion in generated form and detail screens |
| `@Parent(Type)` | Marks a field as a reference to the parent entity `Type` (nested resource) |
| `@Id` | Marks the entity's identifier field (defaults to a field named `id`) |

## Enums

| Enum | Values |
|---|---|
| `Validator` | `required`, `email`, `url`, `positive`, `nonNegative`, `min(n)`, `max(n)`, `minLength(n)`, `maxLength(n)`, `pattern(regex)` |
| `FieldWidget` | `auto`, `multilineText`, `password`, `datePicker`, `timePicker`, `dateTimePicker`, `dropdown`, `toggle` |

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
  final int? id;

  @Field(label: 'Name', form: FormOptions(validators: [Validator.required]))
  final String name;

  @Field(label: 'Price', form: FormOptions(validators: [Validator.positive]))
  final double price;

  Product({this.id, required this.name, required this.price});
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
