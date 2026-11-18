import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The [Dio] instance used by every generated `{Entity}ApiClientProvider`.
///
/// It has no default: override it in your root `ProviderScope` to configure the
/// base URL, authentication and interceptors in one place:
///
/// ```dart
/// ProviderScope(
///   overrides: [
///     prefabDioProvider.overrideWithValue(
///       Dio(BaseOptions(baseUrl: 'https://api.example.com')),
///     ),
///   ],
///   child: const MyApp(),
/// );
/// ```
final prefabDioProvider = Provider<Dio>(
  (ref) => throw UnimplementedError(
    'prefabDioProvider has not been configured. Override it in your '
    'ProviderScope, e.g. ProviderScope(overrides: [prefabDioProvider.'
    "overrideWithValue(Dio(BaseOptions(baseUrl: 'https://api.example.com')))"
    ']).',
  ),
);
