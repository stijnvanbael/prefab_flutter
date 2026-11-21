import 'dart:async';

import 'prefab_page.dart';

/// What happened to an entity on the server, or [reconnected] when the event
/// stream itself was interrupted.
enum PrefabEventType {
  created,
  updated,
  deleted,

  /// The stream connection was re-established after it dropped: events may
  /// have been missed, so listeners reload what they show. Carries no entity.
  reconnected,
}

/// One event of an entity's live stream (see `@Streaming`): what happened and
/// the JSON of the entity. For [PrefabEventType.deleted] the data may be only
/// the id.
class PrefabEvent {
  /// What happened.
  final PrefabEventType type;

  /// The entity as JSON (a deleted entity may carry only its id).
  final Map<String, dynamic> data;

  const PrefabEvent(this.type, this.data);

  /// The signal that the stream reconnected after a gap (see
  /// [PrefabEventType.reconnected]).
  const PrefabEvent.reconnected()
      : type = PrefabEventType.reconnected,
        data = const {};

  /// The id of the entity this event is about, read from the JSON key
  /// [idKey].
  Object? idOf(String idKey) => data[idKey];

  @override
  String toString() => 'PrefabEvent($type, $data)';
}

/// Thrown into a live detail provider when the entity it shows was deleted.
class PrefabEntityDeleted implements Exception {
  /// The id of the deleted entity.
  final Object? id;

  const PrefabEntityDeleted(this.id);

  @override
  String toString() => 'The item $id was deleted.';
}

bool _sameId(Object? a, Object? b) => a != null && '$a' == '$b';

/// Applies [event] to a list [page] and returns the new page.
///
/// * `updated` replaces the item with the same id when it is on the page and
///   is ignored otherwise.
/// * `deleted` removes the item when it is on the page (and lowers the total)
///   and is ignored otherwise.
/// * `created` appends the item when [canInsert] is true and the page can take
///   it (an unpaged list, or the last page with room). Otherwise the item is
///   not inserted: [PrefabPage.newItems] is raised so the screen can offer a
///   refresh. An item that is already on the page (the client created it
///   itself) is replaced.
///
/// A `reconnected` event leaves the page as it is: the caller reloads it.
///
/// [canInsert] is false while a search or sort is active: the server decides
/// where a new item belongs then, and whether it matches.
PrefabPage<T> applyPrefabEvent<T>(
  PrefabPage<T> page,
  PrefabEvent event, {
  required T Function(Map<String, dynamic> json) fromJson,
  required Object? Function(T item) idOf,
  required String idKey,
  required bool paged,
  bool canInsert = true,
}) {
  final id = event.idOf(idKey);
  final index = page.items.indexWhere((e) => _sameId(idOf(e), id));
  switch (event.type) {
    case PrefabEventType.reconnected:
      return page;
    case PrefabEventType.updated:
      if (index < 0) return page;
      return page.copyWith(
        items: [...page.items]..[index] = fromJson(event.data),
      );
    case PrefabEventType.deleted:
      if (index < 0) return page;
      return page.copyWith(
        items: [...page.items]..removeAt(index),
        totalItems: page.totalItems > 0 ? page.totalItems - 1 : 0,
      );
    case PrefabEventType.created:
      if (index >= 0) {
        return page.copyWith(
          items: [...page.items]..[index] = fromJson(event.data),
        );
      }
      final onLastPage =
          page.page >= page.totalPages - 1 && page.items.length < page.pageSize;
      if (canInsert && (!paged || onLastPage)) {
        return page.copyWith(
          items: [...page.items, fromJson(event.data)],
          totalItems: page.totalItems + 1,
        );
      }
      return page.copyWith(newItems: page.newItems + 1);
  }
}

/// A stream with the current state of one entity: loads it with [load], then
/// follows the events for [id] from [events] (events that arrive while
/// loading are applied afterwards). When the entity is deleted the stream
/// fails with [PrefabEntityDeleted]. When [events] signals a reconnect the
/// entity is loaded again (events that arrive meanwhile are applied after it;
/// a failing load is added to the stream as an error, e.g. when the entity
/// was deleted while disconnected). [events] is only listened to while the
/// stream has a listener.
Stream<T> prefabLiveDetail<T>({
  required Future<T> Function() load,
  required Stream<PrefabEvent> events,
  required T Function(Map<String, dynamic> json) fromJson,
  required Object? id,
  required String idKey,
}) {
  late final StreamController<T> controller;
  StreamSubscription<PrefabEvent>? subscription;
  var loaded = false;
  var cancelled = false;
  final pending = <PrefabEvent>[];

  // `loadValue` and `apply` call each other: declare one up front.
  late final void Function(PrefabEvent event) apply;

  Future<void> loadValue() async {
    try {
      final value = await load();
      if (!cancelled) controller.add(value);
    } catch (error, stack) {
      if (!cancelled) controller.addError(error, stack);
    }
    final queued = [...pending];
    pending.clear();
    loaded = true;
    queued.forEach(apply);
  }

  apply = (PrefabEvent event) {
    if (cancelled) return;
    if (event.type == PrefabEventType.reconnected) {
      loaded = false;
      loadValue();
      return;
    }
    if (!_sameId(event.idOf(idKey), id)) return;
    switch (event.type) {
      case PrefabEventType.reconnected:
        break;
      case PrefabEventType.deleted:
        controller.addError(PrefabEntityDeleted(id));
      case PrefabEventType.created:
      case PrefabEventType.updated:
        controller.add(fromJson(event.data));
    }
  };

  Future<void> start() async {
    subscription = events.listen((event) {
      if (loaded) {
        apply(event);
      } else {
        pending.add(event);
      }
    });
    await loadValue();
  }

  controller = StreamController<T>(
    onListen: start,
    onCancel: () {
      cancelled = true;
      return subscription?.cancel();
    },
  );
  return controller.stream;
}
