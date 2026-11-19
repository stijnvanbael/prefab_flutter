import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:prefab_flutter_generator/builder.dart';
import 'package:test/test.dart';
import 'support/prefab_sources.dart';

const _stringIdSource = r'''
import 'package:prefab_flutter/prefab_flutter.dart';

@View(title: 'Item', path: 'items')
@Create()
@Update()
class Item {
  @Id()
  final String? sku;
  @Field()
  final String name;
  Item({this.sku, required this.name});
  factory Item.fromJson(Map<String, dynamic> json) => throw 0;
  Map<String, dynamic> toJson() => {};

}
''';

const _noIdSource = r'''
import 'package:prefab_flutter/prefab_flutter.dart';

@View(title: 'Item', path: 'items')
class Item {
  @Field()
  final String name;
  Item({required this.name});
  factory Item.fromJson(Map<String, dynamic> json) => throw 0;
  Map<String, dynamic> toJson() => {};

}
''';

const _intIdSource = r'''
import 'package:prefab_flutter/prefab_flutter.dart';

@View(title: 'Item', path: 'items')
@Create()
@Update()
class Item {
  final int? id;
  @Field()
  final String name;
  Item({this.id, required this.name});
  factory Item.fromJson(Map<String, dynamic> json) => throw 0;
  Map<String, dynamic> toJson() => {};

}
''';

Map<String, Object> _assets(String source) => {
      ...Map<String, Object>.from(prefabSources),
      'a|lib/item.dart': source,
    };

void main() {
  group('@Id', () {
    test('int id is parsed in routes', () async {
      await testBuilder(
        routesBuilder(BuilderOptions.empty),
        _assets(_intIdSource),
        outputs: {
          'a|lib/item.routes.dart': decodedMatches(
            contains("id: int.parse(state.pathParameters['id']!)"),
          ),
        },
      );
    });

    test('String @Id is passed as-is to routes and typed in the client',
        () async {
      await testBuilder(
        routesBuilder(BuilderOptions.empty),
        _assets(_stringIdSource),
        outputs: {
          'a|lib/item.routes.dart': decodedMatches(allOf(
            contains("id: state.pathParameters['id']!"),
            isNot(contains('int.parse')),
          )),
        },
      );
      await testBuilder(
        apiClientBuilder(BuilderOptions.empty),
        _assets(_stringIdSource),
        outputs: {
          'a|lib/item.api_client.dart': decodedMatches(allOf(
            contains('getById(String id)'),
            contains(r'${item.sku}'),
          )),
        },
      );
    });

    test('@Id field is not a form field', () async {
      await testBuilder(
        formScreenBuilder(BuilderOptions.empty),
        _assets(_stringIdSource),
        outputs: {
          'a|lib/item.form_screen.dart': decodedMatches(allOf(
            isNot(contains('_skuController')),
            // The id is copied from the route on edit and omitted on create.
            contains('sku: widget.id'),
          )),
        },
      );
    });

    test('missing id is a build-time error', () async {
      final logs = <String>[];
      Object? error;
      try {
        await testBuilder(
          routesBuilder(BuilderOptions.empty),
          _assets(_noIdSource),
          outputs: {},
          onLog: (r) => logs.add(r.message),
        );
      } catch (e) {
        error = e;
      }
      expect('$error\n${logs.join('\n')}', contains('has no identifier'));
    });
  });
}
