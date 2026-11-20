import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:prefab_flutter_widgets/prefab_flutter_widgets.dart';

void main() {
  testWidgets('of() falls back to the defaults without an extension',
      (tester) async {
    late PrefabTheme theme;
    await tester.pumpWidget(MaterialApp(
      home: Builder(builder: (context) {
        theme = PrefabTheme.of(context);
        return const SizedBox();
      }),
    ));
    expect(theme.detailPadding, const EdgeInsets.all(16));
    expect(theme.listPadding, EdgeInsets.zero);
  });

  testWidgets('of() returns the extension set in ThemeData', (tester) async {
    late PrefabTheme theme;
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(extensions: const [
        PrefabTheme(formPadding: EdgeInsets.all(2)),
      ]),
      home: Builder(builder: (context) {
        theme = PrefabTheme.of(context);
        return const SizedBox();
      }),
    ));
    expect(theme.formPadding, const EdgeInsets.all(2));
  });

  testWidgets('default builders render today\'s widgets', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(builder: (context) {
          const t = PrefabTheme();
          return Column(children: [
            t.emptyBuilder(context),
            t.errorBuilder(context, 'bad', null),
            t.detailFieldBuilder(context, 'Name', const Text('Ann')),
            t.saveButtonBuilder(context, 'Save', () {}, false),
          ]);
        }),
      ),
    ));
    expect(find.text('No items found'), findsOneWidget);
    expect(find.text('Error: bad'), findsOneWidget);
    expect(find.text('Name'), findsOneWidget);
    expect(find.text('Ann'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);
  });

  testWidgets('default list item builder renders a ListTile with actions',
      (tester) async {
    var taps = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(builder: (context) {
          return const PrefabTheme().listItemBuilder(
            context,
            title: const Text('Keyboard'),
            subtitle: const Text('49'),
            trailing: null,
            actions: const [
              PopupMenuItem<void>(child: Text('Send')),
            ],
            onTap: () => taps++,
          );
        }),
      ),
    ));
    expect(find.byType(ListTile), findsOneWidget);
    await tester.tap(find.text('Keyboard'));
    expect(taps, 1);
    await tester.tap(find.byType(PopupMenuButton<void>));
    await tester.pumpAndSettle();
    expect(find.text('Send'), findsOneWidget);
  });

  test('copyWith replaces only the given values', () {
    const base = PrefabTheme();
    final copy = base.copyWith(formPadding: const EdgeInsets.all(3));
    expect(copy.formPadding, const EdgeInsets.all(3));
    expect(copy.detailPadding, base.detailPadding);
    expect(copy.emptyBuilder, base.emptyBuilder);
  });

  test('lerp interpolates paddings', () {
    const a = PrefabTheme(listPadding: EdgeInsets.all(0));
    const b = PrefabTheme(listPadding: EdgeInsets.all(10));
    expect(a.lerp(b, 0.5).listPadding, const EdgeInsets.all(5));
    expect(a.lerp(null, 0.5), a);
  });
}
