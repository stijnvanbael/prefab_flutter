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
  'prefab_flutter|lib/src/enums/field_widget.dart': r'''
enum FieldWidget { auto, multilineText, password, datePicker, dropdown, toggle }
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

String _entity(String annotations) => """
import 'package:prefab_flutter/prefab_flutter.dart';

@View(title: 'Log', path: 'logs')
$annotations
class Log {
  final int? id;

  @Field(label: 'Message')
  final String message;

  Log({this.id, required this.message});

  factory Log.fromJson(Map<String, dynamic> json) =>
      Log(id: json['id'] as int?, message: json['message'] as String);

  Map<String, dynamic> toJson() => {'id': id, 'message': message};
}
""";

Map<String, Object> _assets(String annotations) => {
      ...Map<String, Object>.from(_prefabSources),
      'a|lib/log.dart': _entity(annotations),
    };

void main() {
  group('PF-14 @Create / @Update split', () {
    test('create-only: create screen, route, FAB, provider and client', () async {
      final assets = _assets('@Create()');
      await testBuilder(formScreenBuilder(BuilderOptions.empty), assets, outputs: {
        'a|lib/log.form_screen.dart': decodedMatches(allOf(
            contains('class LogCreateScreen'),
            isNot(contains('class LogEditScreen')))),
      });
      await testBuilder(routesBuilder(BuilderOptions.empty), assets, outputs: {
        'a|lib/log.routes.dart': decodedMatches(allOf(
            contains("path: 'create'"), isNot(contains("path: 'edit'")))),
      });
      await testBuilder(listScreenBuilder(BuilderOptions.empty), assets, outputs: {
        'a|lib/log.list_screen.dart':
            decodedMatches(contains('FloatingActionButton')),
      });
      await testBuilder(detailScreenBuilder(BuilderOptions.empty), assets,
          outputs: {
            'a|lib/log.detail_screen.dart':
                decodedMatches(isNot(contains('Icons.edit'))),
          });
      await testBuilder(providerBuilder(BuilderOptions.empty), assets, outputs: {
        'a|lib/log.provider.dart': decodedMatches(allOf(
            contains('Future<void> create('),
            isNot(contains('Future<void> update(')))),
      });
      await testBuilder(apiClientBuilder(BuilderOptions.empty), assets, outputs: {
        'a|lib/log.api_client.dart': decodedMatches(allOf(
            contains('Future<Log> create('),
            isNot(contains('Future<Log> update(')))),
      });
    });

    test('update-only: edit screen, route, provider and client', () async {
      final assets = _assets('@Update()');
      await testBuilder(formScreenBuilder(BuilderOptions.empty), assets, outputs: {
        'a|lib/log.form_screen.dart': decodedMatches(allOf(
            contains('class LogEditScreen'),
            isNot(contains('class LogCreateScreen')))),
      });
      await testBuilder(routesBuilder(BuilderOptions.empty), assets, outputs: {
        'a|lib/log.routes.dart': decodedMatches(allOf(
            contains("path: 'edit'"), isNot(contains("path: 'create'")))),
      });
      await testBuilder(listScreenBuilder(BuilderOptions.empty), assets, outputs: {
        'a|lib/log.list_screen.dart':
            decodedMatches(isNot(contains('FloatingActionButton'))),
      });
      await testBuilder(detailScreenBuilder(BuilderOptions.empty), assets,
          outputs: {
            'a|lib/log.detail_screen.dart':
                decodedMatches(contains('/edit')),
          });
      await testBuilder(providerBuilder(BuilderOptions.empty), assets, outputs: {
        'a|lib/log.provider.dart': decodedMatches(allOf(
            contains('Future<void> update('),
            isNot(contains('Future<void> create(')))),
      });
      await testBuilder(apiClientBuilder(BuilderOptions.empty), assets, outputs: {
        'a|lib/log.api_client.dart': decodedMatches(allOf(
            contains('Future<Log> update('),
            isNot(contains('Future<Log> create(')))),
      });
    });

    test('read-only: no form screen, no create/edit routes', () async {
      final assets = _assets('');
      await testBuilder(formScreenBuilder(BuilderOptions.empty), assets,
          outputs: {});
      await testBuilder(routesBuilder(BuilderOptions.empty), assets, outputs: {
        'a|lib/log.routes.dart': decodedMatches(allOf(
            isNot(contains("path: 'create'")),
            isNot(contains("path: 'edit'")))),
      });
    });
  });
}
