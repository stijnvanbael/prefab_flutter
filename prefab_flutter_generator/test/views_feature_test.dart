import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:prefab_flutter_generator/builder.dart';
import 'package:test/test.dart';

import 'support/prefab_sources.dart';

const _source = '''
import 'package:prefab_flutter/prefab_flutter.dart';

@View(title: 'Products', path: 'products')
class Product {
  @Id()
  final String id;
  @Field(views: {'list', 'detail'})
  final String name;
  @Field(views: {'list'})
  final String sku;
  @Field(views: {'detail'})
  final String notes;
  Product(this.id, this.name, this.sku, this.notes);
}
''';

void main() {
  test('PF-64 AC#1 - list tile slots and detail fields follow views', () async {
    await testBuilder(
      listScreenBuilder(BuilderOptions.empty),
      {...prefabSources, 'a|lib/product.dart': _source},
      outputs: {
        'a|lib/product.list_screen.dart': decodedMatches(allOf(
          contains('title: Text(product.name.toString())'),
          contains('subtitle: Text(product.sku.toString())'),
          isNot(contains('product.notes')),
        )),
      },
      onLog: (_) {},
    );
    await testBuilder(
      detailScreenBuilder(BuilderOptions.empty),
      {...prefabSources, 'a|lib/product.dart': _source},
      outputs: {
        'a|lib/product.detail_screen.dart': decodedMatches(allOf(
          contains('product.notes'),
          isNot(contains('product.sku')),
        )),
      },
      onLog: (_) {},
    );
  });
}
