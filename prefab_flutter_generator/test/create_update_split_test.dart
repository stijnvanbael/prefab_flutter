import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:prefab_flutter_generator/builder.dart';
import 'package:test/test.dart';
import 'support/prefab_sources.dart';

// ---------------------------------------------------------------------------
// Shared annotation stubs included in every test's source assets.
// These mirror the actual prefab_flutter package sources so the Dart resolver
// can resolve `package:prefab_flutter/...` imports inside the test sources.
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// Test entity sources
// ---------------------------------------------------------------------------

/// A fully-annotated entity with @Update and @Delete.

String _entity(String annotations) => """
import 'package:prefab_flutter/prefab_flutter.dart';

@View(title: 'Log', path: 'logs')
$annotations
class Log {
  final int? id;

  @Field(label: 'Message')
  final String message;

  Log({this.id, required this.message});

  factory Log.fromJson(Map<String, dynamic> json) =>
      Log(id: json['id'] as int?, message: json['message'] as String);

  Map<String, dynamic> toJson() => {'id': id, 'message': message};
}
""";

Map<String, Object> _assets(String annotations) => {
      ...Map<String, Object>.from(prefabSources),
      'a|lib/log.dart': _entity(annotations),
    };

void main() {
  group('PF-14 @Create / @Update split', () {
    test('create-only: create screen, route, FAB, provider and client', () async {
      final assets = _assets('@Create()');
      await testBuilder(formScreenBuilder(BuilderOptions.empty), assets, outputs: {
        'a|lib/log.form_screen.dart': decodedMatches(allOf(
            contains('class LogCreateScreen'),
            isNot(contains('class LogEditScreen')))),
      });
      await testBuilder(routesBuilder(BuilderOptions.empty), assets, outputs: {
        'a|lib/log.routes.dart': decodedMatches(allOf(
            contains("path: 'create'"), isNot(contains("path: 'edit'")))),
      });
      await testBuilder(listScreenBuilder(BuilderOptions.empty), assets, outputs: {
        'a|lib/log.list_screen.dart':
            decodedMatches(contains('FloatingActionButton')),
      });
      await testBuilder(detailScreenBuilder(BuilderOptions.empty), assets,
          outputs: {
            'a|lib/log.detail_screen.dart':
                decodedMatches(isNot(contains('Icons.edit'))),
          });
      await testBuilder(providerBuilder(BuilderOptions.empty), assets, outputs: {
        'a|lib/log.provider.dart': decodedMatches(allOf(
            contains('Future<void> create('),
            isNot(contains('Future<void> updateEntity(')))),
      });
      await testBuilder(apiClientBuilder(BuilderOptions.empty), assets, outputs: {
        'a|lib/log.api_client.dart': decodedMatches(allOf(
            contains('Future<Log> create('),
            isNot(contains('Future<Log> update(')))),
      });
    });

    test('update-only: edit screen, route, provider and client', () async {
      final assets = _assets('@Update()');
      await testBuilder(formScreenBuilder(BuilderOptions.empty), assets, outputs: {
        'a|lib/log.form_screen.dart': decodedMatches(allOf(
            contains('class LogEditScreen'),
            isNot(contains('class LogCreateScreen')))),
      });
      await testBuilder(routesBuilder(BuilderOptions.empty), assets, outputs: {
        'a|lib/log.routes.dart': decodedMatches(allOf(
            contains("path: 'edit'"), isNot(contains("path: 'create'")))),
      });
      await testBuilder(listScreenBuilder(BuilderOptions.empty), assets, outputs: {
        'a|lib/log.list_screen.dart':
            decodedMatches(isNot(contains('FloatingActionButton'))),
      });
      await testBuilder(detailScreenBuilder(BuilderOptions.empty), assets,
          outputs: {
            'a|lib/log.detail_screen.dart':
                decodedMatches(contains('/edit')),
          });
      await testBuilder(providerBuilder(BuilderOptions.empty), assets, outputs: {
        'a|lib/log.provider.dart': decodedMatches(allOf(
            contains('Future<void> updateEntity('),
            isNot(contains('Future<void> create(')))),
      });
      await testBuilder(apiClientBuilder(BuilderOptions.empty), assets, outputs: {
        'a|lib/log.api_client.dart': decodedMatches(allOf(
            contains('Future<Log> update('),
            isNot(contains('Future<Log> create(')))),
      });
    });

    test('read-only: no form screen, no create/edit routes', () async {
      final assets = _assets('');
      await testBuilder(formScreenBuilder(BuilderOptions.empty), assets,
          outputs: {});
      await testBuilder(routesBuilder(BuilderOptions.empty), assets, outputs: {
        'a|lib/log.routes.dart': decodedMatches(allOf(
            isNot(contains("path: 'create'")),
            isNot(contains("path: 'edit'")))),
      });
    });
  });
}
