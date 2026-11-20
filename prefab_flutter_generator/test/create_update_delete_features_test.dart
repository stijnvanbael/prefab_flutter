import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:prefab_flutter_generator/builder.dart';
import 'package:prefab_flutter_generator/src/features/create/create_feature.dart';
import 'package:prefab_flutter_generator/src/features/delete/delete_feature.dart';
import 'package:prefab_flutter_generator/src/features/features.dart';
import 'package:prefab_flutter_generator/src/features/update/update_feature.dart';
import 'package:test/test.dart';

import 'support/prefab_sources.dart';

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
  group('PF-63 create, update and delete feature modules', () {
    test('are registered alphabetically with the other features', () {
      final names = [for (final f in registeredFeatures) f.name];
      expect(names, containsAll(['create', 'delete', 'update']));
      expect(names, [...names]..sort());
    });

    test('create and update add the screens, delete adds none', () {
      expect(const CreateFeature().artifacts, hasLength(1));
      expect(const UpdateFeature().artifacts, hasLength(1));
      expect(const DeleteFeature().artifacts, isEmpty);
    });

    test('the combined library keeps the order of the artifacts', () async {
      await testBuilder(
        prefabBuilder(BuilderOptions.empty),
        _assets('@Create()\n@Update()\n@Delete()'),
        outputs: {
          'a|lib/log.prefab.dart': decodedMatches(predicate<String>((text) {
            final order = [
              'class LogApiClient',
              'final logDetailProvider',
              'final logsProvider',
              'final logApiClientProvider',
              'class LogDetailScreen',
              'class LogListScreen',
              'class LogCreateScreen',
              'class LogEditScreen',
              r'get $logRoutes',
            ].map(text.indexOf).toList();
            return !order.contains(-1) &&
                order.toString() == ([...order]..sort()).toString();
          }, 'declares the artifacts in order')),
        },
      );
    });

    test('contributions land on the extension points', () async {
      await testBuilder(
        prefabBuilder(BuilderOptions.empty),
        _assets('@Create()\n@Update()\n@Delete()'),
        outputs: {
          'a|lib/log.prefab.dart': decodedMatches(allOf([
            contains('Future<Log> create(Log log)'),
            contains('Future<Log> update(Log log)'),
            contains('Future<void> delete(Log log)'),
            contains('Future<void> updateEntity(Log log)'),
            contains("tooltip: 'Create Log'"),
            contains("tooltip: 'Edit'"),
            contains("tooltip: 'Delete'"),
            contains("path: 'create'"),
            contains("path: 'edit'"),
          ])),
        },
      );
    });

    test('without annotations only the API client delete remains', () async {
      await testBuilder(
        prefabBuilder(BuilderOptions.empty),
        _assets(''),
        outputs: {
          'a|lib/log.prefab.dart': decodedMatches(allOf([
            contains('Future<void> delete(Log log)'),
            isNot(contains('Future<Log> create(')),
            isNot(contains('Future<Log> update(')),
            isNot(contains('updateEntity')),
            isNot(contains('FloatingActionButton')),
            isNot(contains('Icons.edit')),
            isNot(contains('Icons.delete')),
            isNot(contains('CreateScreen')),
            isNot(contains('EditScreen')),
          ])),
        },
      );
    });

    test('a per-kind generator does not emit the screens of the features',
        () async {
      await testBuilder(
        apiClientBuilder(BuilderOptions.empty),
        _assets('@Create()\n@Update()'),
        outputs: {
          'a|lib/log.api_client.dart': decodedMatches(allOf(
            contains('class LogApiClient'),
            contains('Future<Log> create('),
            isNot(contains('CreateScreen')),
            isNot(contains('EditScreen')),
          )),
        },
      );
    });
  });
}
