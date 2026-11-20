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
    await tester.enterText(find.descendant(of: find.byType(PrefabSearchBar), matching: find.byType(TextField)), 'mon');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.text('Monitor'), findsOneWidget);
    expect(find.text('Keyboard'), findsNothing);

    // Clearing the search brings everything back; sort descending by name.
    await tester.enterText(find.descendant(of: find.byType(PrefabSearchBar), matching: find.byType(TextField)), '');
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

  testWidgets('PF-44 hand-written actions on list items and the list',
      (tester) async {
    await _pumpApp(tester);
    expect(find.text('Keyboard'), findsOneWidget);

    // Item action in the trailing menu of the first row.
    await tester.tap(find.byType(PopupMenuButton<void>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Duplicate'));
    await tester.pumpAndSettle();
    expect(find.text('Keyboard (copy)'), findsOneWidget);

    // AppBar action of the list.
    await tester.tap(find.byTooltip('Refresh'));
    await tester.pumpAndSettle();
    expect(find.text('Keyboard (copy)'), findsOneWidget);
  });

  testWidgets('PF-44 hand-written action on a detail screen', (tester) async {
    await _pumpApp(tester, location: '/products/2/reviews/10');
    await tester.tap(find.byTooltip('Show comment'));
    await tester.pumpAndSettle();
    expect(find.text('Sharp picture'), findsWidgets);
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

  testWidgets('three-level nesting shows breadcrumbs back to the ancestors',
      (tester) async {
    await _pumpApp(tester, location: '/products/2/reviews/10/replies');
    expect(find.text('Agreed'), findsOneWidget);
    expect(find.byType(PrefabBreadcrumbBar), findsOneWidget);
    // Ancestors are labelled from their detail providers.
    expect(find.text('Monitor'), findsOneWidget);
    expect(find.text('Sharp picture'), findsOneWidget);

    // Opening a reply keeps the breadcrumb; tapping an ancestor jumps back.
    await tester.tap(find.text('Agreed'));
    await tester.pumpAndSettle();
    expect(find.byType(PrefabBreadcrumbBar), findsOneWidget);
    await tester.tap(find.text('Sharp picture'));
    await tester.pumpAndSettle();
    expect(find.text('Comment'), findsOneWidget);
    expect(find.byType(PrefabBreadcrumbBar), findsNothing);
  });
}
