import 'package:json_annotation/json_annotation.dart';
import 'package:prefab_flutter/prefab_flutter.dart';

part 'report.g.dart';

/// The states of a report job. `@JobStatus` classifies the values by their
/// names (`queued` and `running` are running, `done`, `failed`), so nothing
/// has to be configured.
enum ReportStatus { queued, running, done, failed }

/// A report the server generates in a job that takes a while (PF-57): the
/// list items show whether it is running, done or failed, the detail screen
/// starts with a banner (with the server's message when it failed), and both
/// refresh every two seconds until the job is final.
@JsonSerializable()
@Entity(title: 'Report', path: 'reports')
@Create()
@Delete()
// Starts the job again; a list item then opens the report, which shows it
// running.
@Update(
  path: 'regenerate',
  label: 'Regenerate',
  icon: 'refresh',
  on: {Place.item, Place.detail},
  startsJob: true,
)
class Report {
  final int? id;

  @Field(form: FormOptions(validators: [Validator.required]))
  final String title;

  /// Owned by the server: never in the form or in a request body.
  @JobStatus(pollInterval: Duration(seconds: 2))
  @Field()
  final ReportStatus status;

  /// The server's failure message, shown by the banner of a failed job.
  @Field(readOnly: true)
  final String? error;

  Report({
    this.id,
    required this.title,
    this.status = ReportStatus.queued,
    this.error,
  });

  factory Report.fromJson(Map<String, dynamic> json) => _$ReportFromJson(json);
  Map<String, dynamic> toJson() => _$ReportToJson(this);
}
