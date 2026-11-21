import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:prefab_flutter_generator/builder.dart';
import 'package:test/test.dart';

import 'support/prefab_sources.dart';

String _source({
  String annotations = '',
  String status = '@JobStatus()\n  @Field()',
  String enumValues = 'queued, running, done, failed',
  String statusType = 'Status',
  String extraFields = '@Field(readOnly: true)\n  final String? error;',
  String entityAnnotations = '@Create()\n@Update()',
}) =>
    '''
import 'package:prefab_flutter/prefab_flutter.dart';

enum Status { $enumValues }

@Entity(title: 'Report', path: 'reports')
$entityAnnotations
$annotations
class Report {
  final int? id;
  @Field()
  final String title;
  $status
  final $statusType status;
  $extraFields
  Report({this.id, required this.title, required this.status, this.error});
  factory Report.fromJson(Map<String, dynamic> json) => throw 0;
  Map<String, dynamic> toJson() => {};
}
''';

String _squash(String text) => text.replaceAll(RegExp(r'\s+'), '');

/// The generated code contains [text], ignoring whitespace (the output is
/// formatted by dart_style, which wraps lines).
Matcher has(String text) => predicate<String>(
    (output) => _squash(output).contains(_squash(text)), 'contains $text');

/// The generated code does not contain [text], ignoring whitespace.
Matcher lacks(String text) => predicate<String>(
    (output) => !_squash(output).contains(_squash(text)),
    'does not contain $text');

Map<String, String> _assets(String source) =>
    {...prefabSources, 'a|lib/report.dart': source};

Future<void> _expectOutput(String source, Matcher matcher) => testBuilder(
      prefabBuilder(BuilderOptions.empty),
      _assets(source),
      outputs: {'a|lib/report.prefab.dart': decodedMatches(matcher)},
    );

/// Runs the builder and returns everything it logged plus any thrown error.
Future<String> _buildError(String source) async {
  final logs = <String>[];
  try {
    await testBuilder(
      prefabBuilder(BuilderOptions.empty),
      _assets(source),
      onLog: (r) => logs.add('${r.message} ${r.error ?? ''}'),
    );
  } catch (e) {
    logs.add(e.toString());
  }
  return logs.join('\n');
}

void main() {
  group('PF-57 AC#1 - the job status field', () {
    test('the values are classified by their names', () async {
      await _expectOutput(
        _source(enumValues: 'pending, inProgress, completed, error'),
        allOf([
          has('PrefabJobBanner('),
          has('Status.pending || Status.inProgress =>'),
          has('PrefabJobState.running'),
          has('Status.completed => PrefabJobState.done'),
          has('Status.error => PrefabJobState.failed'),
        ]),
      );
    });

    test('the detail screen shows the banner with the failure message',
        () async {
      await _expectOutput(
        _source(),
        allOf([
          has('PrefabJobBanner('),
          has('message: report.error,'),
          has('Status.queued || Status.running'),
          has('Status.done => PrefabJobState.done'),
          has('Status.failed => PrefabJobState.failed'),
        ]),
      );
    });

    test('list items show the state in front of the trailing field',
        () async {
      await _expectOutput(
        _source(),
        allOf([
          has('PrefabJobIndicator('),
          has('mainAxisSize: MainAxisSize.min'),
        ]),
      );
    });

    test('the message field can be named, else it is found by name',
        () async {
      await _expectOutput(
        _source(
          status: "@JobStatus(message: 'reason')\n  @Field()",
          extraFields: 'final String? reason;\n  final String? error;',
        ),
        has('message: report.reason,'),
      );
      await _expectOutput(
        _source(extraFields: 'final String? errorMessage;'),
        has('message: report.errorMessage,'),
      );
      await _expectOutput(
        _source(extraFields: 'final String? note;'),
        has('message: null,'),
      );
    });

    test('values can be named explicitly', () async {
      await _expectOutput(
        _source(
          enumValues: 'started, finished, cancelled',
          status: '@JobStatus(failed: {Status.cancelled}, '
              'running: {Status.started})\n  @Field()',
        ),
        allOf([
          has('Status.started => PrefabJobState.running'),
          has('Status.finished => PrefabJobState.done'),
          has('Status.cancelled => PrefabJobState.failed'),
        ]),
      );
    });

    test('the status is owned by the server: never in a form or a request',
        () async {
      await _expectOutput(
        _source(),
        allOf([
          lacks('_status'),
          lacks('DropdownButtonFormField<Status>'),
          has('_titleController'),
        ]),
      );
    });

    test('an entity without @JobStatus is unchanged', () async {
      await _expectOutput(
        _source(status: '@Field()'),
        allOf([
          lacks('PrefabJob'),
          lacks('prefabPolledDetail'),
          has('FutureProvider.autoDispose'),
        ]),
      );
    });

    test('a status that cannot be classified is an error naming the values',
        () async {
      final error = await _buildError(_source(enumValues: 'draft, sent, paid'));
      expect(error, contains('@JobStatus on "Report.status"'));
      expect(error, contains('"draft", "sent", "paid"'));
      expect(error, contains('running:, done: or failed:'));
    });

    test('a status without a running value is an error', () async {
      final error = await _buildError(_source(enumValues: 'done, failed'));
      expect(error, contains('no value of Status means running'));
    });

    test('a nullable or non-enum status is an error', () async {
      final nullable = await _buildError(_source(statusType: 'Status?')
          .replaceAll('required this.status', 'this.status'));
      expect(nullable, contains('must not be nullable'));
      final text = await _buildError(_source(statusType: 'String'));
      expect(text, contains('must be of an enum type'));
    });

    test('a value in two states, an unknown value or message are errors',
        () async {
      final both = await _buildError(_source(
        status: '@JobStatus(running: {Status.done}, done: {Status.done})\n'
            '  @Field()',
      ));
      expect(both, contains('"done" is in both running and done'));
      final unknown = await _buildError(_source(
        status: "@JobStatus(message: 'nope')\n  @Field()",
      ));
      expect(unknown, contains('message: "nope" is not a field'));
    });

    test('two status fields are an error', () async {
      final error = await _buildError(_source(
        extraFields: '@JobStatus()\n  final Status other;\n'
            '  final String? error;',
      ).replaceAll('this.error}', 'this.error, required this.other}'));
      expect(error, contains('more than one @JobStatus field'));
    });
  });

  group('PF-57 AC#2 - providers refresh while a job runs', () {
    test('the list notifier polls through a PrefabJobPoller', () async {
      await _expectOutput(
        _source(),
        allOf([
          has('late final _jobPoller = PrefabJobPoller('),
          has('interval: const Duration(seconds: 3),'),
          has('item.status == Status.queued'),
          has('ref.onDispose(_jobPoller.cancel);'),
          has('listenSelf((previous, next) => _jobPoller.check());'),
          has('Future<void> _refreshJobs() async {'),
          has('state = AsyncData(await _client.list('),
        ]),
      );
    });

    test('the detail provider polls while the job runs', () async {
      await _expectOutput(
        _source(),
        allOf([
          has('StreamProvider.autoDispose'),
          has('prefabPolledDetail<Report>('),
          has('isRunning: (report) =>'),
          has('load: () => client.getById(id),'),
        ]),
      );
    });

    test('the poll interval is configurable', () async {
      await _expectOutput(
        _source(
          status: '@JobStatus(pollInterval: Duration(milliseconds: 1500))\n'
              '  @Field()',
        ),
        has('interval: const Duration(milliseconds: 1500),'),
      );
      await _expectOutput(
        _source(
          status: '@JobStatus(pollInterval: Duration(minutes: 1))\n  @Field()',
        ),
        has('interval: const Duration(seconds: 60),'),
      );
    });

    test('a streaming entity follows live events and does not poll',
        () async {
      await _expectOutput(
        _source(entityAnnotations: '@Streaming()'),
        allOf([
          has('prefabLiveDetail<Report>'),
          lacks('prefabPolledDetail'),
          lacks('PrefabJobPoller'),
          has('PrefabJobBanner('),
          has('PrefabJobIndicator('),
        ]),
      );
    });

    test('a nested entity polls with its ancestor ids', () async {
      final source = '''
import 'package:prefab_flutter/prefab_flutter.dart';

enum Status { running, done }

@Entity()
class Site {
  final int id;
  @Field()
  final String name;
  Site({required this.id, required this.name});
  factory Site.fromJson(Map<String, dynamic> json) => throw 0;
  Map<String, dynamic> toJson() => {};
}

@Entity()
class Report {
  final int? id;
  @Parent(Site)
  @Field(on: {})
  final int siteId;
  @JobStatus()
  @Field()
  final Status status;
  Report({this.id, required this.siteId, required this.status});
  factory Report.fromJson(Map<String, dynamic> json) => throw 0;
  Map<String, dynamic> toJson() => {};
}
''';
      await _expectOutput(
        source,
        allOf([
          has('client.getById(args.\$1, siteId: args.\$2)'),
          has('state = AsyncData(await _client.list(siteId: siteId'),
        ]),
      );
    });
  });

  group('PF-57 operations that start a job', () {
    test('a list item opens the job after the operation ran', () async {
      await _expectOutput(
        _source(
          annotations: "@Update(path: 'regenerate', startsJob: true, "
              'on: {Place.item, Place.detail})',
        ),
        allOf([
          has(').then((started) {'),
          has('if (started == true && context.mounted)'),
          has("context.push('/reports/\${report.id!}');"),
        ]),
      );
    });

    test('an operation with parameters tells its list item that it saved',
        () async {
      final source = '''
import 'package:prefab_flutter/prefab_flutter.dart';

enum Status { running, done }

class Options {
  @Field(label: 'Language')
  final String language;
  const Options({required this.language});
  Map<String, dynamic> toJson() => {'language': language};
}

@Entity()
@Update(path: 'regenerate', parameters: Options, startsJob: true, on: {Place.item})
class Report {
  final int? id;
  @JobStatus()
  @Field()
  final Status status;
  Report({this.id, required this.status});
  factory Report.fromJson(Map<String, dynamic> json) => throw 0;
  Map<String, dynamic> toJson() => {};
}
''';
      await _expectOutput(
        source,
        allOf([
          has("context.push<bool>('/reports/\${report.id!}/regenerate')"),
          has('context.pop(true);'),
        ]),
      );
    });

    test('startsJob needs a @JobStatus field', () async {
      final error = await _buildError(_source(
        status: '@Field()',
        annotations: "@Update(path: 'regenerate', startsJob: true)",
      ));
      expect(error, contains('startsJob: true needs a field annotated with '
          '@JobStatus'));
    });

    test('startsJob is only for named operations', () async {
      final error = await _buildError(
          _source(entityAnnotations: '@Update(startsJob: true)'));
      expect(error, contains('startsJob without a path'));
    });
  });
}
