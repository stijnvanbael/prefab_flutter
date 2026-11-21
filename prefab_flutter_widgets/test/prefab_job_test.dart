import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:prefab_flutter_widgets/prefab_flutter_widgets.dart';

const _interval = Duration(seconds: 3);

/// Cancels [subscription]. The future of `cancel` only completes while the
/// test clock runs, so it is not awaited directly.
Future<void> _cancel(WidgetTester tester, StreamSubscription<Object?> s) async {
  unawaited(s.cancel());
  await tester.pump();
}

void main() {
  group('PF-57 PrefabJobPoller', () {
    testWidgets('refreshes every interval while a job runs and then stops',
        (tester) async {
      var running = true;
      var refreshes = 0;
      final poller = PrefabJobPoller(
        interval: _interval,
        isRunning: () => running,
        refresh: () async => refreshes++,
      );
      poller.check();
      await tester.pump(_interval);
      expect(refreshes, 1);
      await tester.pump(_interval);
      expect(refreshes, 2);

      running = false;
      await tester.pump(_interval);
      expect(refreshes, 3, reason: 'the refresh that finds the job final');
      await tester.pump(_interval * 3);
      expect(refreshes, 3, reason: 'no job runs, so nothing is scheduled');
    });

    testWidgets('does nothing when no job runs', (tester) async {
      var refreshes = 0;
      final poller = PrefabJobPoller(
        interval: _interval,
        isRunning: () => false,
        refresh: () async => refreshes++,
      );
      poller.check();
      await tester.pump(_interval * 2);
      expect(refreshes, 0);
    });

    testWidgets('schedules one refresh however often it is checked',
        (tester) async {
      var refreshes = 0;
      var running = true;
      final poller = PrefabJobPoller(
        interval: _interval,
        isRunning: () => running,
        refresh: () async {
          refreshes++;
          running = false;
        },
      );
      poller
        ..check()
        ..check()
        ..check();
      await tester.pump(_interval);
      expect(refreshes, 1);
    });

    testWidgets('a failing refresh is ignored and tried again',
        (tester) async {
      var attempts = 0;
      var running = true;
      final poller = PrefabJobPoller(
        interval: _interval,
        isRunning: () => running,
        refresh: () async {
          attempts++;
          if (attempts == 1) throw StateError('offline');
          running = false;
        },
      );
      poller.check();
      await tester.pump(_interval);
      expect(attempts, 1);
      await tester.pump(_interval);
      expect(attempts, 2);
    });

    testWidgets('cancel stops polling, also a refresh in flight',
        (tester) async {
      var refreshes = 0;
      late final PrefabJobPoller poller;
      poller = PrefabJobPoller(
        interval: _interval,
        isRunning: () => true,
        refresh: () async {
          refreshes++;
          poller.cancel();
        },
      );
      poller.check();
      await tester.pump(_interval);
      await tester.pump(_interval * 3);
      expect(refreshes, 1);

      // It can be started again.
      poller.check();
      await tester.pump(_interval);
      expect(refreshes, 2);
    });
  });

  group('PF-57 prefabPolledDetail', () {
    testWidgets('follows a job from running to done and stops loading',
        (tester) async {
      final states = ['running', 'running', 'done'];
      var loads = 0;
      final emitted = <String>[];
      final subscription = prefabPolledDetail<String>(
        load: () async => states[loads++],
        isRunning: (s) => s == 'running',
        interval: _interval,
      ).listen(emitted.add);

      await tester.pump();
      expect(emitted, ['running']);
      await tester.pump(_interval);
      expect(emitted, ['running', 'running']);
      await tester.pump(_interval);
      expect(emitted, ['running', 'running', 'done']);
      await tester.pump(_interval * 5);
      expect(loads, 3, reason: 'a final job is not loaded again');
      await _cancel(tester, subscription);
    });

    testWidgets('does not poll a job that is final from the start',
        (tester) async {
      var loads = 0;
      final subscription = prefabPolledDetail<String>(
        load: () async {
          loads++;
          return 'failed';
        },
        isRunning: (s) => s == 'running',
        interval: _interval,
      ).listen((_) {});
      await tester.pump(_interval * 3);
      expect(loads, 1);
      await _cancel(tester, subscription);
    });

    testWidgets('keeps the state when a refresh fails', (tester) async {
      var loads = 0;
      final emitted = <String>[];
      final errors = <Object>[];
      final subscription = prefabPolledDetail<String>(
        load: () async {
          loads++;
          if (loads == 2) throw StateError('offline');
          return loads == 1 ? 'running' : 'done';
        },
        isRunning: (s) => s == 'running',
        interval: _interval,
      ).listen(emitted.add, onError: errors.add);

      await tester.pump();
      await tester.pump(_interval);
      expect(errors, isEmpty);
      await tester.pump(_interval);
      expect(emitted, ['running', 'done']);
      await _cancel(tester, subscription);
    });

    testWidgets('reports the error of the first load', (tester) async {
      final errors = <Object>[];
      final subscription = prefabPolledDetail<String>(
        load: () async => throw StateError('not found'),
        isRunning: (s) => true,
        interval: _interval,
      ).listen((_) {}, onError: errors.add);
      await tester.pump();
      expect(errors, hasLength(1));
      await _cancel(tester, subscription);
    });

    testWidgets('stops when the listener cancels', (tester) async {
      var loads = 0;
      final subscription = prefabPolledDetail<String>(
        load: () async {
          loads++;
          return 'running';
        },
        isRunning: (s) => true,
        interval: _interval,
      ).listen((_) {});
      await tester.pump();
      await _cancel(tester, subscription);
      await tester.pump(_interval * 3);
      expect(loads, 1);
    });
  });

  group('PF-57 job widgets', () {
    Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
          MaterialApp(home: Scaffold(body: Center(child: child))),
        );

    testWidgets('the indicator shows each state', (tester) async {
      await pump(
          tester, const PrefabJobIndicator(state: PrefabJobState.running));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await pump(tester, const PrefabJobIndicator(state: PrefabJobState.done));
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      await pump(
          tester, const PrefabJobIndicator(state: PrefabJobState.failed));
      expect(find.byIcon(Icons.error), findsOneWidget);
    });

    testWidgets('the banner shows each state and the failure message',
        (tester) async {
      await pump(tester, const PrefabJobBanner(state: PrefabJobState.running));
      expect(find.text('Running'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);

      await pump(tester, const PrefabJobBanner(state: PrefabJobState.done));
      expect(find.text('Done'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsNothing);

      await pump(
        tester,
        const PrefabJobBanner(
          state: PrefabJobState.failed,
          message: 'The model ran out of tokens.',
        ),
      );
      expect(find.text('Failed'), findsOneWidget);
      expect(find.text('The model ran out of tokens.'), findsOneWidget);
    });
  });
}
