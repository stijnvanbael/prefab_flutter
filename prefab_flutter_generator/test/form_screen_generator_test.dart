import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:prefab_flutter_generator/builder.dart';
import 'package:test/test.dart';
import 'support/prefab_sources.dart';

// ---------------------------------------------------------------------------
// Test entity sources
// ---------------------------------------------------------------------------

/// Entity with Validator.required on a field.
const _requiredSource = r'''
import 'package:prefab_flutter/prefab_flutter.dart';

@Entity(title: 'Product', path: 'products')
@Create()
@Update()
class Product {
  late final int id;
  @Field(label: 'Name', form: FormOptions(validators: [Validator.required]))
  final String name;

  Product({required this.name});
}
''';

/// Entity with Validator.email on a field.
const _emailSource = r'''
import 'package:prefab_flutter/prefab_flutter.dart';

@Entity(title: 'User', path: 'users')
@Create()
@Update()
class User {
  late final int id;
  @Field(label: 'Email', form: FormOptions(validators: [Validator.email]))
  final String email;

  User({required this.email});
}
''';

/// Entity with Validator.positiveNumber on a field.
const _positiveNumberSource = r'''
import 'package:prefab_flutter/prefab_flutter.dart';

@Entity(title: 'Product', path: 'products')
@Create()
@Update()
class Product {
  late final int id;
  @Field(label: 'Price', form: FormOptions(validators: [Validator.positiveNumber]))
  final double price;

  Product({required this.price});
}
''';

/// Entity with Validator.url on a field.
const _urlSource = r'''
import 'package:prefab_flutter/prefab_flutter.dart';

@Entity(title: 'Resource', path: 'resources')
@Create()
@Update()
class Resource {
  late final int id;
  @Field(label: 'URL', form: FormOptions(validators: [Validator.url]))
  final String url;

  Resource({required this.url});
}
''';

/// Entity without @Update — no form screen should be generated.
const _tagSource = r'''
import 'package:prefab_flutter/prefab_flutter.dart';

@Entity(title: 'Tag', path: 'tags')
class Tag {
  late final int id;
  @Field(label: 'Name')
  final String name;

  Tag({required this.name});
}
''';

/// Entity with multiple validators on a single field.
const _multiValidatorSource = r'''
import 'package:prefab_flutter/prefab_flutter.dart';

@Entity(title: 'Contact', path: 'contacts')
@Create()
@Update()
class Contact {
  late final int id;
  @Field(label: 'Email', form: FormOptions(validators: [Validator.required, Validator.email]))
  final String email;

  Contact({required this.email});
}
''';

/// Entity with a bool field — should produce SwitchListTile by default (AC#1).
const _boolSource = r'''
import 'package:prefab_flutter/prefab_flutter.dart';

@Entity(title: 'Setting', path: 'settings')
@Create()
@Update()
class Setting {
  late final int id;
  @Field(label: 'Is Active')
  final bool isActive;

  Setting({required this.isActive});
}
''';

/// Entity with a DateTime field — should produce a date picker (AC#2).
const _dateTimeSource = r'''
import 'package:prefab_flutter/prefab_flutter.dart';

@Entity(title: 'Event', path: 'events')
@Create()
@Update()
class Event {
  late final int id;
  @Field(label: 'Start Date')
  final DateTime startDate;

  Event({required this.startDate});
}
''';

/// Entity with FieldWidget.multilineText — multi-line TextFormField (AC#3).
const _multilineSource = r'''
import 'package:prefab_flutter/prefab_flutter.dart';

@Entity(title: 'Article', path: 'articles')
@Create()
@Update()
class Article {
  late final int id;
  @Field(label: 'Body', form: FormOptions(widget: FieldWidget.multilineText))
  final String body;

  Article({required this.body});
}
''';

/// Entity with FieldWidget.password — obscured TextFormField (AC#4).
const _passwordSource = r'''
import 'package:prefab_flutter/prefab_flutter.dart';

@Entity(title: 'Account', path: 'accounts')
@Create()
@Update()
class Account {
  late final int id;
  @Field(label: 'Password', form: FormOptions(widget: FieldWidget.password))
  final String password;

  Account({required this.password});
}
''';

/// Entity with an enum field — should produce DropdownButtonFormField (AC#5).
const _enumSource = r'''
import 'package:prefab_flutter/prefab_flutter.dart';

enum Status { active, inactive }

@Entity(title: 'Task', path: 'tasks')
@Create()
@Update()
class Task {
  late final int id;
  @Field(label: 'Status')
  final Status status;

  Task({required this.status});
}
''';

/// Entity with FieldWidget.toggle on a String field — Switch regardless of type (AC#6).
const _toggleSource = r'''
import 'package:prefab_flutter/prefab_flutter.dart';

@Entity(title: 'Flag', path: 'flags')
@Create()
@Update()
class Flag {
  late final int id;
  @Field(label: 'Enabled', form: FormOptions(widget: FieldWidget.toggle))
  final String enabled;

  Flag({required this.enabled});
}
''';

/// Entity with multiple field types for PF-8 prefill tests.
const _mixedFieldsSource = r'''
import 'package:prefab_flutter/prefab_flutter.dart';

enum Priority { low, medium, high }

@Entity(title: 'Item', path: 'items')
@Create()
@Update()
class Item {
  late final int id;
  @Field(label: 'Name')
  final String name;

  @Field(label: 'Count')
  final int count;

  @Field(label: 'Price')
  final double price;

  @Field(label: 'Active')
  final bool active;

  @Field(label: 'Due Date')
  final DateTime dueDate;

  @Field(label: 'Priority')
  final Priority priority;

  Item({
    required this.name,
    required this.count,
    required this.price,
    required this.active,
    required this.dueDate,
    required this.priority,
  });
}
''';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Map<String, Object> _assets(String pkg, String path, String source) => {
      ...Map<String, Object>.from(prefabSources),
      '$pkg|$path': source,
    };

/// Entity mixing nullable and non-nullable fields.
const _nullableSource = r'''
import 'package:prefab_flutter/prefab_flutter.dart';

enum Color { red, green }

@Entity(title: 'Item', path: 'items')
@Create()
@Update()
class Item {
  late final int id;
  @Field(label: 'Name')
  final String name;
  @Field(label: 'Nickname')
  final String? nickname;
  @Field(label: 'Email', form: FormOptions(validators: [Validator.email]))
  final String? email;
  @Field(label: 'Code', form: FormOptions(validators: [Validator.required]))
  final String? code;
  @Field(label: 'Age')
  final int? age;
  @Field(label: 'Born')
  final DateTime? born;
  @Field(label: 'Active')
  final bool? active;
  @Field(label: 'Done')
  final bool done;
  @Field(label: 'Color')
  final Color? color;

  Item({required this.name, this.nickname, this.email, this.code, this.age,
      this.born, this.active, required this.done, this.color});
}
''';

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('FormScreenGenerator', () {
    // Basic structure

    test('generates CreateScreen and EditScreen when @Update is present',
        () async {
      await testBuilder(
        formScreenBuilder(BuilderOptions.empty),
        _assets('a', 'lib/product.dart', _requiredSource),
        outputs: {
          'a|lib/product.form_screen.dart': decodedMatches(allOf(
            contains(
                'class ProductCreateScreen extends ConsumerStatefulWidget'),
            contains('class ProductEditScreen extends ConsumerStatefulWidget'),
          )),
        },
      );
    });

    test('produces no output when @Update is absent', () async {
      await testBuilder(
        formScreenBuilder(BuilderOptions.empty),
        _assets('a', 'lib/tag.dart', _tagSource),
        outputs: {},
      );
    });

    test('EditScreen has an id parameter', () async {
      await testBuilder(
        formScreenBuilder(BuilderOptions.empty),
        _assets('a', 'lib/product.dart', _requiredSource),
        outputs: {
          'a|lib/product.form_screen.dart': decodedMatches(
            contains('required this.id'),
          ),
        },
      );
    });

    test('generated file imports flutter and flutter_riverpod', () async {
      await testBuilder(
        formScreenBuilder(BuilderOptions.empty),
        _assets('a', 'lib/product.dart', _requiredSource),
        outputs: {
          'a|lib/product.form_screen.dart': decodedMatches(allOf(
            contains("import 'package:material_ui/material_ui.dart'"),
            contains("import 'package:flutter_riverpod/flutter_riverpod.dart'"),
          )),
        },
      );
    });

    test('generated file imports go_router', () async {
      await testBuilder(
        formScreenBuilder(BuilderOptions.empty),
        _assets('a', 'lib/product.dart', _requiredSource),
        outputs: {
          'a|lib/product.form_screen.dart': decodedMatches(
            contains("import 'package:go_router/go_router.dart'"),
          ),
        },
      );
    });

    test('generated file imports the entity source file', () async {
      await testBuilder(
        formScreenBuilder(BuilderOptions.empty),
        _assets('a', 'lib/product.dart', _requiredSource),
        outputs: {
          'a|lib/product.form_screen.dart': decodedMatches(
            contains("import 'product.dart'"),
          ),
        },
      );
    });

    // AC#1 — Validator.required generates a non-empty check

    test('AC#1 — Validator.required generates a non-empty check', () async {
      await testBuilder(
        formScreenBuilder(BuilderOptions.empty),
        _assets('a', 'lib/product.dart', _requiredSource),
        outputs: {
          'a|lib/product.form_screen.dart': decodedMatches(allOf(
            contains('value == null || value.isEmpty'),
            contains("return 'Required'"),
          )),
        },
      );
    });

    // AC#2 — Validator.email generates a regex email check

    test('AC#2 — Validator.email generates a regex email check', () async {
      await testBuilder(
        formScreenBuilder(BuilderOptions.empty),
        _assets('a', 'lib/user.dart', _emailSource),
        outputs: {
          'a|lib/user.form_screen.dart': decodedMatches(allOf(
            contains('RegExp('),
            contains('@'),
            contains("return 'Invalid email address'"),
          )),
        },
      );
    });

    // AC#3 — Validator.positiveNumber generates a > 0 numeric check

    test('AC#3 — Validator.positiveNumber generates a > 0 numeric check',
        () async {
      await testBuilder(
        formScreenBuilder(BuilderOptions.empty),
        _assets('a', 'lib/product.dart', _positiveNumberSource),
        outputs: {
          'a|lib/product.form_screen.dart': decodedMatches(allOf(
            contains('double.tryParse('),
            contains('<= 0'),
            contains("return 'Must be a positive number'"),
          )),
        },
      );
    });

    // AC#4 — Validator.url generates a Uri.tryParse validity check

    test('AC#4 — Validator.url generates a Uri.tryParse validity check',
        () async {
      await testBuilder(
        formScreenBuilder(BuilderOptions.empty),
        _assets('a', 'lib/resource.dart', _urlSource),
        outputs: {
          'a|lib/resource.form_screen.dart': decodedMatches(allOf(
            contains('Uri.tryParse('),
            contains('uri.isAbsolute'),
            contains("return 'Invalid URL'"),
          )),
        },
      );
    });

    // Multiple validators on a single field

    test('multiple validators are all emitted for a single field', () async {
      await testBuilder(
        formScreenBuilder(BuilderOptions.empty),
        _assets('a', 'lib/contact.dart', _multiValidatorSource),
        outputs: {
          'a|lib/contact.form_screen.dart': decodedMatches(allOf(
            contains('value == null || value.isEmpty'),
            contains('RegExp('),
          )),
        },
      );
    });

    // PF-5 AC#1 — bool field renders SwitchListTile by default

    test('PF-5 AC#1 — bool field renders SwitchListTile by default', () async {
      await testBuilder(
        formScreenBuilder(BuilderOptions.empty),
        _assets('a', 'lib/setting.dart', _boolSource),
        outputs: {
          'a|lib/setting.form_screen.dart': decodedMatches(allOf(
            contains('SwitchListTile('),
            contains('_isActiveValue'),
            isNot(contains('TextEditingController')),
          )),
        },
      );
    });

    // PF-5 AC#2 — DateTime field renders a date picker

    test('PF-5 AC#2 — DateTime field renders a date picker', () async {
      await testBuilder(
        formScreenBuilder(BuilderOptions.empty),
        _assets('a', 'lib/event.dart', _dateTimeSource),
        outputs: {
          'a|lib/event.form_screen.dart': decodedMatches(allOf(
            contains('showDatePicker('),
            contains('_startDateValue'),
            contains('readOnly: true'),
          )),
        },
      );
    });

    // PF-5 AC#3 — FieldWidget.multilineText renders a multi-line TextFormField

    test(
        'PF-5 AC#3 — FieldWidget.multilineText renders a multi-line TextFormField',
        () async {
      await testBuilder(
        formScreenBuilder(BuilderOptions.empty),
        _assets('a', 'lib/article.dart', _multilineSource),
        outputs: {
          'a|lib/article.form_screen.dart': decodedMatches(allOf(
            contains('maxLines: null'),
            contains('TextInputType.multiline'),
          )),
        },
      );
    });

    // PF-5 AC#4 — FieldWidget.password renders an obscured TextFormField

    test('PF-5 AC#4 — FieldWidget.password renders an obscured TextFormField',
        () async {
      await testBuilder(
        formScreenBuilder(BuilderOptions.empty),
        _assets('a', 'lib/account.dart', _passwordSource),
        outputs: {
          'a|lib/account.form_screen.dart': decodedMatches(
            contains('obscureText: true'),
          ),
        },
      );
    });

    // PF-5 AC#5 — enum field renders DropdownButtonFormField

    test('PF-5 AC#5 — enum field renders DropdownButtonFormField', () async {
      await testBuilder(
        formScreenBuilder(BuilderOptions.empty),
        _assets('a', 'lib/task.dart', _enumSource),
        outputs: {
          'a|lib/task.form_screen.dart': decodedMatches(allOf(
            contains('DropdownButtonFormField<Status>'),
            contains('Status.values'),
            contains('DropdownMenuItem<Status>'),
          )),
        },
      );
    });

    // PF-5 AC#6 — FieldWidget.toggle renders SwitchListTile regardless of type

    test(
        'PF-5 AC#6 — FieldWidget.toggle renders SwitchListTile regardless of type',
        () async {
      await testBuilder(
        formScreenBuilder(BuilderOptions.empty),
        _assets('a', 'lib/flag.dart', _toggleSource),
        outputs: {
          'a|lib/flag.form_screen.dart': decodedMatches(allOf(
            contains('SwitchListTile('),
            contains('_enabledValue'),
            isNot(contains('TextEditingController')),
          )),
        },
      );
    });

    // PF-8 — _prefillControllers and edit screen provider wiring

    test('PF-38 — imports the entity, not the sibling generator output',
        () async {
      await testBuilder(
        formScreenBuilder(BuilderOptions.empty),
        _assets('a', 'lib/product.dart', _requiredSource),
        outputs: {
          'a|lib/product.form_screen.dart': decodedMatches(
            allOf(
              contains("import 'product.dart'"),
              isNot(contains("import 'product.provider.dart'")),
            ),
          ),
        },
      );
    });

    test('PF-8 — EditScreen watches the detail provider', () async {
      await testBuilder(
        formScreenBuilder(BuilderOptions.empty),
        _assets('a', 'lib/product.dart', _requiredSource),
        outputs: {
          'a|lib/product.form_screen.dart': decodedMatches(allOf(
            contains('productDetailProvider(widget.id)'),
            contains('asyncItem.whenData'),
            contains('_prefilled'),
          )),
        },
      );
    });

    test('PF-8 — EditScreen body wraps form in asyncItem.when', () async {
      await testBuilder(
        formScreenBuilder(BuilderOptions.empty),
        _assets('a', 'lib/product.dart', _requiredSource),
        outputs: {
          'a|lib/product.form_screen.dart': decodedMatches(allOf(
            contains('asyncItem.when('),
            contains('prefabTheme.loadingBuilder(context)'),
          )),
        },
      );
    });

    test(
        'PF-8 AC#1 — _prefillControllers assigns text for String and numeric fields',
        () async {
      await testBuilder(
        formScreenBuilder(BuilderOptions.empty),
        _assets('a', 'lib/item.dart', _mixedFieldsSource),
        outputs: {
          'a|lib/item.form_screen.dart': decodedMatches(allOf(
            // String field — direct assignment
            contains('_nameController.text = item.name'),
            // int field — .toString()
            contains('_countController.text = item.count.toString()'),
            // double field — .toString()
            contains('_priceController.text = item.price.toString()'),
          )),
        },
      );
    });

    test('PF-8 AC#2 — _prefillControllers sets bool state variable', () async {
      await testBuilder(
        formScreenBuilder(BuilderOptions.empty),
        _assets('a', 'lib/item.dart', _mixedFieldsSource),
        outputs: {
          'a|lib/item.form_screen.dart': decodedMatches(
            contains('_activeValue = item.active'),
          ),
        },
      );
    });

    test('PF-8 AC#3 — _prefillControllers sets DateTime state and controller',
        () async {
      await testBuilder(
        formScreenBuilder(BuilderOptions.empty),
        _assets('a', 'lib/item.dart', _mixedFieldsSource),
        outputs: {
          'a|lib/item.form_screen.dart': decodedMatches(allOf(
            contains('_dueDateValue = item.dueDate'),
            contains(
                '_dueDateController.text = MaterialLocalizations.of(context)\n'),
            contains('.formatCompactDate(_dueDateValue!)'),
          )),
        },
      );
    });

    test('PF-8 — _prefillControllers sets enum dropdown value', () async {
      await testBuilder(
        formScreenBuilder(BuilderOptions.empty),
        _assets('a', 'lib/item.dart', _mixedFieldsSource),
        outputs: {
          'a|lib/item.form_screen.dart': decodedMatches(
            contains('_priorityValue = item.priority'),
          ),
        },
      );
    });

    test(
        'PF-8 — EditScreen state contains _prefilled flag and _prefillControllers method',
        () async {
      await testBuilder(
        formScreenBuilder(BuilderOptions.empty),
        _assets('a', 'lib/product.dart', _requiredSource),
        outputs: {
          'a|lib/product.form_screen.dart': decodedMatches(allOf(
            contains('bool _prefilled = false'),
            contains('_prefillControllers'),
          )),
        },
      );
    });

    test(
        'PF-15 — nullable fields: null-safe prefill, optional, required default',
        () async {
      await testBuilder(
        formScreenBuilder(BuilderOptions.empty),
        _assets('a', 'lib/item.dart', _nullableSource),
        outputs: {
          'a|lib/item.form_screen.dart': decodedMatches(allOf(
              allOf(
                // non-nullable text is required without Validator.required
                contains(
                    "if (value == null || value.isEmpty) return 'Required';"),
                contains('_nameController.text = item.name;'),
                contains("_nicknameController.text = item.nickname ?? '';"),
                contains("_ageController.text = item.age?.toString() ?? '';"),
                contains('_bornValue == null'),
              ),
              allOf(
                // optional validated field skips empty values
                contains('if (value == null || value.isEmpty) return null;'),
                // nullable bool / enum start as null with an empty option
                contains('bool? _activeValue;'),
                contains('DropdownButtonFormField<bool>'),
                contains('bool _doneValue = false;'),
                contains('Color? _colorValue;'),
                contains(
                    "DropdownMenuItem<Color>(value: null, child: Text(''))"),
              ))),
        },
      );
    });
  });
}
