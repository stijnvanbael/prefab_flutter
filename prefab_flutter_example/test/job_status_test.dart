import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:prefab_flutter_example/main.dart';
import 'package:prefab_flutter_example/mock_backend.dart';
import 'package:prefab_flutter_widgets/prefab_flutter_widgets.dart';

/// PF-57: the status of long-running server jobs (`Report`, `@JobStatus`).
///
/// A running job shows a progress indicator, which never settles, so the tests
/// advance the clock in steps with [_pumpFor] instead of `pumpAndSettle`. The
/// mock backend has no clock: every read of a running report moves its job one
/// step on, so polling is what finishes the job.

Future<MockBackendAdapter> _pumpApp(WidgetTester tester,
    {String location = '/reports', int pollsUntilDone = 2}) async {
  final backend = MockBackendAdapter()..pollsUntilDone = pollsUntilDone;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [prefabDioProvider.overrideWithValue(createMockDio(backend))],
      child: ExampleApp(initialLocation: location),
    ),
  );
  await _pumpFor(tester, const Duration(milliseconds: 500));
  return backend;
}

Future<void> _pumpFor(WidgetTester tester, Duration duration) async {
  const step = Duration(milliseconds: 100);
  for (var elapsed = Duration.zero; elapsed < duration; elapsed += step) {
    await tester.pump(step);
  }
}

/// Removes the app, which stops the polling timers.
Future<void> _unmount(WidgetTester tester) =>
    tester.pumpWidget(const SizedBox());

Finder _tile(String title) =>
    find.ancestor(of: find.text(title), matching: find.byType(ListTile));

Finder _inTile(String title, Finder matching) =>
    find.descendant(of: _tile(title), matching: matching);

Future<void> _openMenu(WidgetTester tester, String title) async {
  await tester.tap(
      _inTile(title, find.byType(PopupMenuButton<void>)));
  await _pumpFor(tester, const Duration(milliseconds: 500));
}

void main() {
  testWidgets('PF-57 AC#1 list items show running, done and failed',
      (tester) async {
    await _pumpApp(tester);

    expect(_inTile('Chapter quiz', find.byType(PrefabJobIndicator)),
        findsOneWidget);
    expect(_inTile('Chapter quiz', find.byType(CircularProgressIndicator)),
        findsOneWidget);
    expect(_inTile('Weekly summary', find.byIcon(Icons.check_circle)),
        findsOneWidget);
    expect(_inTile('Legacy import', find.byIcon(Icons.error)), findsOneWidget);
    await _unmount(tester);
  });

  testWidgets('PF-57 AC#2 the list refreshes until the job is final',
      (tester) async {
    final backend = await _pumpApp(tester, pollsUntilDone: 3);
    expect(backend.reportReads, 1);

    // The first poll (every 2 seconds) finds the job still running.
    await _pumpFor(tester, const Duration(milliseconds: 2300));
    expect(backend.reportReads, 2);
    expect(_inTile('Chapter quiz', find.byType(CircularProgressIndicator)),
        findsOneWidget);

    // The second poll finds it done; the indicator becomes a check mark.
    await _pumpFor(tester, const Duration(seconds: 2));
    expect(backend.reportReads, 3);
    expect(_inTile('Chapter quiz', find.byIcon(Icons.check_circle)),
        findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    // Nothing is running any more, so nothing is read any more.
    await _pumpFor(tester, const Duration(seconds: 10));
    expect(backend.reportReads, 3);
    await _unmount(tester);
  });

  testWidgets('PF-57 AC#1+2 the detail screen shows the banner and refreshes',
      (tester) async {
    // The list screen stays below the detail screen and reads the report too:
    // both read it once now and again at every poll.
    final backend =
        await _pumpApp(tester, location: '/reports/2', pollsUntilDone: 4);
    expect(find.byType(PrefabJobBanner), findsOneWidget);
    expect(find.text('Running'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(backend.reportReads, 2);

    await _pumpFor(tester, const Duration(milliseconds: 2300));
    expect(find.text('Done'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);

    // Once the list has seen the final job too, nothing is read any more.
    await _pumpFor(tester, const Duration(seconds: 4));
    final reads = backend.reportReads;
    await _pumpFor(tester, const Duration(seconds: 10));
    expect(backend.reportReads, reads, reason: 'a final job is not read again');
    await _unmount(tester);
  });

  testWidgets('PF-57 AC#3 a failed job shows the message of the server',
      (tester) async {
    await _pumpApp(tester, location: '/reports/3');
    expect(find.text('Failed'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(PrefabJobBanner),
        matching: find.text('The source file could not be parsed.'),
      ),
      findsOneWidget,
    );
    await _unmount(tester);
  });

  testWidgets('PF-57 AC#3 a job that fails while it runs ends failed '
      'with the message of the server', (tester) async {
    await _pumpApp(tester, location: '/reports/create');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Title'), 'This will fail');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Create'));
    await _pumpFor(tester, const Duration(seconds: 1));

    // The created report starts running; the status is not in the form.
    expect(_inTile('This will fail', find.byType(CircularProgressIndicator)),
        findsOneWidget);

    await _pumpFor(tester, const Duration(seconds: 3));
    expect(_inTile('This will fail', find.byIcon(Icons.error)), findsOneWidget);

    await tester.tap(find.text('This will fail'));
    await _pumpFor(tester, const Duration(seconds: 1));
    expect(find.text('Failed'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(PrefabJobBanner),
        matching: find.text('The report could not be generated.'),
      ),
      findsOneWidget,
    );
    await _unmount(tester);
  });

  testWidgets('PF-57 an operation that starts a job opens it, running',
      (tester) async {
    await _pumpApp(tester, pollsUntilDone: 4);
    await _openMenu(tester, 'Weekly summary');
    await tester.tap(find.text('Regenerate'));
    await _pumpFor(tester, const Duration(seconds: 1));

    // The detail screen of the report is open and shows the running job.
    expect(find.byType(PrefabJobBanner), findsOneWidget);
    expect(find.text('Running'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);

    // ... and follows it to the end.
    await _pumpFor(tester, const Duration(milliseconds: 2300));
    expect(find.text('Done'), findsOneWidget);
    await _unmount(tester);
  });
}
