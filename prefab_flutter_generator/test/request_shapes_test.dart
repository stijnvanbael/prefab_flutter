import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:prefab_flutter_generator/builder.dart';
import 'package:test/test.dart';

import 'support/prefab_sources.dart';

const _source = r'''
import 'package:prefab_flutter/prefab_flutter.dart';

enum State { open, closed }

@Entity(title: 'Ticket', path: 'tickets')
@Create()
@Update()
class Ticket {
  final int? id;

  @Field(label: 'Title')
  final String title;

  @Field(form: FormOptions(on: {FormMode.create}))
  final String reporter;

  @Field(form: FormOptions(on: {FormMode.update}))
  final String? resolution;

  @Field(readOnly: true)
  final DateTime created;

  @Field(readOnly: true)
  final State state;

  Ticket({
    this.id,
    required this.title,
    required this.reporter,
    this.resolution,
    required this.created,
    required this.state,
  });
  factory Ticket.fromJson(Map<String, dynamic> json) => throw 0;
  Map<String, dynamic> toJson() => {};
}
''';

Map<String, Object> get _assets => {
      ...Map<String, Object>.from(prefabSources),
      'a|lib/ticket.dart': _source,
    };

void main() {
  group('PF-53 create and update request shapes', () {
    test('the create body holds only the create form fields', () async {
      await testBuilder(apiClientBuilder(BuilderOptions.empty), _assets,
          outputs: {
            'a|lib/ticket.api_client.dart': decodedMatches(allOf(
              contains('data: _createBody(ticket)'),
              contains("const <String>{'title', 'reporter'}.contains(e.key)"),
            )),
          });
    });

    test('the update body leaves out read-only and create-only fields',
        () async {
      await testBuilder(apiClientBuilder(BuilderOptions.empty), _assets,
          outputs: {
            'a|lib/ticket.api_client.dart': decodedMatches(allOf(
              contains('data: _updateBody(ticket)'),
              contains(
                  "!const <String>{'reporter', 'created', 'state'}.contains(e.key)"),
            )),
          });
    });

    test('forms contain only the fields of their mode, never read-only ones',
        () async {
      await testBuilder(formScreenBuilder(BuilderOptions.empty), _assets,
          outputs: {
            'a|lib/ticket.form_screen.dart': decodedMatches(predicate<String>(
                (code) {
              final create = code.substring(
                  code.indexOf('class _TicketCreateScreenState'),
                  code.indexOf('class TicketEditScreen'));
              final edit =
                  code.substring(code.indexOf('class _TicketEditScreenState'));
              return create.contains('_reporterController') &&
                  !create.contains('_resolutionController') &&
                  edit.contains('_resolutionController') &&
                  !edit.contains('_reporterController') &&
                  !create.contains('_createdValue') &&
                  !edit.contains('_stateValue');
            }, 'create and edit forms differ')),
          });
    });

    test('server-set required values get placeholders on create', () async {
      await testBuilder(formScreenBuilder(BuilderOptions.empty), _assets,
          outputs: {
            'a|lib/ticket.form_screen.dart': decodedMatches(allOf(
              contains('created: DateTime.fromMillisecondsSinceEpoch(0)'),
              contains('state: State.values.first'),
            )),
          });
    });
  });
}
