import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:prefab_flutter_generator/builder.dart';
import 'package:test/test.dart';

// ---------------------------------------------------------------------------
// Shared annotation stubs included in every test's source assets.
// These mirror the actual prefab_flutter package sources so the Dart resolver
// can resolve `package:prefab_flutter/...` imports inside the test sources.
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
  const Parent();
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

/// A fully-annotated entity with @Update and @Delete.
const _productSource = r'''
import 'package:prefab_flutter/prefab_flutter.dart';

@View(title: 'Product', path: 'products')
@Update()
@Delete()
class Product {
  final int id;

  @FormField(label: 'Name')
  final String name;

  @FormField(label: 'Price')
  final double price;

  @FormField(hidden: true)
  final String internalCode;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.internalCode,
  });
}
''';

/// An entity with no @Update / @Delete.
const _tagSource = r'''
import 'package:prefab_flutter/prefab_flutter.dart';

@View(title: 'Tag', path: 'tags')
class Tag {
  @FormField(label: 'Name')
  final String name;

  Tag({required this.name});
}
''';

/// An entity where @FormField.label is omitted (label should be derived from
/// the field name).
const _orderSource = r'''
import 'package:prefab_flutter/prefab_flutter.dart';

@View(title: 'Order', path: 'orders')
class Order {
  @FormField()
  final String customerName;

  Order({required this.customerName});
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
  group('DetailScreenGenerator', () {
    test('AC#1 — emits a ConsumerWidget for the annotated entity', () async {
      await testBuilder(
        detailScreenBuilder(BuilderOptions.empty),
        _assets('a', 'lib/product.dart', _productSource),
        outputs: {
          'a|lib/product.detail_screen.dart': decodedMatches(contains(
            'class ProductDetailScreen extends ConsumerWidget',
          )),
        },
      );
    });

    test('AC#3 — AppBar title uses the entity title from @View', () async {
      await testBuilder(
        detailScreenBuilder(BuilderOptions.empty),
        _assets('a', 'lib/product.dart', _productSource),
        outputs: {
          'a|lib/product.detail_screen.dart': decodedMatches(contains(
            "const Text('Product')",
          )),
        },
      );
    });

    test('AC#2 — renders non-hidden fields as labelled read-only tiles',
        () async {
      await testBuilder(
        detailScreenBuilder(BuilderOptions.empty),
        _assets('a', 'lib/product.dart', _productSource),
        outputs: {
          'a|lib/product.detail_screen.dart': decodedMatches(allOf(
            contains("const Text('Name')"),
            contains('product.name.toString()'),
            contains("const Text('Price')"),
            contains('product.price.toString()'),
          )),
        },
      );
    });

    test('AC#2 — hidden fields are excluded from the detail screen', () async {
      await testBuilder(
        detailScreenBuilder(BuilderOptions.empty),
        _assets('a', 'lib/product.dart', _productSource),
        outputs: {
          'a|lib/product.detail_screen.dart': decodedMatches(isNot(
            contains('internalCode'),
          )),
        },
      );
    });

    test('AC#4 — Edit action is present when @Update is on the class',
        () async {
      await testBuilder(
        detailScreenBuilder(BuilderOptions.empty),
        _assets('a', 'lib/product.dart', _productSource),
        outputs: {
          'a|lib/product.detail_screen.dart': decodedMatches(allOf(
            contains('Icons.edit'),
            contains("/products/\$id/edit"),
          )),
        },
      );
    });

    test('AC#4 — Delete action is present when @Delete is on the class',
        () async {
      await testBuilder(
        detailScreenBuilder(BuilderOptions.empty),
        _assets('a', 'lib/product.dart', _productSource),
        outputs: {
          'a|lib/product.detail_screen.dart': decodedMatches(allOf(
            contains('Icons.delete'),
            contains('showPrefabDeleteDialog'),
          )),
        },
      );
    });

    test('no Edit action when @Update is absent', () async {
      await testBuilder(
        detailScreenBuilder(BuilderOptions.empty),
        _assets('a', 'lib/tag.dart', _tagSource),
        outputs: {
          'a|lib/tag.detail_screen.dart': decodedMatches(isNot(contains('Icons.edit'))),
        },
      );
    });

    test('no Delete action when @Delete is absent', () async {
      await testBuilder(
        detailScreenBuilder(BuilderOptions.empty),
        _assets('a', 'lib/tag.dart', _tagSource),
        outputs: {
          'a|lib/tag.detail_screen.dart': decodedMatches(isNot(contains('Icons.delete'))),
        },
      );
    });

    test(
        'field label is derived from camelCase field name when '
        '@FormField.label is omitted', () async {
      await testBuilder(
        detailScreenBuilder(BuilderOptions.empty),
        _assets('a', 'lib/order.dart', _orderSource),
        outputs: {
          'a|lib/order.detail_screen.dart': decodedMatches(contains(
            "const Text('Customer Name')",
          )),
        },
      );
    });

    test('generated file imports flutter and flutter_riverpod', () async {
      await testBuilder(
        detailScreenBuilder(BuilderOptions.empty),
        _assets('a', 'lib/product.dart', _productSource),
        outputs: {
          'a|lib/product.detail_screen.dart': decodedMatches(allOf(
            contains("import 'package:flutter/material.dart'"),
            contains(
                "import 'package:flutter_riverpod/flutter_riverpod.dart'"),
          )),
        },
      );
    });

    test('generated file imports go_router when actions are present', () async {
      await testBuilder(
        detailScreenBuilder(BuilderOptions.empty),
        _assets('a', 'lib/product.dart', _productSource),
        outputs: {
          'a|lib/product.detail_screen.dart': decodedMatches(
              contains("import 'package:go_router/go_router.dart'")),
        },
      );
    });

    test('generated file does NOT import go_router when no actions', () async {
      await testBuilder(
        detailScreenBuilder(BuilderOptions.empty),
        _assets('a', 'lib/tag.dart', _tagSource),
        outputs: {
          'a|lib/tag.detail_screen.dart': decodedMatches(
              isNot(contains("import 'package:go_router/go_router.dart'"))),
        },
      );
    });
  });
}
