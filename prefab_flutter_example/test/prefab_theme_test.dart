import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:prefab_flutter_example/main.dart';
import 'package:prefab_flutter_example/mock_backend.dart';
import 'package:prefab_flutter_widgets/prefab_flutter_widgets.dart';

ThemeData _theme() => ThemeData(
      extensions: [
        PrefabTheme(
          emptyBuilder: (_) => const Center(child: Text('Nothing here')),
          errorBuilder: (_, error, __) => Center(child: Text('Oops: $error')),
          listPadding: const EdgeInsets.all(40),
        ),
      ],
    );

Future<void> _pump(WidgetTester tester, Dio dio) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [prefabDioProvider.overrideWithValue(dio)],
      child: ExampleApp(theme: _theme()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the generated list screen uses the custom empty state',
      (tester) async {
    await _pump(tester, createMockDio());
    expect(find.text('Keyboard'), findsOneWidget);
    expect(find.text('Nothing here'), findsNothing);

    await tester.enterText(find.byType(TextField), 'zzzz');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.text('Nothing here'), findsOneWidget);
    expect(find.text('No items found'), findsNothing);
  });

  testWidgets('the generated list screen uses the custom error state',
      (tester) async {
    final dio = Dio(BaseOptions(baseUrl: 'http://mock.local'))
      ..interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) => handler.reject(
          DioException(requestOptions: options, error: 'boom'),
        ),
      ));
    await _pump(tester, dio);
    expect(find.textContaining('Oops:'), findsOneWidget);
    expect(find.byWidgetPredicate((w) => w is Text && (w.data ?? '').startsWith('Error:')), findsNothing);
  });
}
