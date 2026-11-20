import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:prefab_flutter_generator/builder.dart';
import 'package:test/test.dart';

import 'support/prefab_sources.dart';

String _source(String annotations, {String extra = ''}) => '''
import 'package:prefab_flutter/prefab_flutter.dart';

class Reason {
  @Field(form: FormOptions(validators: [Validator.required]))
  final String text;
  const Reason({required this.text});
  Map<String, dynamic> toJson() => {'text': text};
}

class NoJson {
  @Field()
  final String text;
  const NoJson({required this.text});
}

$extra

@Entity(title: 'Invoice', path: 'invoices')
$annotations
class Invoice {
  final int? id;
  @Field()
  final String number;
  Invoice({this.id, required this.number});
  factory Invoice.fromJson(Map<String, dynamic> json) => throw 0;
  Map<String, dynamic> toJson() => {};
}
''';

Map<String, Object> _assets(String source) => {
      ...Map<String, Object>.from(prefabSources),
      'a|lib/invoice.dart': source,
    };

/// Runs the builder and returns everything it logged plus any thrown error.
Future<String> _buildError(String annotations, {String extra = ''}) async {
  final logs = <String>[];
  try {
    await testBuilder(
      prefabBuilder(BuilderOptions.empty),
      _assets(_source(annotations, extra: extra)),
      onLog: (r) => logs.add('${r.message} ${r.error ?? ''}'),
    );
  } catch (e) {
    logs.add(e.toString());
  }
  return logs.join('\n');
}

void main() {
  group('PF-54 named operations', () {
    test('AC#1 the API client calls {path}/{id}/{operation} through the backend',
        () async {
      await testBuilder(
        apiClientBuilder(BuilderOptions.empty),
        _assets(_source("@Update(path: 'send')\n@Update(path: 'mark-paid')")),
        outputs: {
          'a|lib/invoice.api_client.dart': decodedMatches(allOf([
            contains('Future<void> send(int id) async'),
            contains("'/invoices/\${_adapter.encodeId(id)}/send'"),
            contains('Future<void> markPaid(int id) async'),
            contains("'/invoices/\${_adapter.encodeId(id)}/mark-paid'"),
            contains('data: _adapter.operationBody(null)'),
            contains('options: Options(method: _adapter.operationMethod)'),
          ])),
        },
      );
    });

    test('a named operation does not make the entity editable', () async {
      await testBuilder(
        prefabBuilder(BuilderOptions.empty),
        _assets(_source("@Update(path: 'send')")),
        outputs: {
          'a|lib/invoice.prefab.dart': decodedMatches(allOf(
            isNot(contains('InvoiceEditScreen')),
            isNot(contains('Future<Invoice> update(')),
          )),
        },
      );
    });

    test('AC#2 an operation without parameters is a confirmed action', () async {
      await testBuilder(
        prefabBuilder(BuilderOptions.empty),
        _assets(_source(
            "@Update(path: 'send', label: 'Send it', icon: 'send', confirm: 'Send the invoice?', on: {Place.detail, Place.item})")),
        outputs: {
          'a|lib/invoice.prefab.dart': decodedMatches(allOf([
            contains("tooltip: 'Send it'"),
            contains('Icons.send'),
            contains("confirm: 'Send the invoice?'"),
            contains('runPrefabOperation('),
            contains('ref.read(invoicesProvider.notifier).send(id)'),
            contains('.send(invoice.id!)'),
          ])),
        },
      );
    });

    test('AC#4 the notifier refreshes the entity and the list', () async {
      await testBuilder(
        prefabBuilder(BuilderOptions.empty),
        _assets(_source("@Update(path: 'send')")),
        outputs: {
          'a|lib/invoice.prefab.dart': decodedMatches(contains(
              'Future<void> send(int id) async {\n'
              '    await _client.send(id);\n'
              '    ref.invalidate(invoiceDetailProvider(id));\n'
              '    await _load();')),
        },
      );
    });

    test('AC#3 an operation with parameters opens a generated form', () async {
      await testBuilder(
        prefabBuilder(BuilderOptions.empty),
        _assets(_source("@Update(path: 'reject', parameters: Reason)")),
        outputs: {
          'a|lib/invoice.prefab.dart': decodedMatches(allOf([
            contains('class InvoiceRejectScreen extends ConsumerStatefulWidget'),
            contains('final parameters = Reason('),
            contains('.reject(widget.id, parameters)'),
            contains('_textController'),
            contains("return 'Required'"),
            contains("context.push('/invoices/\$id/reject')"),
            contains("path: 'reject'"),
            contains('Future<void> reject(int id, Reason parameters)'),
            contains('data: _adapter.operationBody(parameters.toJson())'),
          ])),
        },
      );
    });

    test('invalid declarations fail the build with a message', () async {
      Future<void> fails(String annotations, String message) async =>
          expect(await _buildError(annotations), contains(message));

      await fails("@Update(label: 'Send')", 'without a path');
      await fails("@Update(path: 'send')\n@Update(path: 'send')", 'twice');
      await fails("@Update(path: 'edit')", 'taken by the generated code');
      await fails("@Update(path: 'delete')", 'taken by the generated code');
      await fails("@Update(path: 'Not valid')", 'one URL segment');
      await fails(
          "@Update(path: 'x', on: {Place.form})", 'Place.detail and Place.item');
      await fails("@Update(path: 'x', parameters: NoJson)", 'toJson()');
    });
  });
}
