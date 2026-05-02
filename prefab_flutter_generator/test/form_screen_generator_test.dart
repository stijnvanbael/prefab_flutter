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

/// Entity with Validator.required on a field.
const _requiredSource = r'''
import 'package:prefab_flutter/prefab_flutter.dart';

@View(title: 'Product', path: 'products')
@Update()
class Product {
  @FormField(label: 'Name', validators: [Validator.required])
  final String name;

  Product({required this.name});
}
''';

/// Entity with Validator.email on a field.
const _emailSource = r'''
import 'package:prefab_flutter/prefab_flutter.dart';

@View(title: 'User', path: 'users')
@Update()
class User {
  @FormField(label: 'Email', validators: [Validator.email])
  final String email;

  User({required this.email});
}
''';

/// Entity with Validator.positiveNumber on a field.
const _positiveNumberSource = r'''
import 'package:prefab_flutter/prefab_flutter.dart';

@View(title: 'Product', path: 'products')
@Update()
class Product {
  @FormField(label: 'Price', validators: [Validator.positiveNumber])
  final double price;

  Product({required this.price});
}
''';

/// Entity with Validator.url on a field.
const _urlSource = r'''
import 'package:prefab_flutter/prefab_flutter.dart';

@View(title: 'Resource', path: 'resources')
@Update()
class Resource {
  @FormField(label: 'URL', validators: [Validator.url])
  final String url;

  Resource({required this.url});
}
''';

/// Entity without @Update — no form screen should be generated.
const _tagSource = r'''
import 'package:prefab_flutter/prefab_flutter.dart';

@View(title: 'Tag', path: 'tags')
class Tag {
  @FormField(label: 'Name')
  final String name;

  Tag({required this.name});
}
''';

/// Entity with multiple validators on a single field.
const _multiValidatorSource = r'''
import 'package:prefab_flutter/prefab_flutter.dart';

@View(title: 'Contact', path: 'contacts')
@Update()
class Contact {
  @FormField(label: 'Email', validators: [Validator.required, Validator.email])
  final String email;

  Contact({required this.email});
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
  group('FormScreenGenerator', () {
    // Basic structure

    test('generates CreateScreen and EditScreen when @Update is present',
        () async {
      await testBuilder(
        formScreenBuilder(BuilderOptions.empty),
        _assets('a', 'lib/product.dart', _requiredSource),
        outputs: {
          'a|lib/product.form_screen.dart': decodedMatches(allOf(
            contains('class ProductCreateScreen extends ConsumerStatefulWidget'),
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
            contains("import 'package:flutter/material.dart'"),
            contains(
                "import 'package:flutter_riverpod/flutter_riverpod.dart'"),
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
  });
}
