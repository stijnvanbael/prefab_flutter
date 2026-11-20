import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prefab_flutter_widgets/prefab_flutter_widgets.dart';

typedef _Item = ({int id, String name});

_Item _fromJson(Map<String, dynamic> json) =>
    (id: json['id'] as int, name: json['name'] as String);

/// Answers each request with the next body of [bodies], or fails when none is
/// left; records the requests.
class _SseAdapter implements HttpClientAdapter {
  final bodies = <Stream<List<int>>>[];
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    requests.add(options);
    if (bodies.isEmpty) throw DioException(requestOptions: options);
    return ResponseBody(bodies.removeAt(0).map(Uint8List.fromList), 200);
  }

  @override
  void close({bool force = false}) {}
}

Stream<List<int>> _text(String text) => Stream.value(utf8.encode(text));

PrefabEventSource _source(_SseAdapter adapter,
        {PrefabBackend backend = const PrefabBackend()}) =>
    PrefabEventSource(
      dio: Dio()..httpClientAdapter = adapter,
      backend: backend,
      url: '/p',
      initialDelay: const Duration(milliseconds: 1),
    );

void main() {
  group('PF-74 AC#2 - the source signals a reconnect', () {
    test('emits reconnected after the connection ended, not before', () async {
      final adapter = _SseAdapter()
        ..bodies.add(_text('event: created\ndata: {"id":1}\n\n'))
        ..bodies.add(_text('event: created\ndata: {"id":2}\n\n'));
      final events = await _source(adapter).events().take(3).toList();
      expect(events.map((e) => e.type), [
        PrefabEventType.created,
        PrefabEventType.reconnected,
        PrefabEventType.created,
      ]);
    });

    test('emits reconnected when the first connection attempts failed',
        () async {
      // The adapter fails while it has no body; add one after a short wait.
      final adapter = _SseAdapter();
      final future = _source(adapter).events().first;
      await Future<void>.delayed(const Duration(milliseconds: 20));
      adapter.bodies.add(StreamController<List<int>>().stream);
      expect((await future).type, PrefabEventType.reconnected);
    });

    test('sends the last event id on a reconnect', () async {
      final adapter = _SseAdapter()
        ..bodies.add(_text('id: 7\nevent: created\ndata: {"id":1}\n\n'))
        ..bodies.add(StreamController<List<int>>().stream);
      await _source(adapter).events().take(2).toList();
      expect(adapter.requests.first.headers['Last-Event-ID'], isNull);
      expect(adapter.requests.last.headers['Last-Event-ID'], '7');
    });

    test('a backend that resumes from Last-Event-ID needs no catch-up',
        () async {
      final adapter = _SseAdapter()
        ..bodies.add(_text('id: 7\nevent: created\ndata: {"id":1}\n\n'))
        ..bodies.add(_text('id: 8\nevent: created\ndata: {"id":2}\n\n'));
      final events = await _source(adapter,
              backend: const PrefabBackend(resumeWithLastEventId: true))
          .events()
          .take(2)
          .toList();
      expect(events.map((e) => e.data['id']), [1, 2]);
      expect(adapter.requests.last.headers['Last-Event-ID'], '7');
    });

    test('resuming still reloads when no event id was seen', () async {
      final adapter = _SseAdapter()
        ..bodies.add(_text('event: created\ndata: {"id":1}\n\n'))
        ..bodies.add(_text(''))
        ..bodies.add(StreamController<List<int>>().stream);
      final events = await _source(adapter,
              backend: const PrefabBackend(resumeWithLastEventId: true))
          .events()
          .take(2)
          .toList();
      expect(events.last.type, PrefabEventType.reconnected);
    });
  });

  group('PF-74 AC#1 - the detail provider reloads', () {
    test('a fake source that drops and reconnects refreshes the value',
        () async {
      final controller = StreamController<PrefabEvent>();
      var server = 'a';
      final values = <String>[];
      final sub = prefabLiveDetail<_Item>(
        load: () async => (id: 1, name: server),
        events: controller.stream,
        fromJson: _fromJson,
        id: 1,
        idKey: 'id',
      ).map((e) => e.name).listen(values.add);
      await Future<void>.delayed(Duration.zero);
      server = 'b'; // changed while the connection was down
      controller.add(const PrefabEvent.reconnected());
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();
      expect(values, ['a', 'b']);
    });

    test('events during the catch-up load are applied after it', () async {
      final controller = StreamController<PrefabEvent>();
      final release = Completer<void>();
      var calls = 0;
      final values = <String>[];
      final sub = prefabLiveDetail<_Item>(
        load: () async {
          if (++calls == 2) await release.future;
          return (id: 1, name: 'loaded$calls');
        },
        events: controller.stream,
        fromJson: _fromJson,
        id: 1,
        idKey: 'id',
      ).map((e) => e.name).listen(values.add);
      await Future<void>.delayed(Duration.zero);
      controller
        ..add(const PrefabEvent.reconnected())
        ..add(const PrefabEvent(
            PrefabEventType.updated, {'id': 1, 'name': 'event'}));
      await Future<void>.delayed(Duration.zero);
      release.complete();
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();
      expect(values, ['loaded1', 'loaded2', 'event']);
    });

    test('a failing catch-up load is surfaced as an error', () async {
      final controller = StreamController<PrefabEvent>();
      var gone = false;
      final errors = <Object>[];
      final sub = prefabLiveDetail<_Item>(
        load: () async {
          if (gone) throw StateError('404');
          return (id: 1, name: 'a');
        },
        events: controller.stream,
        fromJson: _fromJson,
        id: 1,
        idKey: 'id',
      ).listen((_) {}, onError: errors.add);
      await Future<void>.delayed(Duration.zero);
      gone = true;
      controller.add(const PrefabEvent.reconnected());
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();
      expect(errors, hasLength(1));
    });
  });

  test('PF-74 applyPrefabEvent leaves a page alone on reconnected', () {
    const page = PrefabPage<_Item>(
        items: [(id: 1, name: 'a')],
        totalItems: 1,
        page: 0,
        pageSize: 20);
    expect(
        applyPrefabEvent<_Item>(page, const PrefabEvent.reconnected(),
            fromJson: _fromJson,
            idOf: (e) => e.id,
            idKey: 'id',
            paged: true),
        same(page));
  });
}
