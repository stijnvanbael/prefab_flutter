import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:prefab_flutter_example/main.dart';
import 'package:prefab_flutter_example/mock_backend.dart';
import 'package:prefab_flutter_widgets/prefab_flutter_widgets.dart';

/// PF-54: named operations of Product (`@Update(path: ...)`).
Future<void> _pumpApp(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [prefabDioProvider.overrideWithValue(createMockDio())],
      child: const ExampleApp(initialLocation: '/products'),
    ),
  );
  await tester.pumpAndSettle();
}

/// The save button of the parameter form (the app bar title has the same text).
final _save = find.descendant(of: find.byType(Form), matching: find.text('Discount'));

Future<void> _openMenu(WidgetTester tester, String product) async {
  final tile = find.ancestor(
      of: find.text(product), matching: find.byType(ListTile));
  await tester.tap(find.descendant(
      of: tile, matching: find.byType(PopupMenuButton<void>)));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('PF-54 an operation without parameters asks first, then '
      'refreshes the list', (tester) async {
    await _pumpApp(tester);

    await _openMenu(tester, 'Keyboard');
    await tester.tap(find.text('Discontinue'));
    await tester.pumpAndSettle();
    expect(find.text('Mark this product as out of stock?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Discontinue'));
    await tester.pumpAndSettle();

    // The mock now answers 409 for a second attempt: the problem is shown.
    await _openMenu(tester, 'Keyboard');
    await tester.tap(find.text('Discontinue'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Discontinue'));
    await tester.pumpAndSettle();
    expect(find.text('The product is already out of stock.'), findsOneWidget);
  });

  testWidgets('PF-54 an operation with parameters opens a form with the '
      'validators and the server errors', (tester) async {
    await _pumpApp(tester);
    await _openMenu(tester, 'Monitor');
    await tester.tap(find.text('Discount'));
    await tester.pumpAndSettle();

    // The form has the fields of DiscountParameters.
    expect(find.widgetWithText(TextFormField, 'Percent'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Reason'), findsOneWidget);

    // Validator.max(90) is checked on the client.
    await tester.enterText(find.widgetWithText(TextFormField, 'Percent'), '95');
    await tester.tap(_save);
    await tester.pumpAndSettle();
    expect(find.text('Must be at most 90'), findsOneWidget);

    // The server rejects 60 percent on an expensive product, under the field.
    await tester.enterText(find.widgetWithText(TextFormField, 'Percent'), '60');
    await tester.tap(_save);
    await tester.pumpAndSettle();
    expect(find.text('Expensive products take at most 50 percent'),
        findsOneWidget);

    // 20 percent works: the form closes and the list shows the new price.
    await tester.enterText(find.widgetWithText(TextFormField, 'Percent'), '20');
    await tester.tap(_save);
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextFormField, 'Percent'), findsNothing);
    expect(find.textContaining('159.2'), findsOneWidget);
  });
}
