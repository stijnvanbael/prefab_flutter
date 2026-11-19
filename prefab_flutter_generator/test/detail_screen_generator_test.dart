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
export 'src/annotations/create.dart';
export 'src/annotations/update.dart';
export 'src/annotations/delete.dart';
export 'src/annotations/field.dart';
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
  'prefab_flutter|lib/src/annotations/create.dart': r'''
class Create {
  const Create();
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
  'prefab_flutter|lib/src/annotations/field.dart': r'''
import 'package:prefab_flutter/src/enums/field_widget.dart';
import 'package:prefab_flutter/src/enums/validator.dart';
class FormOptions {
  final FieldWidget widget;
  final List<Validator> validators;
  const FormOptions({
    this.widget = FieldWidget.auto,
    this.validators = const [],
  });
}
class Field {
  final String? label;
  final bool hidden;
  final FormOptions form;
  final Set<String>? views;
  const Field({
    this.label,
    this.hidden = false,
    this.views,
    this.form = const FormOptions(),
  });
}
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
enum FieldWidget { auto, multilineText, password, datePicker, timePicker, dateTimePicker, dropdown, toggle }
''',
  'prefab_flutter|lib/src/enums/validator.dart': r'''
/// Validation rules that the form-screen generator wires into form fields.
///
/// Parameterless rules are available as static constants
/// (`Validator.required`, `Validator.email`, ...); rules that carry a value are
/// created with the const factories (`Validator.min(0)`,
/// `Validator.pattern(r'^[A-Z]+$')`).
///
/// Every rule accepts an optional custom error [message]. For the parameterless
/// rules use the subclass constructor, e.g. `EmailValidator(message: 'Bad')`.
sealed class Validator {
  /// Custom error message shown instead of the default one.
  final String? message;

  const Validator({this.message});

  /// Field must not be empty (or, on dropdowns, must have a selection).
  static const Validator required = RequiredValidator();

  /// Field value must be a valid e-mail address.
  static const Validator email = EmailValidator();

  /// Field value must be a parseable absolute URL.
  static const Validator url = UrlValidator();

  /// Field value must be a number greater than zero.
  static const Validator positive = PositiveValidator();

  /// Alias of [positive], kept for backwards compatibility.
  static const Validator positiveNumber = PositiveValidator();

  /// Field value must be a number greater than or equal to zero.
  static const Validator nonNegative = NonNegativeValidator();

  /// Field value must be a number greater than or equal to [value].
  const factory Validator.min(num value, {String? message}) = MinValidator;

  /// Field value must be a number less than or equal to [value].
  const factory Validator.max(num value, {String? message}) = MaxValidator;

  /// Field value must be at least [length] characters long.
  const factory Validator.minLength(int length, {String? message}) =
      MinLengthValidator;

  /// Field value must be at most [length] characters long.
  const factory Validator.maxLength(int length, {String? message}) =
      MaxLengthValidator;

  /// Field value must match the regular expression [regex].
  const factory Validator.pattern(String regex, {String? message}) =
      PatternValidator;
}

/// See [Validator.required].
final class RequiredValidator extends Validator {
  const RequiredValidator({super.message});
}

/// See [Validator.email].
final class EmailValidator extends Validator {
  const EmailValidator({super.message});
}

/// See [Validator.url].
final class UrlValidator extends Validator {
  const UrlValidator({super.message});
}

/// See [Validator.positive].
final class PositiveValidator extends Validator {
  const PositiveValidator({super.message});
}

/// See [Validator.nonNegative].
final class NonNegativeValidator extends Validator {
  const NonNegativeValidator({super.message});
}

/// See [Validator.min].
final class MinValidator extends Validator {
  final num value;
  const MinValidator(this.value, {super.message});
}

/// See [Validator.max].
final class MaxValidator extends Validator {
  final num value;
  const MaxValidator(this.value, {super.message});
}

/// See [Validator.minLength].
final class MinLengthValidator extends Validator {
  final int length;
  const MinLengthValidator(this.length, {super.message});
}

/// See [Validator.maxLength].
final class MaxLengthValidator extends Validator {
  final int length;
  const MaxLengthValidator(this.length, {super.message});
}

/// See [Validator.pattern].
final class PatternValidator extends Validator {
  final String regex;
  const PatternValidator(this.regex, {super.message});
}
''',
};

// ---------------------------------------------------------------------------
// Test entity sources
// ---------------------------------------------------------------------------

/// A fully-annotated entity with @Update and @Delete.
const _productSource = r'''
import 'package:prefab_flutter/prefab_flutter.dart';

@View(title: 'Product', path: 'products')
@Create()
@Update()
@Delete()
class Product {
  final int id;

  @Field(label: 'Name')
  final String name;

  @Field(label: 'Price')
  final double price;

  @Field(hidden: true)
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
  late final int id;
  @Field(label: 'Name')
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
  late final int id;
  @Field()
  final String customerName;

  Order({required this.customerName});
}
''';

/// Entity with nullable and non-nullable fields.
const _nullableSource = r'''
import 'package:prefab_flutter/prefab_flutter.dart';

@View(title: 'Item', path: 'items')
class Item {
  late final int id;
  @Field(label: 'Name')
  final String name;
  @Field(label: 'Note')
  final String? note;

  Item({required this.name, this.note});
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

const _viewsSource = r'''
import 'package:prefab_flutter/prefab_flutter.dart';

@View(title: 'Item', path: 'items')
class Item {
  final int id;

  @Field(label: 'Only list', views: {'list'})
  final String onlyList;

  @Field(label: 'Only detail', views: {'detail'})
  final String onlyDetail;

  @Field(label: 'Everywhere')
  final String everywhere;

  Item({required this.id, required this.onlyList, required this.onlyDetail,
      required this.everywhere});
}
''';

void main() {
  test('PF-16 — detail screen only shows fields in the detail view', () async {
    await testBuilder(
      detailScreenBuilder(BuilderOptions.empty),
      {
        ..._prefabSources,
        'a|lib/item.dart': _viewsSource,
      },
      outputs: {
        'a|lib/item.detail_screen.dart': decodedMatches(
          allOf(
            contains("Text('Only detail')"),
            contains("Text('Everywhere')"),
            isNot(contains("Text('Only list')")),
          ),
        ),
      },
    );
  });

  group('DetailScreenGenerator', () {
    test('AC#1 — emits a ConsumerWidget for the annotated entity', () async {
      await testBuilder(
        detailScreenBuilder(BuilderOptions.empty),
        _assets('a', 'lib/product.dart', _productSource),
        outputs: {
          'a|lib/product.detail_screen.dart': decodedMatches(
            contains('class ProductDetailScreen extends ConsumerWidget'),
          ),
        },
      );
    });

    test('AC#3 — AppBar title uses the entity title from @View', () async {
      await testBuilder(
        detailScreenBuilder(BuilderOptions.empty),
        _assets('a', 'lib/product.dart', _productSource),
        outputs: {
          'a|lib/product.detail_screen.dart': decodedMatches(
            contains("const Text('Product')"),
          ),
        },
      );
    });

    test(
      'AC#2 — renders non-hidden fields as labelled read-only tiles',
      () async {
        await testBuilder(
          detailScreenBuilder(BuilderOptions.empty),
          _assets('a', 'lib/product.dart', _productSource),
          outputs: {
            'a|lib/product.detail_screen.dart': decodedMatches(
              allOf(
                contains("const Text('Name')"),
                contains('product.name.toString()'),
                contains("const Text('Price')"),
                contains('product.price.toString()'),
              ),
            ),
          },
        );
      },
    );

    test('AC#2 — hidden fields are excluded from the detail screen', () async {
      await testBuilder(
        detailScreenBuilder(BuilderOptions.empty),
        _assets('a', 'lib/product.dart', _productSource),
        outputs: {
          'a|lib/product.detail_screen.dart': decodedMatches(
            isNot(contains('internalCode')),
          ),
        },
      );
    });

    test(
      'AC#4 — Edit action is present when @Update is on the class',
      () async {
        await testBuilder(
          detailScreenBuilder(BuilderOptions.empty),
          _assets('a', 'lib/product.dart', _productSource),
          outputs: {
            'a|lib/product.detail_screen.dart': decodedMatches(
              allOf(contains('Icons.edit'), contains("/products/\$id/edit")),
            ),
          },
        );
      },
    );

    test(
      'AC#4 — Delete action is present when @Delete is on the class',
      () async {
        await testBuilder(
          detailScreenBuilder(BuilderOptions.empty),
          _assets('a', 'lib/product.dart', _productSource),
          outputs: {
            'a|lib/product.detail_screen.dart': decodedMatches(
              allOf(
                contains('Icons.delete'),
                contains('showPrefabDeleteDialog'),
              ),
            ),
          },
        );
      },
    );

    test('no Edit action when @Update is absent', () async {
      await testBuilder(
        detailScreenBuilder(BuilderOptions.empty),
        _assets('a', 'lib/tag.dart', _tagSource),
        outputs: {
          'a|lib/tag.detail_screen.dart': decodedMatches(
            isNot(contains('Icons.edit')),
          ),
        },
      );
    });

    test('no Delete action when @Delete is absent', () async {
      await testBuilder(
        detailScreenBuilder(BuilderOptions.empty),
        _assets('a', 'lib/tag.dart', _tagSource),
        outputs: {
          'a|lib/tag.detail_screen.dart': decodedMatches(
            isNot(contains('Icons.delete')),
          ),
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
          'a|lib/order.detail_screen.dart': decodedMatches(
            contains("const Text('Customer Name')"),
          ),
        },
      );
    });

    test('generated file imports flutter and flutter_riverpod', () async {
      await testBuilder(
        detailScreenBuilder(BuilderOptions.empty),
        _assets('a', 'lib/product.dart', _productSource),
        outputs: {
          'a|lib/product.detail_screen.dart': decodedMatches(
            allOf(
              contains("import 'package:material_ui/material_ui.dart'"),
              contains(
                "import 'package:flutter_riverpod/flutter_riverpod.dart'",
              ),
            ),
          ),
        },
      );
    });

    test('generated file imports go_router when actions are present', () async {
      await testBuilder(
        detailScreenBuilder(BuilderOptions.empty),
        _assets('a', 'lib/product.dart', _productSource),
        outputs: {
          'a|lib/product.detail_screen.dart': decodedMatches(
            contains("import 'package:go_router/go_router.dart'"),
          ),
        },
      );
    });

    test('generated file does NOT import go_router when no actions', () async {
      await testBuilder(
        detailScreenBuilder(BuilderOptions.empty),
        _assets('a', 'lib/tag.dart', _tagSource),
        outputs: {
          'a|lib/tag.detail_screen.dart': decodedMatches(
            isNot(contains("import 'package:go_router/go_router.dart'")),
          ),
        },
      );
    });

    test('PF-15 — nullable fields show an em dash instead of null', () async {
      await testBuilder(
        detailScreenBuilder(BuilderOptions.empty),
        _assets('a', 'lib/item.dart', _nullableSource),
        outputs: {
          'a|lib/item.detail_screen.dart': decodedMatches(
            allOf(
              contains("Text(item.note?.toString() ?? '\u2014')"),
              contains('Text(item.name.toString())'),
            ),
          ),
        },
      );
    });
  });
}
