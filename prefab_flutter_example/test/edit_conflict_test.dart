import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:prefab_flutter_example/main.dart';
import 'package:prefab_flutter_example/mock_backend.dart';
import 'package:prefab_flutter_widgets/prefab_flutter_widgets.dart';

Future<void> _pumpApp(WidgetTester tester, Dio dio, String location) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [prefabDioProvider.overrideWithValue(dio)],
      child: ExampleApp(initialLocation: location),
    ),
  );
  await tester.pumpAndSettle();
}

/// Calls the mock backend directly, outside the test's fake clock.
Future<Map<String, dynamic>> _get(WidgetTester tester, Dio dio) async =>
    (await tester.runAsync(() => dio.get('/products/2')))!.data
        as Map<String, dynamic>;

Future<void> _someoneElseSaves(WidgetTester tester, Dio dio) async {
  final current = await _get(tester, dio);
  await tester.runAsync(
    () => dio.put('/products/2', data: {...current, 'name': 'Monitor (other)'}),
  );
}

void main() {
  testWidgets('PF-52 the edit form sends the loaded version and the item '
      'gets the next one', (tester) async {
    final dio = createMockDio();
    await _pumpApp(tester, dio, '/products/2/edit');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Name'), 'Monitor 4K');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final saved = await _get(tester, dio);
    expect(saved['name'], 'Monitor 4K');
    expect(saved['version'], 1);
  });

  testWidgets('PF-52 the version is not a form field', (tester) async {
    await _pumpApp(tester, createMockDio(), '/products/2/edit');
    expect(find.widgetWithText(TextFormField, 'Version'), findsNothing);
  });

  testWidgets('PF-52 a stale version opens the conflict dialog; reload '
      'refills the form with the latest version', (tester) async {
    final dio = createMockDio();
    await _pumpApp(tester, dio, '/products/2/edit');

    // Someone else saves the product first.
    await _someoneElseSaves(tester, dio);

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Name'), 'Mine');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Changed by someone else'), findsOneWidget);

    await tester.tap(find.text('Reload'));
    await tester.pumpAndSettle();
    expect(find.text('Changed by someone else'), findsNothing);
    expect(find.widgetWithText(TextFormField, 'Monitor (other)'),
        findsOneWidget);

    // The reloaded form carries the new version, so saving works now.
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Name'), 'Merged');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect((await _get(tester, dio))['name'], 'Merged');
  });

  testWidgets('PF-52 cancel keeps the input in the form', (tester) async {
    final dio = createMockDio();
    await _pumpApp(tester, dio, '/products/2/edit');
    await _someoneElseSaves(tester, dio);

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Name'), 'Mine');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Changed by someone else'), findsNothing);
    expect(find.widgetWithText(TextFormField, 'Mine'), findsOneWidget);
    expect((await _get(tester, dio))['name'], 'Monitor (other)');
  });
}
