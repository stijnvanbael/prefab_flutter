import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prefab_flutter_example/main.dart';
import 'package:prefab_flutter_example/mock_backend.dart';
import 'package:prefab_flutter_widgets/prefab_flutter_widgets.dart';

Future<MockBackendAdapter> _pumpApp(WidgetTester tester,
    {String location = '/products'}) async {
  final backend = MockBackendAdapter();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [prefabDioProvider.overrideWithValue(createMockDio(backend))],
      child: ExampleApp(initialLocation: location),
    ),
  );
  await tester.pumpAndSettle();
  return backend;
}

void main() {
  testWidgets('PF-56 the product list follows live events', (tester) async {
    final backend = await _pumpApp(tester);
    expect(find.text('Mouse'), findsNothing);

    backend.emitProductEvent('created', {
      'id': 50,
      'name': 'Mouse',
      'price': 19.5,
      'inStock': true,
      'createdAt': '2024-05-01T09:00:00.000',
    });
    await tester.pumpAndSettle();
    expect(find.text('Mouse'), findsOneWidget);

    backend.emitProductEvent('updated', {
      'id': 50,
      'name': 'Trackball',
      'price': 19.5,
      'inStock': true,
      'createdAt': '2024-05-01T09:00:00.000',
    });
    await tester.pumpAndSettle();
    expect(find.text('Mouse'), findsNothing);
    expect(find.text('Trackball'), findsOneWidget);

    backend.emitProductEvent('deleted', {'id': 50});
    await tester.pumpAndSettle();
    expect(find.text('Trackball'), findsNothing);
    expect(find.text('Keyboard'), findsOneWidget);
  });

  testWidgets('PF-56 a created product during a search shows the banner',
      (tester) async {
    final backend = await _pumpApp(tester);
    await tester.enterText(
        find.descendant(
            of: find.byType(PrefabSearchBar),
            matching: find.byType(TextField)),
        'key');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.byType(PrefabNewItemsBanner), findsNothing);

    backend.emitProductEvent('created', {
      'id': 51,
      'name': 'Keycap',
      'price': 5.0,
      'inStock': true,
      'createdAt': '2024-05-01T09:00:00.000',
    });
    await tester.pumpAndSettle();
    expect(find.byType(PrefabNewItemsBanner), findsOneWidget);
    expect(find.text('1 new item'), findsOneWidget);
    expect(find.text('Keycap'), findsNothing);
  });

  testWidgets('PF-56 the detail screen follows live updates', (tester) async {
    final backend = await _pumpApp(tester, location: '/products/2');
    expect(find.text('Monitor'), findsWidgets);

    backend.emitProductEvent('updated', {
      'id': 2,
      'name': 'Display',
      'price': 199.0,
      'inStock': true,
      'createdAt': '2024-05-01T09:00:00.000',
      'category': 'electronics',
    });
    await tester.pumpAndSettle();
    expect(find.text('Display'), findsWidgets);
    expect(find.text('Monitor'), findsNothing);
  });

  testWidgets('PF-74 the list catches up after the stream reconnects',
      (tester) async {
    final backend = await _pumpApp(tester);
    expect(find.text('Keyboard'), findsOneWidget);

    backend.dropProductStreams();
    backend.changeProductSilently(1, {'name': 'Mechanical keyboard'});
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.text('Mechanical keyboard'), findsOneWidget);
    expect(find.text('Keyboard'), findsNothing);
  });

  testWidgets('PF-74 the detail screen catches up after the stream reconnects',
      (tester) async {
    final backend = await _pumpApp(tester, location: '/products/2');
    expect(find.text('Monitor'), findsWidgets);

    backend.dropProductStreams();
    backend.changeProductSilently(2, {'name': 'Display'});
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.text('Display'), findsWidgets);
    expect(find.text('Monitor'), findsNothing);
  });
}
