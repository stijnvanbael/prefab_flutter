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
// Helpers
// ---------------------------------------------------------------------------

Map<String, Object> _assets(String pkg, String path, String source) => {
      ...Map<String, Object>.from(_prefabSources),
      '$pkg|$path': source,
    };

String _entity(String fieldDecl) => '''
import 'package:prefab_flutter/prefab_flutter.dart';

enum Color { red, green }

@View(title: 'Thing', path: 'things')
@Update()
class Thing {
  late final int id;
  $fieldDecl

  Thing({required this.f});
}
''';

Future<void> _expectOutput(String fieldDecl, Matcher matcher) => testBuilder(
      formScreenBuilder(BuilderOptions.empty),
      _assets('a', 'lib/thing.dart', _entity(fieldDecl)),
      outputs: {'a|lib/thing.form_screen.dart': decodedMatches(matcher)},
    );

Future<String> _buildError(String fieldDecl) async {
  final logs = <String>[];
  try {
    await testBuilder(
      formScreenBuilder(BuilderOptions.empty),
      _assets('a', 'lib/thing.dart', _entity(fieldDecl)),
      onLog: (r) => logs.add('${r.message} ${r.error ?? ''}'),
    );
  } catch (e) {
    logs.add(e.toString());
  }
  return logs.join('\n');
}

void main() {
  group('timePicker and dateTimePicker (PF-17)', () {
    test(
      'timePicker on Duration stores a typed Duration and formats via locale',
      () => _expectOutput(
        '@Field(form: FormOptions(widget: FieldWidget.timePicker)) final Duration f;',
        allOf(
          contains('Duration? _fValue;'),
          contains('showTimePicker('),
          contains('Duration(hours: picked.hour, minutes: picked.minute)'),
          contains('MaterialLocalizations.of(context).formatTimeOfDay('),
          contains('_fValue!'),
          isNot(contains('toIso8601String')),
        ),
      ),
    );

    test(
      'timePicker on String uses HH:mm',
      () => _expectOutput(
        '@Field(form: FormOptions(widget: FieldWidget.timePicker)) final String f;',
        allOf(
          contains('String? _fValue;'),
          contains("padLeft(2, '0')"),
          contains("split(':')"),
        ),
      ),
    );

    test(
      'dateTimePicker chains both pickers',
      () => _expectOutput(
        '@Field(form: FormOptions(widget: FieldWidget.dateTimePicker)) final DateTime f;',
        allOf(
          contains('DateTime? _fValue;'),
          contains('showDatePicker('),
          contains('showTimePicker('),
          contains('formatCompactDate('),
          contains('formatTimeOfDay('),
        ),
      ),
    );

    test(
      'datePicker display uses locale formatting, not ISO-8601',
      () => _expectOutput(
        '@Field(form: FormOptions()) final DateTime f;',
        allOf(
            contains('formatCompactDate('), isNot(contains('toIso8601String'))),
      ),
    );

    test(
      'timePicker on an unsupported type is a build error',
      () async {
        final out = await _buildError(
          '@Field(form: FormOptions(widget: FieldWidget.timePicker)) final int f;',
        );
        expect(out, contains('timePicker'));
        expect(out, contains('Duration'));
      },
    );

    test(
      'dateTimePicker on an unsupported type is a build error',
      () async {
        final out = await _buildError(
          '@Field(form: FormOptions(widget: FieldWidget.dateTimePicker)) final String f;',
        );
        expect(out, contains('dateTimePicker'));
      },
    );
  });
}
