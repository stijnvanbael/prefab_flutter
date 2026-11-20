import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:prefab_flutter_example/main.dart';
import 'package:prefab_flutter_example/mock_backend.dart';
import 'package:prefab_flutter_widgets/prefab_flutter_widgets.dart';

Future<void> _pumpApp(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        prefabDioProvider.overrideWithValue(createMockDio()),
        prefabBackendProvider.overrideWithValue(exampleBackend),
      ],
      child: const ExampleApp(initialLocation: '/products'),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('PF-55 filters the products list by enum, bool and text',
      (tester) async {
    await _pumpApp(tester);
    expect(find.byType(PrefabEnumFilter), findsOneWidget);
    expect(find.byType(PrefabBoolFilter), findsOneWidget);
    expect(find.byType(PrefabDateRangeFilter), findsOneWidget);
    expect(find.byType(PrefabTextFilter), findsOneWidget);

    // Enum chips.
    await tester.tap(find.widgetWithText(ChoiceChip, 'electronics'));
    await tester.pumpAndSettle();
    expect(find.text('Monitor'), findsOneWidget);
    expect(find.text('Keyboard'), findsNothing);

    // Tapping the selected chip clears the filter.
    await tester.tap(find.widgetWithText(ChoiceChip, 'electronics'));
    await tester.pumpAndSettle();
    expect(find.text('Keyboard'), findsOneWidget);

    // Bool chips.
    await tester.tap(find.widgetWithText(ChoiceChip, 'Yes'));
    await tester.pumpAndSettle();
    expect(find.text('Keyboard'), findsOneWidget);
    expect(find.text('Monitor'), findsNothing);
  });

  testWidgets('PF-55 text filter suggests values from the autocomplete endpoint',
      (tester) async {
    await _pumpApp(tester);
    await tester.enterText(
        find.descendant(
            of: find.byType(PrefabTextFilter),
            matching: find.byType(TextField)),
        'key');
    await tester.pumpAndSettle();
    // The suggestion is listed; choosing it applies the filter.
    await tester.tap(find.text('Keyboard').last);
    await tester.pumpAndSettle();
    expect(find.text('Monitor'), findsNothing);
  });
}
