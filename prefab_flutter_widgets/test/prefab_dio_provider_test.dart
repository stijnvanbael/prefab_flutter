import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prefab_flutter_widgets/prefab_flutter_widgets.dart';

void main() {
  test('throws a descriptive error unless overridden', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(
      () => container.read(prefabDioProvider),
      throwsA(predicate((e) => e.toString().contains('prefabDioProvider'))),
    );
  });

  test('returns the overridden instance', () {
    final dio = Dio();
    final container = ProviderContainer(
        overrides: [prefabDioProvider.overrideWithValue(dio)]);
    addTearDown(container.dispose);
    expect(container.read(prefabDioProvider), same(dio));
  });
}
