import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:prefab_flutter_generator/builder.dart';
import 'package:test/test.dart';

const _prefabSources = {
  'prefab_flutter|lib/prefab_flutter.dart': r'''
export 'src/annotations/entity.dart';
export 'src/annotations/create.dart';
export 'src/annotations/update.dart';
export 'src/annotations/delete.dart';
export 'src/annotations/field.dart';
export 'src/annotations/parent.dart';
export 'src/enums/field_widget.dart';
export 'src/enums/validator.dart';
''',
  'prefab_flutter|lib/src/annotations/entity.dart': r'''
class Entity {
  final String title;
  final String path;
  final bool paged;
  const Entity({required this.title, required this.path, this.paged = true});
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
  final bool searchable;
  final bool sortable;
  final FormOptions form;
  const Field({
    this.label,
    this.searchable = false,
    this.sortable = false,
    this.form = const FormOptions(),
  });
}
''',
  'prefab_flutter|lib/src/annotations/parent.dart': r'''
class Parent {
  final Type entity;
  const Parent(this.entity);
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

const _jsonAnnotation = r'''
enum FieldRename { none, kebab, snake, pascal, screamingSnake }
class JsonSerializable {
  final FieldRename? fieldRename;
  const JsonSerializable({this.fieldRename});
}
class JsonKey {
  final String? name;
  const JsonKey({this.name});
}
''';

String _source(String classAnnotation) => '''
import 'package:json_annotation/json_annotation.dart';
import 'package:prefab_flutter/prefab_flutter.dart';

$classAnnotation
@Entity(title: 'Product', path: 'products')
class Product {
  final int id;

  @Field(sortable: true)
  final String name;

  @Field(sortable: true)
  final double unitPrice;

  @JsonKey(name: 'created')
  @Field(sortable: true)
  final String createdAt;

  Product({required this.id, required this.name, required this.unitPrice,
      required this.createdAt});
}
''';

Future<void> _expect(String classAnnotation, Matcher matcher) =>
    testBuilder(
      listScreenBuilder(BuilderOptions.empty),
      {
        ...Map<String, Object>.from(_prefabSources),
        'json_annotation|lib/json_annotation.dart': _jsonAnnotation,
        'a|lib/product.dart': _source(classAnnotation),
      },
      outputs: {'a|lib/product.list_screen.dart': decodedMatches(matcher)},
    );

void main() {
  group('PF-34 sort keys follow JSON names', () {
    test('no rename keeps the Dart field name', () async {
      await _expect(
        '',
        allOf(
          contains("id: 'unitPrice'"),
          contains("id: '-unitPrice'"),
          contains("id: 'name'"),
          contains("id: 'created'"),
        ),
      );
    });

    test('FieldRename.snake is applied, @JsonKey(name:) wins', () async {
      await _expect(
        '@JsonSerializable(fieldRename: FieldRename.snake)',
        allOf(
          contains("id: 'unit_price'"),
          contains("id: '-unit_price'"),
          contains("id: 'created'"),
          isNot(contains("id: 'unitPrice'")),
          isNot(contains("id: 'created_at'")),
        ),
      );
    });

    test('FieldRename.kebab is applied', () async {
      await _expect(
        '@JsonSerializable(fieldRename: FieldRename.kebab)',
        contains("id: 'unit-price'"),
      );
    });
  });
}
