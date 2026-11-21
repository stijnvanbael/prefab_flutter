import 'package:prefab_flutter/prefab_flutter.dart';

enum SummaryStatus { queued, running, done, failed }

// The values are classified by their names, the message field is `error`.
@Entity(title: 'Summary', path: 'summaries')
@Create()
@Update(path: 'regenerate', icon: 'refresh', on: {Place.item, Place.detail}, startsJob: true)
class Summary {
  final int? id;
  @Field()
  final String title;
  @JobStatus()
  @Field()
  final SummaryStatus status;
  @Field(readOnly: true)
  final String? error;
  Summary({this.id, required this.title, required this.status, this.error});
  factory Summary.fromJson(Map<String, dynamic> json) => throw 0;
  Map<String, dynamic> toJson() => {};
}

enum UploadPhase { uploading, parsing, imported, rejected, cancelled }

// Values named explicitly, another message field and poll interval, nested
// below a parent.
@Entity(title: 'Source', path: 'sources')
class Source {
  final int id;
  @Field()
  final String name;
  Source({required this.id, required this.name});
  factory Source.fromJson(Map<String, dynamic> json) => throw 0;
  Map<String, dynamic> toJson() => {};
}

@Entity(title: 'Upload', path: 'uploads')
class Upload {
  final int? id;
  @Parent(Source)
  @Field(on: {})
  final int sourceId;
  @JobStatus(
    running: {UploadPhase.uploading, UploadPhase.parsing},
    done: {UploadPhase.imported},
    failed: {UploadPhase.rejected, UploadPhase.cancelled},
    message: 'reason',
    pollInterval: Duration(milliseconds: 1500),
  )
  @Field()
  final UploadPhase phase;
  final String? reason;
  Upload({this.id, required this.sourceId, required this.phase, this.reason});
  factory Upload.fromJson(Map<String, dynamic> json) => throw 0;
  Map<String, dynamic> toJson() => {};
}

// A streaming job follows the live events and does not poll.
@Entity(title: 'Render', path: 'renders')
@Streaming()
class Render {
  final int? id;
  @Field()
  final String name;
  @JobStatus()
  @Field()
  final SummaryStatus state;
  Render({this.id, required this.name, required this.state});
  factory Render.fromJson(Map<String, dynamic> json) => throw 0;
  Map<String, dynamic> toJson() => {};
}
