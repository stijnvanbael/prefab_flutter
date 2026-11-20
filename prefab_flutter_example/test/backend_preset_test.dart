import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prefab_flutter_example/main.dart';
import 'package:prefab_flutter_example/mock_backend.dart';
import 'package:prefab_flutter_widgets/prefab_flutter_widgets.dart';

void main() {
  testWidgets('the app runs against the explicit Prefab preset',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          prefabDioProvider.overrideWithValue(createMockDio()),
          prefabBackendProvider.overrideWithValue(exampleBackend),
        ],
        child: const ExampleApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Keyboard'), findsOneWidget);
    expect(find.text('Monitor'), findsOneWidget);
  });
}
