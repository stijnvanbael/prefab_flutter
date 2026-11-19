import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prefab_flutter_example/main.dart';
import 'package:prefab_flutter_example/mock_backend.dart';
import 'package:prefab_flutter_widgets/prefab_flutter_widgets.dart';

Future<void> _pumpApp(WidgetTester tester,
    {String location = '/products'}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [prefabDioProvider.overrideWithValue(createMockDio())],
      child: ExampleApp(initialLocation: location),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows the products list', (tester) async {
    await _pumpApp(tester);
    expect(find.text('Keyboard'), findsOneWidget);
    expect(find.text('Monitor'), findsOneWidget);
  });

  testWidgets('searches and sorts the products list', (tester) async {
    await _pumpApp(tester);
    expect(find.byType(PrefabSearchBar), findsOneWidget);
    expect(find.byType(PrefabPaginationBar), findsOneWidget);

    // Search is sent to the server (debounced) and filters the list.
    await tester.enterText(find.byType(TextField), 'mon');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.text('Monitor'), findsOneWidget);
    expect(find.text('Keyboard'), findsNothing);

    // Clearing the search brings everything back; sort descending by name.
    await tester.enterText(find.byType(TextField), '');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Sort'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Name \u2193'));
    await tester.pumpAndSettle();
    final monitor = tester.getTopLeft(find.text('Monitor')).dy;
    final keyboard = tester.getTopLeft(find.text('Keyboard')).dy;
    expect(monitor, lessThan(keyboard));
  });

  testWidgets('create, edit and delete a product', (tester) async {
    await _pumpApp(tester);

    // Create
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Name'), 'Mouse');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Price (EUR)'), '19.5');
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();
    expect(find.text('Mouse'), findsOneWidget);

    // Edit
    await tester.tap(find.text('Mouse'));
    await tester.pumpAndSettle();
    expect(find.text('19.5'), findsOneWidget);
    await tester.tap(find.byTooltip('Edit'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Name'), 'Trackball');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Trackball'), findsOneWidget);
    expect(find.text('Mouse'), findsNothing);

    // Delete
    await tester.tap(find.text('Trackball'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete').last);
    await tester.pumpAndSettle();
    expect(find.text('Trackball'), findsNothing);
    expect(find.text('Keyboard'), findsOneWidget);
  });

  testWidgets('create and edit a nested review', (tester) async {
    await _pumpApp(tester, location: '/products/1/reviews');
    expect(find.text('No items found'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Comment'), 'Great');
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();
    expect(find.text('Great'), findsOneWidget);

    await tester.tap(find.text('Great'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Edit'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Comment'), 'Excellent');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Excellent'), findsOneWidget);
  });
}
