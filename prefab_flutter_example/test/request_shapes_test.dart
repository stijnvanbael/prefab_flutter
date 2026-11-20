import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:prefab_flutter_example/main.dart';
import 'package:prefab_flutter_example/mock_backend.dart';
import 'package:prefab_flutter_widgets/prefab_flutter_widgets.dart';

/// PF-53: the create and the update request carry only their fields.
void main() {
  testWidgets('create and update send only the fields of their form',
      (tester) async {
    final bodies = <String, Map<String, dynamic>>{};
    final dio = createMockDio()
      ..interceptors.add(InterceptorsWrapper(onRequest: (o, handler) {
        if (o.data is Map && o.path == '/products' ||
            o.method == 'PUT' && o.data is Map) {
          bodies[o.method] = Map<String, dynamic>.from(o.data as Map);
        }
        handler.next(o);
      }));
    await tester.pumpWidget(ProviderScope(
      overrides: [prefabDioProvider.overrideWithValue(dio)],
      child: const ExampleApp(initialLocation: '/products'),
    ));
    await tester.pumpAndSettle();

    // Create: the SKU is in the form, the creation time is not.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextFormField, 'SKU'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Created at'), findsNothing);
    await tester.enterText(find.widgetWithText(TextFormField, 'Name'), 'Mouse');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Price (EUR)'), '19.5');
    await tester.enterText(find.widgetWithText(TextFormField, 'SKU'), 'M-1');
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    final created = bodies['POST']!;
    expect(created['sku'], 'M-1');
    expect(created.containsKey('id'), isFalse);
    expect(created.containsKey('createdAt'), isFalse);
    expect(jsonEncode(created), isNot(contains('1970')));

    // Edit: the SKU is gone from the form and from the body.
    await tester.tap(find.text('Mouse'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Edit'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextFormField, 'SKU'), findsNothing);
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final updated = bodies['PUT']!;
    expect(updated.containsKey('sku'), isFalse);
    expect(updated.containsKey('createdAt'), isFalse);
    expect(updated['name'], 'Mouse');
  });
}
