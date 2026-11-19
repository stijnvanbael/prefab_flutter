import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:prefab_flutter_generator/builder.dart';
import 'package:prefab_flutter_generator/src/manifest/entity_manifest.dart';
import 'package:test/test.dart';

const _prefabSources = {
  'prefab_flutter|lib/prefab_flutter.dart': r'''
export 'src/annotations/view.dart';
export 'src/annotations/update.dart';
export 'src/annotations/delete.dart';
export 'src/annotations/field.dart';
export 'src/annotations/parent.dart';
export 'src/annotations/id.dart';
export 'src/enums/field_widget.dart';
export 'src/enums/validator.dart';
''',
  'prefab_flutter|lib/src/annotations/view.dart': r'''
class View {
  final String? title;
  final String? path;
  const View({this.title, this.path});
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
  const Field({
    this.label,
    this.hidden = false,
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
  'prefab_flutter|lib/src/annotations/id.dart': r'''
class Id {
  const Id();
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

const _minimalSource = r'''
import 'package:prefab_flutter/prefab_flutter.dart';

@View()
@Update()
class ProductOrder {
  final String? id;
  @Field()
  final String name;
  ProductOrder({this.id, required this.name});
  factory ProductOrder.fromJson(Map<String, dynamic> json) => throw 0;
  Map<String, dynamic> toJson() => {};
}
''';

const _explicitSource = r'''
import 'package:prefab_flutter/prefab_flutter.dart';

@View(title: 'Order', path: 'orders-x')
class ProductOrder {
  final String? id;
  @Field()
  final String name;
  ProductOrder({this.id, required this.name});
  factory ProductOrder.fromJson(Map<String, dynamic> json) => throw 0;
  Map<String, dynamic> toJson() => {};
}
''';

const _chainSource = r'''
import 'package:prefab_flutter/prefab_flutter.dart';

@View()
class Post {
  final String? id;
  @Field()
  final String name;
  Post({this.id, required this.name});
  factory Post.fromJson(Map<String, dynamic> json) => throw 0;
  Map<String, dynamic> toJson() => {};
}

@View()
class Comment {
  final String? id;
  @Field()
  @Parent(Post)
  final String postId;
  Comment({this.id, required this.postId});
  factory Comment.fromJson(Map<String, dynamic> json) => throw 0;
  Map<String, dynamic> toJson() => {};
}
''';

Map<String, Object> _assets(String source, String file) => {
      ...Map<String, Object>.from(_prefabSources),
      'a|lib/$file.dart': source,
    };

void main() {
  test('minimal @View() derives route path from the class name', () async {
    await testBuilder(
      routesBuilder(BuilderOptions.empty),
      _assets(_minimalSource, 'product_order'),
      outputs: {
        'a|lib/product_order.routes.dart':
            decodedMatches(contains("path: '/product-orders'")),
      },
    );
  });

  test('minimal @View() derives the screen title from the class name',
      () async {
    await testBuilder(
      detailScreenBuilder(BuilderOptions.empty),
      _assets(_minimalSource, 'product_order'),
      outputs: {
        'a|lib/product_order.detail_screen.dart':
            decodedMatches(contains("Text('Product Order')")),
      },
    );
  });

  test('explicit title and path are unaffected', () async {
    await testBuilder(
      routesBuilder(BuilderOptions.empty),
      _assets(_explicitSource, 'product_order'),
      outputs: {
        'a|lib/product_order.routes.dart': decodedMatches(
          allOf(contains("path: '/orders-x'"),
              isNot(contains('product-orders'))),
        ),
      },
    );
  });

  test('bare @View() works for parent entities', () async {
    await testBuilder(
      routesBuilder(BuilderOptions.empty),
      _assets(_chainSource, 'chain'),
      outputs: {
        'a|lib/chain.routes.dart': decodedMatches(
          allOf(contains("'/posts'"), contains("comments")),
        ),
      },
    );
  });

  test('pluralisation rule', () {
    String p(String n) => EntityManifest.pluralizeKebab(n);
    expect(p('Product'), 'products');
    expect(p('ProductOrder'), 'product-orders');
    expect(p('Category'), 'categories');
    expect(p('Day'), 'days');
    expect(p('Box'), 'boxes');
    expect(p('Address'), 'addresses');
    expect(p('Batch'), 'batches');
    expect(p('HTTPRequest'), 'http-requests');
  });
}
