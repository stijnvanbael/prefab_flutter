import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'models/product.routes.dart';

void main() {
  runApp(const ProviderScope(child: PrefabExampleApp()));
}

class PrefabExampleApp extends StatelessWidget {
  const PrefabExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Prefab Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      routerConfig: GoRouter(
        initialLocation: '/products',
        routes: $prefabRoutes,
      ),
    );
  }
}
