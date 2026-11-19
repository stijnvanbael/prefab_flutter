import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:prefab_flutter_generator/builder.dart';
import 'package:test/test.dart';

const _prefabSources = {
  'prefab_flutter|lib/prefab_flutter.dart': r'''
export 'src/annotations/view.dart';
export 'src/annotations/create.dart';
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
