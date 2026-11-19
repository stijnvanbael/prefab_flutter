import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:prefab_flutter_generator/builder.dart';
import 'package:test/test.dart';

// ---------------------------------------------------------------------------
// Shared annotation stubs
// ---------------------------------------------------------------------------

const _prefabSources = {
  'prefab_flutter|lib/prefab_flutter.dart': r'''
export 'src/annotations/view.dart';
export 'src/annotations/update.dart';
export 'src/annotations/delete.dart';
export 'src/annotations/form_field.dart';
export 'src/annotations/parent.dart';
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
  final Type type;
  const Parent(this.type);
}
''',
  'prefab_flutter|lib/src/enums/field_widget.dart': r'''
enum FieldWidget { auto, multilineText, password, datePicker, dropdown, toggle }
''',
  'prefab_flutter|lib/src/enums/validator.dart': r'''
enum Validator { required, email, positiveNumber, url }
''',
};

// ---------------------------------------------------------------------------
// Test entity sources
// ---------------------------------------------------------------------------

const _productSource = r'''
import 'package:prefab_flutter/prefab_flutter.dart';

@View(title: 'Product', path: 'products')
@Update()
@Delete()
class Product {
  final int? id;

  @FormField(label: 'Name')
  final String name;

  Product({this.id, required this.name});

  factory Product.fromJson(Map<String, dynamic> json) =>
      Product(id: json['id'] as int?, name: json['name'] as String);

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}
''';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Map<String, Object> _assets(String pkg, String path, String source) => {
      ...Map<String, Object>.from(_prefabSources),
      '$pkg|$path': source,
    };

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('PrefabGenerator', () {
    test('generates one combined library with merged imports', () async {
      await testBuilder(
        prefabBuilder(BuilderOptions.empty),
        _assets('a', 'lib/product.dart', _productSource),
        outputs: {
          'a|lib/product.prefab.dart': decodedMatches(allOf([
            contains('class ProductListScreen'),
            contains('class ProductDetailScreen'),
            contains('class ProductCreateScreen'),
            contains('class ProductEditScreen'),
            contains('class ProductApiClient'),
            contains('productsProvider'),
            contains('\$productRoutes'),
            contains("import 'product.dart';"),
            isNot(contains('product.provider.dart')),
            isNot(contains('product.api_client.dart')),
            isNot(contains('product.detail_screen.dart')),
            isNot(contains('product.list_screen.dart')),
            isNot(contains('product.form_screen.dart')),
          ])),
        },
      );
    });

    test('imports are not duplicated', () async {
      await testBuilder(
        prefabBuilder(BuilderOptions.empty),
        _assets('a', 'lib/product.dart', _productSource),
        outputs: {
          'a|lib/product.prefab.dart': decodedMatches(predicate<String>((s) {
            final lines =
                s.split('\n').where((l) => l.startsWith('import ')).toList();
            return lines.length == lines.toSet().length;
          }, 'has no duplicate imports')),
        },
      );
    });

    test('generates nothing for a file without @View', () async {
      await testBuilder(
        prefabBuilder(BuilderOptions.empty),
        _assets('a', 'lib/plain.dart', 'class Plain {}'),
        outputs: {},
      );
    });
  });
}
