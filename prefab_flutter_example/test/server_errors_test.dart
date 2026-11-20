import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:prefab_flutter_example/main.dart';
import 'package:prefab_flutter_example/mock_backend.dart';
import 'package:prefab_flutter_widgets/prefab_flutter_widgets.dart';

Future<void> _pumpApp(WidgetTester tester, String location) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [prefabDioProvider.overrideWithValue(createMockDio())],
      child: ExampleApp(initialLocation: location),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _fill(WidgetTester tester, String name, String price) async {
  await tester.enterText(find.widgetWithText(TextFormField, 'Name'), name);
  await tester.enterText(
      find.widgetWithText(TextFormField, 'Price (EUR)'), price);
}

void main() {
  testWidgets('PF-51 a field error from the server appears under the field '
      'and disappears when the field is edited', (tester) async {
    await _pumpApp(tester, '/products/create');
    await _fill(tester, 'keyboard', '10');
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    expect(find.text('A product with this name already exists'),
        findsOneWidget);
    // The general message is shown above the form.
    expect(find.text('The product is invalid.'), findsOneWidget);
    // The form stays open.
    expect(find.text('Create'), findsWidgets);

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Name'), 'keyboard 2');
    await tester.pump();
    expect(find.text('A product with this name already exists'), findsNothing);
  });

  testWidgets('PF-51 errors for fields the form does not have appear above '
      'the form', (tester) async {
    await _pumpApp(tester, '/products/create');
    await _fill(tester, 'Server rack', '20000');
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    expect(find.text('Must not exceed 10000'), findsOneWidget);
    expect(find.text('warehouse: No capacity for this product'),
        findsOneWidget);
  });

  testWidgets('PF-51 the edit form shows server errors too', (tester) async {
    await _pumpApp(tester, '/products/2/edit');
    await tester.enterText(find.widgetWithText(TextFormField, 'Name'), 'Keyboard');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('A product with this name already exists'),
        findsOneWidget);
  });

  testWidgets('PF-51 a missing item shows a not-found state with a way back',
      (tester) async {
    // The review detail screen is generated (the product one is promoted).
    await _pumpApp(tester, '/products/2/reviews/999');
    expect(find.text('Not found'), findsOneWidget);
    await tester.tap(find.text('Back to list'));
    await tester.pumpAndSettle();
    expect(find.text('Sharp picture'), findsOneWidget);
  });

  testWidgets('PF-51 the edit screen of a missing item shows not-found',
      (tester) async {
    await _pumpApp(tester, '/products/999/edit');
    expect(find.text('Not found'), findsOneWidget);
  });
}
