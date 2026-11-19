import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:prefab_flutter_generator/builder.dart';
import 'package:test/test.dart';
import 'support/prefab_sources.dart';

// ---------------------------------------------------------------------------
// Test entity sources
// ---------------------------------------------------------------------------

const _productSource = r'''
import 'package:prefab_flutter/prefab_flutter.dart';

@View(title: 'Product', path: 'products')
@Create()
@Update()
@Delete()
class Product {
  final int? id;

  @Field(label: 'Name')
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
      ...Map<String, Object>.from(prefabSources),
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
