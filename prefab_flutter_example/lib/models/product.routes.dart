// GENERATED CODE - DO NOT MODIFY BY HAND
//
// **************************************************************************
// RoutesGenerator
// **************************************************************************

import 'package:go_router/go_router.dart';

import 'product.detail_screen.dart';
import 'product.list_screen.dart';
import 'product.form_screen.dart';

List<RouteBase> get $prefabRoutes => [
  GoRoute(
    path: '/products',
    builder: (context, state) => const ProductListScreen(),
    routes: [
      GoRoute(
        path: ':id',
        builder: (context, state) =>
            ProductDetailScreen(id: state.pathParameters['id']!),
        routes: [
          GoRoute(
            path: 'edit',
            builder: (context, state) =>
                ProductEditScreen(id: state.pathParameters['id']!),
          ),
        ],
      ),
      GoRoute(
        path: 'create',
        builder: (context, state) => const ProductCreateScreen(),
      ),
    ],
  ),
];
