import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:prefab_flutter_generator/builder.dart';
import 'package:test/test.dart';

import 'support/prefab_sources.dart';

String _source({String versionField = 'final int? version;'}) => '''
import 'package:prefab_flutter/prefab_flutter.dart';

@Entity(title: 'Item', path: 'items')
@Update()
class Item {
  final int? id;
  $versionField
  @Field()
  final String name;
  Item({this.id, this.version, required this.name});
  factory Item.fromJson(Map<String, dynamic> json) => throw 0;
  Map<String, dynamic> toJson() => {};
}
''';

Map<String, Object> _assets(String source) => {
      ...Map<String, Object>.from(prefabSources),
      'a|lib/item.dart': source,
    };

void main() {
  group('@Version (PF-52)', () {
    test('the update sends the version through the backend', () async {
      await testBuilder(
        apiClientBuilder(BuilderOptions.empty),
        _assets(_source()),
        outputs: {
          'a|lib/item.api_client.dart': decodedMatches(allOf(
            contains("_adapter.updateBody(item.toJson(), versionKey: 'version')"),
            contains('options: _adapter.updateOptions(item.version)'),
          )),
        },
      );
    });

    test('a field named version is used without @Version', () async {
      await testBuilder(
        apiClientBuilder(BuilderOptions.empty),
        _assets(_source(versionField: 'final int? version;')),
        outputs: {
          'a|lib/item.api_client.dart':
              decodedMatches(contains('updateOptions(item.version)')),
        },
      );
    });

    test('@Version marks a field of any name', () async {
      await testBuilder(
        apiClientBuilder(BuilderOptions.empty),
        _assets(_source(versionField: '@Version()\n  final int? rev;')
            .replaceAll('this.version', 'this.rev')),
        outputs: {
          'a|lib/item.api_client.dart': decodedMatches(allOf(
            contains("versionKey: 'rev'"),
            contains('updateOptions(item.rev)'),
          )),
        },
      );
    });

    test('an entity without a version is not locked', () async {
      await testBuilder(
        apiClientBuilder(BuilderOptions.empty),
        _assets(_source(versionField: '')
            .replaceAll('this.version, ', '')),
        outputs: {
          'a|lib/item.api_client.dart': decodedMatches(allOf(
            contains('data: item.toJson())'),
            isNot(contains('updateBody')),
          )),
        },
      );
    });

    test('the edit screen resolves a conflict; the version is no form field',
        () async {
      await testBuilder(
        formScreenBuilder(BuilderOptions.empty),
        _assets(_source()),
        outputs: {
          'a|lib/item.form_screen.dart': decodedMatches(allOf(
            contains('error.isConflict'),
            contains('showPrefabConflictDialog(context)'),
            contains('ref.refresh('),
            contains('version: _item!.version'),
            isNot(contains('_versionController')),
          )),
        },
      );
    });
  });
}
