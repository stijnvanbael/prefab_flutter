import '../enums/place.dart';

/// Signals that a prefab entity can be edited, or declares a named operation.
///
/// **`@Update()`** (no `path`): when present on a class annotated with
/// [@Entity], prefab generates the `{Entity}EditScreen`, the `edit` route, the
/// **Edit** action in the detail screen's AppBar and the `update()` methods on
/// the provider and API client.
///
/// Independent of [@Create]: an entity may be create-only, edit-only, both, or
/// neither (read-only).
///
/// **`@Update(path: 'send', label: 'Send')`**: a *named operation*, the
/// counterpart of Prefab's `@Update(path = "send")`. It is repeatable and
/// does not generate the edit screen. Each named operation gets
///
/// * an API client method (`send`) that calls `POST {path}/{id}/send`,
/// * a notifier method (`send`) that refreshes the entity and the list,
/// * a button in the places listed in [on] (the detail screen by default):
///   without [parameters] the button runs the operation (after the optional
///   [confirm] dialog); with [parameters] it opens a generated
///   `{Entity}{Operation}Screen` form for the parameters.
///
/// ```dart
/// @Entity()
/// @Update(path: 'send', label: 'Send', icon: 'send', confirm: 'Send the invoice?')
/// @Update(path: 'schedule', label: 'Schedule', parameters: ScheduleParameters)
/// class Invoice { ... }
/// ```
///
/// With [startsJob] the operation starts a long-running server job (see
/// [@JobStatus]): after it ran, the item menu of a list opens the job's
/// detail screen, which shows it running.
///
/// [parameters] is a class with `@Field` fields (the same field widgets and
/// validators as an entity), a constructor that takes them and a `toJson()`
/// method; its JSON is the request body.
class Update {
  const Update({
    this.path,
    this.label,
    this.icon,
    this.on = const {Place.detail},
    this.confirm,
    this.parameters,
    this.order = 0,
    this.startsJob = false,
  });

  /// The URL segment after the id of a named operation (`send` for
  /// `/invoices/1/send`). Without it the annotation marks the entity as
  /// editable and the other parameters must not be set.
  final String? path;

  /// Text of the button, menu entry or tooltip. Defaults to [path] in words
  /// (`mark-paid` becomes `Mark paid`).
  final String? label;

  /// Name of a member of Flutter's `Icons` class (`'send'` for `Icons.send`);
  /// `Icons.bolt` by default.
  final String? icon;

  /// The places the operation appears in: [Place.detail] and [Place.item].
  /// An operation with [parameters] is shown in the same places and opens the
  /// parameter form.
  final Set<Place> on;

  /// The question of the confirmation dialog shown before an operation
  /// without [parameters] runs; without it the operation runs at once.
  final String? confirm;

  /// A class with the `@Field` fields the user fills in; the generated form
  /// sends it as the request body.
  final Type? parameters;

  /// Operations are sorted by [order], then by label.
  final int order;

  /// Whether the operation starts a job of an entity with a [@JobStatus]
  /// field. After the operation ran (and its form, if it has [parameters],
  /// was saved) the item menu of a list opens the entity's detail screen; the
  /// detail screen stays where it is and shows the job running. Only for a
  /// named operation ([path] is set).
  final bool startsJob;
}
