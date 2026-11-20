import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:prefab_flutter_widgets/prefab_flutter_widgets.dart';

void main() {
  Future<BuildContext> pump(WidgetTester tester) async {
    late BuildContext context;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(builder: (c) {
          context = c;
          return const SizedBox();
        }),
      ),
    ));
    return context;
  }

  testWidgets('PF-54 runs at once without a confirmation', (tester) async {
    final context = await pump(tester);
    var ran = false;
    final result = await runPrefabOperation(
      context: context,
      backend: const PrefabBackend(),
      label: 'Send',
      run: () async => ran = true,
    );
    expect(result, isTrue);
    expect(ran, isTrue);
  });

  testWidgets('PF-54 does not run when the confirmation is cancelled',
      (tester) async {
    final context = await pump(tester);
    var ran = false;
    final future = runPrefabOperation(
      context: context,
      backend: const PrefabBackend(),
      label: 'Send',
      confirm: 'Send it?',
      run: () async => ran = true,
    );
    await tester.pumpAndSettle();
    expect(find.text('Send it?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(await future, isFalse);
    expect(ran, isFalse);
  });

  testWidgets('PF-54 shows the Problem Details message of a failure',
      (tester) async {
    final context = await pump(tester);
    final future = runPrefabOperation(
      context: context,
      backend: const PrefabBackend(),
      label: 'Send',
      confirm: 'Send it?',
      run: () async => throw DioException(
        requestOptions: RequestOptions(),
        response: Response(
          requestOptions: RequestOptions(),
          statusCode: 409,
          data: {'detail': 'Already sent'},
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Send'));
    await tester.pumpAndSettle();
    expect(await future, isFalse);
    expect(find.text('Already sent'), findsOneWidget);
  });

  test('PF-54 the Prefab preset posts the parameters as the body', () {
    const backend = PrefabBackend();
    expect(backend.operationMethod, 'POST');
    expect(backend.operationBody({'a': 1}), {'a': 1});
    expect(backend.operationBody(null), isNull);
  });
}
