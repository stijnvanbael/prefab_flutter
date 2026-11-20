import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:prefab_flutter_widgets/prefab_flutter_widgets.dart';

import 'mock_backend.dart';
import 'product.prefab.dart';
import 'reply.prefab.dart';
import 'review.prefab.dart';

GoRouter createRouter({String initialLocation = '/products'}) => GoRouter(
      initialLocation: initialLocation,
      routes: [...$productRoutes, ...$reviewRoutes, ...$replyRoutes],
    );

void main() => runApp(
      ProviderScope(
        overrides: [prefabDioProvider.overrideWithValue(createMockDio())],
        child: const ExampleApp(),
      ),
    );

class ExampleApp extends StatefulWidget {
  const ExampleApp({super.key, this.initialLocation = '/products', this.theme});

  final String initialLocation;

  /// Overrides the app theme (the tests use it to set a [PrefabTheme]).
  final ThemeData? theme;

  @override
  State<ExampleApp> createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  late final GoRouter _router =
      createRouter(initialLocation: widget.initialLocation);

  @override
  Widget build(BuildContext context) => MaterialApp.router(
        title: 'Prefab Flutter Example',
        theme: widget.theme ??
            ThemeData(
              extensions: const [
                // Generated screens read their layout from PrefabTheme.
                PrefabTheme(listPadding: EdgeInsets.symmetric(vertical: 8)),
              ],
            ),
        routerConfig: _router,
      );
}
