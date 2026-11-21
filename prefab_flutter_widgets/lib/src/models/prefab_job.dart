import 'dart:async';

/// Where a long-running server job stands (see `@JobStatus`).
enum PrefabJobState {
  /// The server is still working on it.
  running,

  /// It finished successfully.
  done,

  /// It failed; the server may tell why.
  failed,
}

/// Refreshes the list of a job entity while one of its items is running.
///
/// The generated list notifier calls [check] after every change of its state.
/// While [isRunning] is true, [refresh] runs every [interval] (and [check]
/// again after each run, so polling continues even when the answer did not
/// change the state); polling stops as soon as [isRunning] is false. A
/// [refresh] that fails is ignored and tried again at the next interval.
/// [cancel] stops everything, also a refresh that is still running.
class PrefabJobPoller {
  PrefabJobPoller({
    required this.interval,
    required this.isRunning,
    required this.refresh,
  });

  /// The wait between two refreshes.
  final Duration interval;

  /// Whether any job is still running, according to the current state.
  final bool Function() isRunning;

  /// Loads the current state of the jobs.
  final Future<void> Function() refresh;

  Timer? _timer;
  int _generation = 0;

  /// Starts polling when a job is running and no refresh is scheduled yet.
  void check() {
    if (_timer != null || !isRunning()) return;
    final generation = _generation;
    _timer = Timer(interval, () => _tick(generation));
  }

  Future<void> _tick(int generation) async {
    _timer = null;
    if (generation != _generation) return;
    try {
      await refresh();
    } catch (_) {
      // A failed refresh keeps what is shown; the next interval tries again.
    }
    if (generation != _generation) return;
    check();
  }

  /// Stops polling. [check] starts it again.
  void cancel() {
    _generation++;
    _timer?.cancel();
    _timer = null;
  }
}

/// A stream with the current state of one job entity: loads it with [load],
/// then, while [isRunning] says the entity is running, loads it again every
/// [interval] and emits the new state. A refresh that fails keeps the state
/// that is shown and is tried again at the next interval; only the first load
/// reports its error. Nothing is loaded after the listener cancelled.
///
/// Generated detail providers of `@JobStatus` entities (without
/// `@Streaming`) are built on it.
Stream<T> prefabPolledDetail<T>({
  required Future<T> Function() load,
  required bool Function(T value) isRunning,
  required Duration interval,
}) {
  late final StreamController<T> controller;
  Timer? timer;
  var cancelled = false;

  Future<void> run({required bool first}) async {
    timer = null;
    try {
      final value = await load();
      if (cancelled) return;
      controller.add(value);
      if (isRunning(value)) timer = Timer(interval, () => run(first: false));
    } catch (error, stack) {
      if (cancelled) return;
      if (first) {
        controller.addError(error, stack);
      } else {
        timer = Timer(interval, () => run(first: false));
      }
    }
  }

  controller = StreamController<T>(
    onListen: () => run(first: true),
    onCancel: () {
      cancelled = true;
      timer?.cancel();
      timer = null;
    },
  );
  return controller.stream;
}
