[← User guide](../user_guide.md)

# How it works

1. You annotate a plain Dart class with `@View` and its fields with
   `@Field`.
2. `build_runner` runs the Prefab builder over every library that contains a
   `@View` class and writes one `.prefab.dart` file next to the source file
   (see [Generated files](generated-files.md#generated-files)).
3. You register the generated routes with GoRouter and wrap the app in a
   Riverpod `ProviderScope`.

The generated code depends on `flutter_riverpod`, `go_router`, `dio`, `material_ui` (Flutter 3.47+) and
`prefab_flutter_widgets`, so your app must depend on them too.
