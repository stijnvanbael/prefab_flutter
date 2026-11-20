import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:prefab_flutter_widgets/prefab_flutter_widgets.dart';

void main() {
  Future<bool?> open(WidgetTester tester, String button) async {
    bool? result;
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () async =>
              result = await showPrefabConflictDialog(context),
          child: const Text('open'),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Changed by someone else'), findsOneWidget);
    await tester.tap(find.text(button));
    await tester.pumpAndSettle();
    return result;
  }

  testWidgets('Reload returns true (PF-52)', (tester) async {
    expect(await open(tester, 'Reload'), isTrue);
  });

  testWidgets('Cancel returns false (PF-52)', (tester) async {
    expect(await open(tester, 'Cancel'), isFalse);
  });
}
