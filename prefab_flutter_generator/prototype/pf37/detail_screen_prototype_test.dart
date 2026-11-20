// PF-37 prototype test. Not run by CI (`dart test` only runs test/).
// Run with: dart test prototype/pf37
//
// Generates the detail screen with today's DetailScreenGenerator and with
// the prototype (artifact + extension points + feature modules) and checks
// that both produce the same imports and the same code.

import 'dart:convert';
import 'dart:io';

import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:prefab_flutter_generator/builder.dart';
import 'package:test/test.dart';

import 'core/library_emitter.dart';
import 'detail_screen_prototype.dart';

/// The real annotation sources (as PF-36 plans for all tests).
Map<String, String> _prefabSources() {
  final root = Directory('../prefab_flutter/lib');
  return {
    for (final f in root.listSync(recursive: true).whereType<File>())
      if (f.path.endsWith('.dart'))
        'prefab_flutter|lib/${f.path.substring(root.path.length + 1)}':
            f.readAsStringSync(),
  };
}

Future<String> _generate(Builder builder, Map<String, String> sources,
    String input, String extension) async {
  final writer = InMemoryAssetWriter();
  await testBuilder(builder, {..._prefabSources(), ...sources}, writer: writer);
  final id = AssetId('a', input.replaceFirst('.dart', extension));
  final bytes = writer.assets[id];
  return bytes == null ? '' : utf8.decode(bytes);
}

/// Splits generated code into its set of imports and its code (comments and
/// surrounding blank lines dropped). Only the import order differs today:
/// the per-generator output is unsorted, the merged file sorts imports.
({Set<String> imports, String code}) _normalise(String output) {
  final lines = output.split('\n');
  return (
    imports: lines.where((l) => l.startsWith('import ')).toSet(),
    code: lines
        .where((l) => !l.startsWith('import ') && !l.startsWith('//'))
        .join('\n')
        .trim(),
  );
}

const _scenarios = <String, Map<String, String>>{
  'minimal': {
    'a|lib/product.dart': '''
import 'package:prefab_flutter/prefab_flutter.dart';

@View(title: 'Products', path: 'products')
class Product {
  final String id;
  @Field()
  final String name;
  @Field(label: 'Notes')
  final String? notes;
  const Product({required this.id, required this.name, this.notes});
}
''',
  },
  'update, delete and views': {
    'a|lib/product.dart': '''
import 'package:prefab_flutter/prefab_flutter.dart';

@View(title: 'Products', path: 'products')
@Update()
@Delete()
class Product {
  @Id()
  final int? productId;
  @Field(views: {'list'})
  final String name;
  @Field(views: {'detail'})
  final double price;
  @Field(hidden: true)
  final String secret;
  const Product({this.productId, required this.name, required this.price, required this.secret});
}
''',
  },
  'three-level parent chain with breadcrumbs': {
    'a|lib/order.dart': '''
import 'package:prefab_flutter/prefab_flutter.dart';

@View(title: 'Orders', path: 'orders')
class Order {
  final int id;
  @Field()
  final String number;
  const Order({required this.id, required this.number});
}

@View(title: 'Lines', path: 'lines')
class OrderLine {
  final int id;
  @Field()
  @Parent(Order)
  final int orderId;
  @Field()
  final String product;
  const OrderLine({required this.id, required this.orderId, required this.product});
}

@View(title: "Note's", path: 'notes')
@Update()
@Delete()
class LineNote {
  final int id;
  @Field()
  @Parent(OrderLine)
  final int lineId;
  @Field()
  final String? text;
  const LineNote({required this.id, required this.lineId, this.text});
}
''',
  },
};

void main() {
  for (final MapEntry(key: name, value: sources) in _scenarios.entries) {
    test('prototype matches DetailScreenGenerator: $name', () async {
      final input = sources.keys.single.split('|').last;
      final today = _normalise(await _generate(
          detailScreenBuilder(BuilderOptions.empty),
          sources,
          input,
          '.detail_screen.dart'));
      final prototype = _normalise(await _generate(
          detailScreenPrototypeBuilder(),
          sources,
          input,
          '.detail_prototype.dart'));
      expect(today.code, isNotEmpty);
      expect(prototype.imports, today.imports);
      expect(prototype.code, today.code);
    });
  }

  test('a promoted detail screen is skipped, imported and re-exported',
      () async {
    final sources = _scenarios['update, delete and views']!;
    final output = await _generate(
        detailScreenPrototypeBuilder(promoted: const [
          PromotedDeclaration(
              'ProductDetailScreen', 'screens/product_detail_screen.dart'),
        ]),
        sources,
        'lib/product.dart',
        '.detail_prototype.dart');
    expect(output, isNot(contains('class ProductDetailScreen')));
    // Re-exported, so code importing the generated library (routes, main.dart,
    // other entities' generated code) still finds ProductDetailScreen.
    expect(
        output,
        contains("export 'screens/product_detail_screen.dart' "
            'show ProductDetailScreen;'));
  });

  test('a promoted artifact keeps the others and imports the replacement',
      () async {
    final sources = _scenarios['three-level parent chain with breadcrumbs']!;
    final output = await _generate(
        detailScreenPrototypeBuilder(promoted: const [
          PromotedDeclaration(
              'OrderLineDetailScreen', 'screens/order_line_detail_screen.dart'),
        ]),
        sources,
        'lib/order.dart',
        '.detail_prototype.dart');
    expect(output, contains("import 'screens/order_line_detail_screen.dart';"));
    expect(output, isNot(contains('class OrderLineDetailScreen')));
    expect(output, contains('class OrderDetailScreen'));
    expect(output, contains('class LineNoteDetailScreen'));
  });
}
