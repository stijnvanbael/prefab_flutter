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

const _productSource = r'''
import 'package:prefab_flutter/prefab_flutter.dart';

@View(title: 'Product', path: 'products')
@Update()
@Delete()
class Product {
  final int id;

  @Field(label: 'Name')
  final String name;

  Product({required this.id, required this.name});
}
''';

const _parentChildSource = r'''
import 'package:prefab_flutter/prefab_flutter.dart';

@View(title: 'Post', path: 'posts')
@Update()
@Delete()
class Post {
  final int id;

  @Field(label: 'Title')
  final String title;

  Post({required this.id, required this.title});
}

@View(title: 'Comment', path: 'comments')
@Update()
@Delete()
class Comment {
  final int id;

  @Parent(Post)
  @Field(hidden: true)
  final int postId;

  @Field(label: 'Content')
  final String content;

  Comment({required this.id, required this.postId, required this.content});
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
  group('ProviderGenerator', () {
    // Non-parent entity

    test('generates a detail provider for an entity', () async {
      await testBuilder(
        providerBuilder(BuilderOptions.empty),
        _assets('a', 'lib/product.dart', _productSource),
        outputs: {
          'a|lib/product.provider.dart': decodedMatches(
            contains('productDetailProvider'),
          ),
        },
      );
    });

    test('generates a list AsyncNotifier for an entity', () async {
      await testBuilder(
        providerBuilder(BuilderOptions.empty),
        _assets('a', 'lib/product.dart', _productSource),
        outputs: {
          'a|lib/product.provider.dart': decodedMatches(
            allOf(
              contains(
                'class ProductsNotifier extends AutoDisposeAsyncNotifier<List<Product>>',
              ),
              contains('AsyncNotifierProvider.autoDispose'),
              isNot(contains('StateNotifier')),
            ),
          ),
        },
      );
    });

    test('list notifier has load, create, update and delete methods', () async {
      await testBuilder(
        providerBuilder(BuilderOptions.empty),
        _assets('a', 'lib/product.dart', _productSource),
        outputs: {
          'a|lib/product.provider.dart': decodedMatches(
            allOf(
              contains('_load()'),
              contains('Future<void> create('),
              contains('Future<void> update('),
              contains('Future<void> delete('),
            ),
          ),
        },
      );
    });

    test('generated file imports flutter_riverpod', () async {
      await testBuilder(
        providerBuilder(BuilderOptions.empty),
        _assets('a', 'lib/product.dart', _productSource),
        outputs: {
          'a|lib/product.provider.dart': decodedMatches(
            contains("import 'package:flutter_riverpod/flutter_riverpod.dart'"),
          ),
        },
      );
    });

    test('API client provider watches prefabDioProvider', () async {
      await testBuilder(
        providerBuilder(BuilderOptions.empty),
        _assets('a', 'lib/product.dart', _productSource),
        outputs: {
          'a|lib/product.provider.dart': decodedMatches(
            allOf(
              contains(
                "import 'package:prefab_flutter_widgets/prefab_flutter_widgets.dart'",
              ),
              contains('ref.watch(prefabDioProvider)'),
              isNot(contains('ref.watch(dioProvider)')),
            ),
          ),
        },
      );
    });

    // AC#3 — @Parent: parent ID threaded through all operations

    test(
      'AC#3 @Parent — detail provider is keyed on (Object, parentType) record',
      () async {
        await testBuilder(
          providerBuilder(BuilderOptions.empty),
          _assets('a', 'lib/post.dart', _parentChildSource),
          outputs: {
            'a|lib/post.provider.dart': decodedMatches(
              contains('.family<Comment, (int, int)>'),
            ),
          },
        );
      },
    );

    test(
        'AC#3 @Parent — detail provider passes both id and parentId to API client',
        () async {
      await testBuilder(
        providerBuilder(BuilderOptions.empty),
        _assets('a', 'lib/post.dart', _parentChildSource),
        outputs: {
          'a|lib/post.provider.dart': decodedMatches(
            allOf(contains('args.\$1'), contains('postId: args.\$2')),
          ),
        },
      );
    });

    test(
      'AC#3 @Parent — list provider is a family keyed on the parent ID type',
      () async {
        await testBuilder(
          providerBuilder(BuilderOptions.empty),
          _assets('a', 'lib/post.dart', _parentChildSource),
          outputs: {
            'a|lib/post.provider.dart': decodedMatches(
              allOf(
                contains('AsyncNotifierProvider.autoDispose'),
                contains('.family<CommentsNotifier, List<Comment>, int>'),
              ),
            ),
          },
        );
      },
    );

    test('AC#3 @Parent — family notifier exposes the parent ID', () async {
      await testBuilder(
        providerBuilder(BuilderOptions.empty),
        _assets('a', 'lib/post.dart', _parentChildSource),
        outputs: {
          'a|lib/post.provider.dart': decodedMatches(
            allOf(
              contains('class CommentsNotifier'),
              contains('AutoDisposeFamilyAsyncNotifier<List<Comment>, int>'),
              contains('int get postId => arg'),
            ),
          ),
        },
      );
    });

    test(
      'AC#3 @Parent — family notifier _load passes parentId to API client',
      () async {
        await testBuilder(
          providerBuilder(BuilderOptions.empty),
          _assets('a', 'lib/post.dart', _parentChildSource),
          outputs: {
            'a|lib/post.provider.dart': decodedMatches(
              contains('_client.list(postId: postId)'),
            ),
          },
        );
      },
    );

    test('AC#3 @Parent — create passes parentId to API client', () async {
      await testBuilder(
        providerBuilder(BuilderOptions.empty),
        _assets('a', 'lib/post.dart', _parentChildSource),
        outputs: {
          'a|lib/post.provider.dart': decodedMatches(
            contains('_client.create(comment, postId: postId)'),
          ),
        },
      );
    });

    test('AC#3 @Parent — update passes parentId to API client', () async {
      await testBuilder(
        providerBuilder(BuilderOptions.empty),
        _assets('a', 'lib/post.dart', _parentChildSource),
        outputs: {
          'a|lib/post.provider.dart': decodedMatches(
            contains('_client.update(comment, postId: postId)'),
          ),
        },
      );
    });

    test('AC#3 @Parent — delete passes parentId to API client', () async {
      await testBuilder(
        providerBuilder(BuilderOptions.empty),
        _assets('a', 'lib/post.dart', _parentChildSource),
        outputs: {
          'a|lib/post.provider.dart': decodedMatches(
            contains('_client.delete(comment, postId: postId)'),
          ),
        },
      );
    });

    test(
      'AC#3 @Parent — parent entity provider is not affected by child entity',
      () async {
        await testBuilder(
          providerBuilder(BuilderOptions.empty),
          _assets('a', 'lib/post.dart', _parentChildSource),
          outputs: {
            'a|lib/post.provider.dart': decodedMatches(
              contains('FutureProvider.autoDispose.family<Post, int>'),
            ),
          },
        );
      },
    );

    // PF-28 — detail provider invalidation

    test('PF-28 update and delete invalidate the detail provider', () async {
      await testBuilder(
        providerBuilder(BuilderOptions.empty),
        _assets('a', 'lib/product.dart', _productSource),
        outputs: {
          'a|lib/product.provider.dart': decodedMatches(
            allOf(
              matches(
                RegExp(
                  r'update\(Product product\) async \{\n[^}]*'
                  r'ref\.invalidate\(productDetailProvider\(product\.id\)\);',
                ),
              ),
              matches(
                RegExp(
                  r'delete\(Product product\) async \{\n[^}]*'
                  r'ref\.invalidate\(productDetailProvider\(product\.id\)\);',
                ),
              ),
            ),
          ),
        },
      );
    });

    test(
      'PF-28 @Parent — invalidates the (id, parentId) detail provider',
      () async {
        await testBuilder(
          providerBuilder(BuilderOptions.empty),
          _assets('a', 'lib/post.dart', _parentChildSource),
          outputs: {
            'a|lib/post.provider.dart': decodedMatches(
              contains(
                'ref.invalidate(commentDetailProvider((comment.id, postId)));',
              ),
            ),
          },
        );
      },
    );
  });
}
