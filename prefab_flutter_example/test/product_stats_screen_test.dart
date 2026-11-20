import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prefab_flutter_example/main.dart';
import 'package:prefab_flutter_example/mock_backend.dart';
import 'package:prefab_flutter_widgets/prefab_flutter_widgets.dart';

void main() {
  testWidgets('PF-48 the hand-written statistics screen shows backend data',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [prefabDioProvider.overrideWithValue(createMockDio())],
        child: const ExampleApp(initialLocation: '/products/2'),
      ),
    );
    await tester.pumpAndSettle();

    // Open it from the (promoted) detail screen.
    await tester.tap(find.text('Statistics'));
    await tester.pumpAndSettle();

    expect(find.text('Product statistics'), findsOneWidget);
    expect(find.byType(PrefabBreadcrumbBar), findsOneWidget);
    expect(find.text('Monitor'), findsWidgets);
    expect(find.text('Price: 199.00 EUR'), findsOneWidget);
    expect(find.text('Reviews: 1'), findsOneWidget);
    expect(find.text('Average rating: 4.0'), findsOneWidget);
  });
}
