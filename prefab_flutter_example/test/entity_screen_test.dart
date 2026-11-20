import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prefab_flutter_example/main.dart';
import 'package:prefab_flutter_example/mock_backend.dart';
import 'package:prefab_flutter_widgets/prefab_flutter_widgets.dart';

void main() {
  testWidgets('PF-45 the detail screen links to the hand-written child screen',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [prefabDioProvider.overrideWithValue(createMockDio())],
        child: const ExampleApp(initialLocation: '/products/2/reviews/10'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Summary'));
    await tester.pumpAndSettle();
    expect(find.text('Review summary'), findsOneWidget);
    expect(find.byType(PrefabBreadcrumbBar), findsOneWidget);
  });
}
