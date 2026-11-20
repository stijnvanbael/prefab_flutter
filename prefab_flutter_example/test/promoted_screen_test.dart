import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prefab_flutter_example/main.dart';
import 'package:prefab_flutter_example/mock_backend.dart';
import 'package:prefab_flutter_widgets/prefab_flutter_widgets.dart';

void main() {
  testWidgets('the generated routes show the promoted detail screen',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [prefabDioProvider.overrideWithValue(createMockDio())],
        child: const ExampleApp(initialLocation: '/products/1'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Product (hand-written)'), findsOneWidget);
  });
}
