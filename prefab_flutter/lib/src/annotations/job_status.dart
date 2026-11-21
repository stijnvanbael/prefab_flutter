/// Marks the field that holds the status of a long-running server job.
///
/// Some entities are *jobs*: the server creates them and keeps working on them
/// for seconds or minutes (a generated summary, an import, a report). Put
/// [@JobStatus] on the field of an enum type that tells how far the job is;
/// the generated screens then show it and keep it up to date without code:
///
/// * list items show a progress indicator while the job runs, a check mark
///   when it is done and an error icon when it failed,
/// * the detail screen starts with a banner that shows the same, with the
///   server's failure message,
/// * while a job runs, the detail and list providers refresh every
///   [pollInterval] and stop when every job is final. An entity that is also
///   `@Streaming` follows the live events instead and does not poll.
///
/// ```dart
/// enum ReportStatus { queued, running, done, failed }
///
/// @Entity()
/// class Report {
///   final int? id;
///   @Field()
///   final String title;
///   @JobStatus()
///   @Field()
///   final ReportStatus status;
///   @Field(readOnly: true)
///   final String? error;
///   ...
/// }
/// ```
///
/// The status field is owned by the server, so it is never in a form or in a
/// request body (like `@Field(readOnly: true)`).
class JobStatus {
  /// The enum values that mean the job is still being worked on. When none of
  /// [running], [done] and [failed] names a value, it is classified by its
  /// name: `queued`, `pending`, `waiting`, `scheduled`, `running`,
  /// `inProgress`, `started`, `processing`, `active`.
  final Set<Enum>? running;

  /// The enum values that mean the job finished successfully; by name:
  /// `done`, `completed`, `complete`, `succeeded`, `success`, `finished`,
  /// `ready`.
  final Set<Enum>? done;

  /// The enum values that mean the job failed; by name: `failed`, `failure`,
  /// `error`, `errored`.
  final Set<Enum>? failed;

  /// The name of the `String?` field that holds the server's failure message,
  /// shown in the detail banner of a failed job. Without it a field named
  /// `error`, `errorMessage`, `failureReason`, `failureMessage` or `failure`
  /// is used, if the entity has one.
  final String? message;

  /// How often the providers refresh while a job runs. Ignored for an entity
  /// that is `@Streaming`.
  final Duration pollInterval;

  const JobStatus({
    this.running,
    this.done,
    this.failed,
    this.message,
    this.pollInterval = const Duration(seconds: 3),
  });
}
