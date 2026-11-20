import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prefab_flutter_widgets/prefab_flutter_widgets.dart';

typedef _Item = ({int id, String name});

_Item _fromJson(Map<String, dynamic> json) =>
    (id: json['id'] as int, name: json['name'] as String);

PrefabPage<_Item> _page({
  List<_Item> items = const [(id: 1, name: 'a'), (id: 2, name: 'b')],
  int total = 2,
  int page = 0,
  int pageSize = 20,
}) =>
    PrefabPage(items: items, totalItems: total, page: page, pageSize: pageSize);

PrefabPage<_Item> _apply(
  PrefabPage<_Item> page,
  PrefabEventType type,
  Map<String, dynamic> data, {
  bool paged = true,
  bool canInsert = true,
}) =>
    applyPrefabEvent<_Item>(page, PrefabEvent(type, data),
        fromJson: _fromJson,
        idOf: (e) => e.id,
        idKey: 'id',
        paged: paged,
        canInsert: canInsert);

/// Answers every request with a server-sent events body from [bodies] (the
/// next one per request) or fails when it is empty.
class _SseAdapter implements HttpClientAdapter {
  final bodies = <Stream<List<int>>>[];
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    requests.add(options);
    if (bodies.isEmpty) throw DioException(requestOptions: options);
    return ResponseBody(bodies.removeAt(0).map(Uint8List.fromList), 200,
        headers: {
          Headers.contentTypeHeader: ['text/event-stream'],
        });
  }

  @override
  void close({bool force = false}) {}
}

Stream<List<int>> _text(String text) => Stream.value(utf8.encode(text));

void main() {
  group('PF-56 AC#1 - applying events to a list page', () {
    test('updated replaces the item on the page, ignores others', () {
      final updated =
          _apply(_page(), PrefabEventType.updated, {'id': 2, 'name': 'B'});
      expect(updated.items.map((e) => e.name), ['a', 'B']);
      final other =
          _apply(_page(), PrefabEventType.updated, {'id': 9, 'name': 'x'});
      expect(other, _page());
    });

    test('deleted removes the item and lowers the total', () {
      final result = _apply(_page(), PrefabEventType.deleted, {'id': 1});
      expect(result.items.map((e) => e.id), [2]);
      expect(result.totalItems, 1);
      expect(_apply(_page(), PrefabEventType.deleted, {'id': 9}), _page());
    });

    test('created appends to an unpaged list', () {
      final result = _apply(
          _page(), PrefabEventType.created, {'id': 3, 'name': 'c'},
          paged: false);
      expect(result.items.map((e) => e.id), [1, 2, 3]);
      expect(result.totalItems, 3);
      expect(result.newItems, 0);
    });

    test('created that is already on the page replaces it', () {
      final result =
          _apply(_page(), PrefabEventType.created, {'id': 1, 'name': 'A'});
      expect(result.items.first.name, 'A');
      expect(result.totalItems, 2);
    });
  });

  group('PF-56 AC#3 - items outside the page', () {
    test('created on the last page with room is appended', () {
      final result =
          _apply(_page(), PrefabEventType.created, {'id': 3, 'name': 'c'});
      expect(result.items.length, 3);
      expect(result.newItems, 0);
    });

    test('created on a full page raises newItems instead of inserting', () {
      final full = _page(pageSize: 2);
      final result =
          _apply(full, PrefabEventType.created, {'id': 3, 'name': 'c'});
      expect(result.items, full.items);
      expect(result.totalItems, 2);
      expect(result.newItems, 1);
    });

    test('created on a page before the last raises newItems', () {
      final first = _page(total: 5, pageSize: 2);
      expect(
          _apply(first, PrefabEventType.created, {'id': 3, 'name': 'c'})
              .newItems,
          1);
    });

    test('created while a search or sort is active raises newItems', () {
      final result = _apply(
          _page(), PrefabEventType.created, {'id': 3, 'name': 'c'},
          canInsert: false, paged: false);
      expect(result.items.length, 2);
      expect(result.newItems, 1);
    });
  });

  group('PF-56 AC#1 - backend event format', () {
    const backend = PrefabBackend();

    test('parses created, updated and deleted events', () {
      expect(backend.parseEvent('created', '{"id":1}')!.type,
          PrefabEventType.created);
      expect(backend.parseEvent('updated', '{"id":1}')!.type,
          PrefabEventType.updated);
      final deleted = backend.parseEvent('deleted', '{"id":1}')!;
      expect(deleted.type, PrefabEventType.deleted);
      expect(deleted.idOf('id'), 1);
    });

    test('ignores other events and invalid data', () {
      expect(backend.parseEvent(null, '{"id":1}'), isNull);
      expect(backend.parseEvent('ping', '{}'), isNull);
      expect(backend.parseEvent('created', 'nope'), isNull);
      expect(backend.parseEvent('created', '[1]'), isNull);
    });

    test('event names and the stream path are configurable', () {
      const custom = PrefabBackend(
          streamPath: 'events', createdEvent: 'add', updatedEvent: 'change');
      expect(custom.eventsUrl('/products'), '/products/events');
      expect(custom.parseEvent('add', '{}')!.type, PrefabEventType.created);
      expect(custom.parseEvent('created', '{}'), isNull);
    });
  });

  group('PF-56 AC#2 - the SSE client', () {
    test('parses events from the stream with the configured Dio', () async {
      final adapter = _SseAdapter()
        ..bodies.add(_text(': hello\n\n'
            'event: created\ndata: {"id":1,\ndata: "name":"a"}\n\n'
            'event: deleted\ndata: {"id":1}\n\n'
            'event: ping\ndata: x\n\n'));
      final dio = Dio(BaseOptions(baseUrl: 'http://x'))
        ..httpClientAdapter = adapter
        ..interceptors.add(InterceptorsWrapper(onRequest: (o, h) {
          o.headers['Authorization'] = 'Bearer t';
          h.next(o);
        }));
      final source = PrefabEventSource(
          dio: dio, backend: const PrefabBackend(), url: '/products/stream');
      final events = await source.events().take(2).toList();
      expect(events.map((e) => e.type),
          [PrefabEventType.created, PrefabEventType.deleted]);
      expect(events.first.data, {'id': 1, 'name': 'a'});
      expect(adapter.requests.first.headers['Authorization'], 'Bearer t');
      expect(adapter.requests.first.headers['Accept'], 'text/event-stream');
    });

    test('reconnects after the connection ends or fails', () async {
      final adapter = _SseAdapter()
        ..bodies.add(_text('event: created\ndata: {"id":1}\n\n'))
        ..bodies.add(_text('event: created\ndata: {"id":2}\n\n'));
      final source = PrefabEventSource(
        dio: Dio()..httpClientAdapter = adapter,
        backend: const PrefabBackend(),
        url: '/p',
        initialDelay: const Duration(milliseconds: 1),
      );
      final events = await source.events().take(2).toList();
      expect(events.map((e) => e.data['id']), [1, 2]);
      expect(adapter.requests.length, 2);
    });

    test('backoff doubles up to the maximum', () {
      final source = PrefabEventSource(
        dio: Dio(),
        backend: const PrefabBackend(),
        url: '/p',
        initialDelay: const Duration(seconds: 1),
        maxDelay: const Duration(seconds: 5),
      );
      expect([for (var i = 0; i < 5; i++) source.delayFor(i).inSeconds],
          [1, 2, 4, 5, 5]);
    });

    test('stops when the listener cancels', () async {
      final adapter = _SseAdapter()..bodies.add(StreamController<List<int>>().stream);
      final source = PrefabEventSource(
        dio: Dio()..httpClientAdapter = adapter,
        backend: const PrefabBackend(),
        url: '/p',
        initialDelay: const Duration(milliseconds: 1),
      );
      final subscription = source.events().listen((_) {});
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await subscription.cancel();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(adapter.requests.length, 1);
    });

    test('the provider shares one connection and can be faked', () async {
      final controller = StreamController<PrefabEvent>.broadcast();
      final container = ProviderContainer(overrides: [
        prefabEventsProvider
            .overrideWith((ref, url) => controller.stream),
      ]);
      addTearDown(container.dispose);
      final received = <PrefabEvent>[];
      container.listen(prefabEventsProvider('/p'), (_, __) {});
      container.read(prefabEventsProvider('/p')).listen(received.add);
      controller.add(const PrefabEvent(PrefabEventType.created, {'id': 1}));
      await Future<void>.delayed(Duration.zero);
      expect(received, hasLength(1));
    });
  });

  group('PF-56 AC#1 - live detail', () {
    test('yields the loaded value, then updates for its id', () async {
      final controller = StreamController<PrefabEvent>();
      final values = <Object>[];
      final done = prefabLiveDetail<_Item>(
        load: () async => (id: 1, name: 'a'),
        events: controller.stream,
        fromJson: _fromJson,
        id: 1,
        idKey: 'id',
      ).map((e) => e.name).listen(values.add, onError: values.add);
      await Future<void>.delayed(Duration.zero);
      controller
        ..add(const PrefabEvent(
            PrefabEventType.updated, {'id': 2, 'name': 'other'}))
        ..add(const PrefabEvent(
            PrefabEventType.updated, {'id': 1, 'name': 'A'}))
        ..add(const PrefabEvent(PrefabEventType.deleted, {'id': 1}));
      await Future<void>.delayed(Duration.zero);
      await done.cancel();
      expect(values.take(2), ['a', 'A']);
      expect(values[2], isA<PrefabEntityDeleted>());
    });
  });
}
