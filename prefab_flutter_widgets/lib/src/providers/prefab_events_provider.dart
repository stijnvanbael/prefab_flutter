import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/prefab_backend.dart';
import '../models/prefab_event.dart';
import 'prefab_dio_provider.dart';

/// A server-sent events (SSE) connection to the event stream of one
/// collection, on top of the configured [Dio] (so its base URL and
/// authentication interceptors apply).
///
/// [events] connects when it is listened to, closes the connection when the
/// listener cancels and reconnects with exponential backoff (starting at
/// [initialDelay], at most [maxDelay], reset by a successful connection) when
/// the connection fails or ends.
class PrefabEventSource {
  final Dio dio;
  final PrefabBackend backend;

  /// The URL of the event stream, relative to the Dio base URL.
  final String url;

  /// The wait before the first reconnect; doubles with every failure.
  final Duration initialDelay;

  /// The longest wait between reconnects.
  final Duration maxDelay;

  const PrefabEventSource({
    required this.dio,
    required this.backend,
    required this.url,
    this.initialDelay = const Duration(seconds: 1),
    this.maxDelay = const Duration(seconds: 30),
  });

  /// The delay before reconnect number [attempt] (0 for the first).
  Duration delayFor(int attempt) {
    final micros = initialDelay.inMicroseconds * (1 << attempt.clamp(0, 20));
    return Duration(
      microseconds: micros > maxDelay.inMicroseconds
          ? maxDelay.inMicroseconds
          : micros,
    );
  }

  /// The events of the collection. Single-subscription.
  Stream<PrefabEvent> events() {
    late final StreamController<PrefabEvent> controller;
    StreamSubscription<String>? lines;
    Timer? retry;
    CancelToken? cancel;
    var attempt = 0;
    var closed = false;

    void scheduleReconnect(void Function() connect) {
      if (closed) return;
      retry = Timer(delayFor(attempt++), connect);
    }

    void connect() {
      cancel = CancelToken();
      dio
          .get<ResponseBody>(
        url,
        cancelToken: cancel,
        options: Options(
          responseType: ResponseType.stream,
          receiveTimeout: Duration.zero,
          headers: {'Accept': 'text/event-stream'},
        ),
      )
          .then((response) {
        if (closed) return;
        attempt = 0;
        String? name;
        final data = <String>[];
        lines = utf8.decoder
            .bind(response.data!.stream.cast<List<int>>())
            .transform(const LineSplitter())
            .listen(
          (line) {
            if (line.isEmpty) {
              if (data.isNotEmpty) {
                final event = backend.parseEvent(name, data.join('\n'));
                if (event != null) controller.add(event);
              }
              name = null;
              data.clear();
            } else if (line.startsWith('event:')) {
              name = line.substring(6).trim();
            } else if (line.startsWith('data:')) {
              data.add(line.substring(5).trimLeft());
            }
          },
          onError: (Object _) => scheduleReconnect(connect),
          onDone: () => scheduleReconnect(connect),
          cancelOnError: true,
        );
      }, onError: (Object _) => scheduleReconnect(connect));
    }

    controller = StreamController<PrefabEvent>(
      onListen: connect,
      onCancel: () async {
        closed = true;
        retry?.cancel();
        cancel?.cancel();
        await lines?.cancel();
      },
    );
    return controller.stream;
  }
}

/// The live events of the collection at a URL (relative to the Dio base URL,
/// e.g. `/products/stream`), shared by every listener: the connection opens
/// with the first listener and closes when the last one is gone.
///
/// Generated providers of `@Streaming` entities listen to it. Override it with
/// a fake stream in tests:
///
/// ```dart
/// prefabEventsProvider.overrideWith((ref, url) => controller.stream)
/// ```
final prefabEventsProvider =
    Provider.autoDispose.family<Stream<PrefabEvent>, String>((ref, url) {
  final source = PrefabEventSource(
    dio: ref.watch(prefabDioProvider),
    backend: ref.watch(prefabBackendProvider),
    url: url,
  );
  // One connection for all listeners: opened by the first one, closed when
  // the last one cancels (and opened again by the next one).
  late final StreamController<PrefabEvent> shared;
  StreamSubscription<PrefabEvent>? connection;
  shared = StreamController<PrefabEvent>.broadcast(
    onListen: () =>
        connection = source.events().listen(shared.add, onError: shared.addError),
    onCancel: () {
      final open = connection;
      connection = null;
      open?.cancel();
    },
  );
  ref.onDispose(() {
    connection?.cancel();
    shared.close();
  });
  return shared.stream;
});
