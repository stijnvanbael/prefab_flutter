import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:prefab_flutter_generator/builder.dart';
import 'package:test/test.dart';

const _prefabSources = {
  'prefab_flutter|lib/prefab_flutter.dart': r'''
export 'src/annotations/view.dart';
export 'src/annotations/update.dart';
export 'src/annotations/delete.dart';
export 'src/annotations/form_field.dart';
export 'src/annotations/parent.dart';
export 'src/annotations/id.dart';
export 'src/enums/field_widget.dart';
export 'src/enums/validator.dart';
''',
  'prefab_flutter|lib/src/annotations/view.dart': r'''
class View {
  final String title;
  final String path;
  const View({required this.title, required this.path});
}
''',
  'prefab_flutter|lib/src/annotations/update.dart': r'''
class Update {
  const Update();
}
''',
  'prefab_flutter|lib/src/annotations/delete.dart': r'''
class Delete {
  const Delete();
}
''',
  'prefab_flutter|lib/src/annotations/form_field.dart': r'''
import 'package:prefab_flutter/src/enums/field_widget.dart';
import 'package:prefab_flutter/src/enums/validator.dart';
class FormField {
  final String? label;
  final FieldWidget widget;
  final List<Validator> validators;
  final bool hidden;
  const FormField({
    this.label,
    this.widget = FieldWidget.auto,
    this.validators = const [],
    this.hidden = false,
  });
}
''',
  'prefab_flutter|lib/src/annotations/parent.dart': r'''
class Parent {
  const Parent();
}
''',
  'prefab_flutter|lib/src/annotations/id.dart': r'''
class Id {
  const Id();
}
''',
  'prefab_flutter|lib/src/enums/field_widget.dart': r'''
enum FieldWidget { auto, multilineText, password, datePicker, dropdown, toggle }
''',
  'prefab_flutter|lib/src/enums/validator.dart': r'''
enum Validator { required, email, positiveNumber, url }
''',
};

const _stringIdSource = r'''
import 'package:prefab_flutter/prefab_flutter.dart';

@View(title: 'Item', path: 'items')
@Update()
class Item {
  @Id()
  final String sku;
  @FormField()
  final String name;
  Item({required this.sku, required this.name});
}
''';

const _noIdSource = r'''
import 'package:prefab_flutter/prefab_flutter.dart';

@View(title: 'Item', path: 'items')
class Item {
  @FormField()
  final String name;
  Item({required this.name});
}
''';

const _intIdSource = r'''
import 'package:prefab_flutter/prefab_flutter.dart';

@View(title: 'Item', path: 'items')
@Update()
class Item {
  final int id;
  @FormField()
  final String name;
  Item({required this.id, required this.name});
}
''';

Map<String, Object> _assets(String source) => {
      ...Map<String, Object>.from(_prefabSources),
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
          'a|lib/item.form_screen.dart': decodedMatches(
            isNot(contains('sku')),
          ),
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
