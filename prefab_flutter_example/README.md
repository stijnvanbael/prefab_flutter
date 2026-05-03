# prefab_flutter_example

A complete Flutter example that demonstrates the **prefab_flutter** code generator
with a full **Products CRUD flow** backed by an in-memory mock.

## What it shows

| Feature | Location |
|---------|----------|
| List screen with search & pagination support | `ProductListScreen` |
| Detail screen with Edit / Delete actions | `ProductDetailScreen` |
| Create & Edit forms with validation | `ProductCreateScreen`, `ProductEditScreen` |
| Riverpod providers wired to a Dio API client | `product.provider.dart` |
| GoRouter route definitions | `product.routes.dart` |

The in-memory mock (`dio_provider.dart`) intercepts all HTTP calls and stores
`Product` objects in memory, so the app works fully offline.

## Prerequisites

| Tool | Version |
|------|---------|
| Flutter SDK | ≥ 3.10 |
| Dart SDK | ≥ 3.0 |

## Running the example

```bash
# From the repo root
cd prefab_flutter_example
flutter pub get
flutter run
```

The app starts on the Products list screen. Use the **+** button to create a
product, tap an item to see its detail screen, and use the edit / delete icons
in the AppBar.

## Regenerating the generated files

The generated `*.list_screen.dart`, `*.detail_screen.dart`, `*.form_screen.dart`,
`*.provider.dart`, `*.api_client.dart` and `*.routes.dart` files are committed for
convenience. To regenerate them from scratch after modifying `product.dart`:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## Project structure

```
lib/
├── main.dart                         # App entry point
└── models/
    ├── product.dart                  # Entity annotated with @View, @Update, @Delete
    ├── dio_provider.dart             # dioProvider (in-memory mock)
    ├── product.api_client.dart       # GENERATED — Dio-backed API client
    ├── product.provider.dart         # GENERATED — Riverpod providers & notifier
    ├── product.list_screen.dart      # GENERATED — list screen with FAB
    ├── product.detail_screen.dart    # GENERATED — read-only detail screen
    ├── product.form_screen.dart      # GENERATED — create & edit forms
    └── product.routes.dart           # GENERATED — GoRouter route definitions
```
