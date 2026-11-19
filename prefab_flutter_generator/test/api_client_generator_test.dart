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
// Test entity sources
// ---------------------------------------------------------------------------

/// A simple entity without @Parent.
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
  factory Product.fromJson(Map<String, dynamic> json) => throw 0;
  Map<String, dynamic> toJson() => {};
}
''';

/// Parent entity (Post) and child entity (Comment) with @Parent.
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
  factory Post.fromJson(Map<String, dynamic> json) => throw 0;
  Map<String, dynamic> toJson() => {};
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
  factory Comment.fromJson(Map<String, dynamic> json) => throw 0;
  Map<String, dynamic> toJson() => {};
}
''';

const _postFileSource = r'''
import 'package:prefab_flutter/prefab_flutter.dart';

@View(title: 'Post', path: 'posts')
class Post {
  final int id;
  @Field(label: 'Title')
  final String title;
  Post({required this.id, required this.title});
  factory Post.fromJson(Map<String, dynamic> json) => throw 0;
  Map<String, dynamic> toJson() => {};
}
''';

const _crossFileCommentSource = r'''
import 'package:prefab_flutter/prefab_flutter.dart';
import 'post.dart';

@View(title: 'Comment', path: 'comments')
@Update()
class Comment {
  final int id;
  @Parent(Post)
  @Field(hidden: true)
  final int postId;
  @Field(label: 'Content')
  final String content;
  Comment({required this.id, required this.postId, required this.content});
  factory Comment.fromJson(Map<String, dynamic> json) => throw 0;
  Map<String, dynamic> toJson() => {};
}
''';

Map<String, Object> _crossFile(String commentSource) => {
      ...Map<String, Object>.from(_prefabSources),
      'a|lib/post.dart': _postFileSource,
      'a|lib/comment.dart': commentSource,
    };

/// Runs the builder and returns everything it logged plus any thrown error.
Future<String> _buildError(Map<String, Object> assets) async {
  final logs = <String>[];
  try {
    await testBuilder(
      apiClientBuilder(BuilderOptions.empty),
      assets,
      onLog: (r) => logs.add('${r.message} ${r.error ?? ''}'),
    );
  } catch (e) {
    logs.add(e.toString());
  }
  return logs.join('\n');
}

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
  group('ApiClientGenerator', () {
    // Non-parent entity

    test('generates an ApiClient class for an entity', () async {
      await testBuilder(
        apiClientBuilder(BuilderOptions.empty),
        _assets('a', 'lib/product.dart', _productSource),
        outputs: {
          'a|lib/product.api_client.dart': decodedMatches(
            contains('class ProductApiClient'),
          ),
        },
      );
    });

    test('generated file imports dio', () async {
      await testBuilder(
        apiClientBuilder(BuilderOptions.empty),
        _assets('a', 'lib/product.dart', _productSource),
        outputs: {
          'a|lib/product.api_client.dart': decodedMatches(
            contains("import 'package:dio/dio.dart'"),
          ),
        },
      );
    });

    test('list method uses entity path in URL', () async {
      await testBuilder(
        apiClientBuilder(BuilderOptions.empty),
        _assets('a', 'lib/product.dart', _productSource),
        outputs: {
          'a|lib/product.api_client.dart': decodedMatches(
            contains("'/products'"),
          ),
        },
      );
    });

    test('list method has no extra parameters for non-parent entity', () async {
      await testBuilder(
        apiClientBuilder(BuilderOptions.empty),
        _assets('a', 'lib/product.dart', _productSource),
        outputs: {
          'a|lib/product.api_client.dart': decodedMatches(
            contains('Future<List<Product>> list()'),
          ),
        },
      );
    });

    test('getById method accepts an id parameter', () async {
      await testBuilder(
        apiClientBuilder(BuilderOptions.empty),
        _assets('a', 'lib/product.dart', _productSource),
        outputs: {
          'a|lib/product.api_client.dart': decodedMatches(
            contains('Future<Product> getById(int id)'),
          ),
        },
      );
    });

    // AC#2 — @Parent: parent ID injected into all API methods

    test('AC#2 @Parent — list method requires parent ID parameter', () async {
      await testBuilder(
        apiClientBuilder(BuilderOptions.empty),
        _assets('a', 'lib/post.dart', _parentChildSource),
        outputs: {
          'a|lib/post.api_client.dart': decodedMatches(
            contains('Future<List<Comment>> list({required int postId})'),
          ),
        },
      );
    });

    test('AC#2 @Parent — list URL is prefixed with parent path', () async {
      await testBuilder(
        apiClientBuilder(BuilderOptions.empty),
        _assets('a', 'lib/post.dart', _parentChildSource),
        outputs: {
          'a|lib/post.api_client.dart': decodedMatches(
            contains(r"'/posts/$postId/comments'"),
          ),
        },
      );
    });

    test('AC#2 @Parent — getById requires parent ID parameter', () async {
      await testBuilder(
        apiClientBuilder(BuilderOptions.empty),
        _assets('a', 'lib/post.dart', _parentChildSource),
        outputs: {
          'a|lib/post.api_client.dart': decodedMatches(
            contains('Future<Comment> getById(int id, {required int postId})'),
          ),
        },
      );
    });

    test('AC#2 @Parent — create requires parent ID parameter', () async {
      await testBuilder(
        apiClientBuilder(BuilderOptions.empty),
        _assets('a', 'lib/post.dart', _parentChildSource),
        outputs: {
          'a|lib/post.api_client.dart': decodedMatches(
            contains(
              'Future<Comment> create(Comment comment, {required int postId})',
            ),
          ),
        },
      );
    });

    test('AC#2 @Parent — update requires parent ID parameter', () async {
      await testBuilder(
        apiClientBuilder(BuilderOptions.empty),
        _assets('a', 'lib/post.dart', _parentChildSource),
        outputs: {
          'a|lib/post.api_client.dart': decodedMatches(
            contains(
              'Future<Comment> update(Comment comment, {required int postId})',
            ),
          ),
        },
      );
    });

    test('AC#2 @Parent — delete requires parent ID parameter', () async {
      await testBuilder(
        apiClientBuilder(BuilderOptions.empty),
        _assets('a', 'lib/post.dart', _parentChildSource),
        outputs: {
          'a|lib/post.api_client.dart': decodedMatches(
            contains(
              'Future<void> delete(Comment comment, {required int postId})',
            ),
          ),
        },
      );
    });

    test('AC#2 @Parent — parent entity itself has no parent params', () async {
      await testBuilder(
        apiClientBuilder(BuilderOptions.empty),
        _assets('a', 'lib/post.dart', _parentChildSource),
        outputs: {
          'a|lib/post.api_client.dart': decodedMatches(
            contains('Future<List<Post>> list()'),
          ),
        },
      );
    });

    // PF-24 — cross-file parents and build-time validation

    test(
      'PF-24 @Parent(Type) resolves a parent declared in another file',
      () async {
        await testBuilder(
          apiClientBuilder(BuilderOptions.empty),
          _crossFile(_crossFileCommentSource),
          outputs: {
            'a|lib/comment.api_client.dart': decodedMatches(
              allOf(
                contains("'/posts/\$postId/comments'"),
                contains('Future<List<Comment>> list({required int postId})'),
              ),
            ),
            'a|lib/post.api_client.dart': anything,
          },
        );
      },
    );

    test('PF-24 @Parent(Type) without @View on the type is an error', () async {
      final source = _crossFileCommentSource
          .replaceFirst(
            'import \'post.dart\';',
            'import \'post.dart\';\nclass Plain { final int id = 0; }',
          )
          .replaceFirst('@Parent(Post)', '@Parent(Plain)');
      expect(
        await _buildError(_crossFile(source)),
        contains('without a @View annotation'),
      );
    });

    test('PF-24 @Parent field type must match the parent id type', () async {
      final source = _crossFileCommentSource.replaceFirst(
        'final int postId;',
        'final String postId;',
      );
      expect(await _buildError(_crossFile(source)), contains('Type mismatch'));
    });

    // PF-12 — JSON (de)serialization

    test('PF-12 list deserializes with fromJson', () async {
      await testBuilder(
        apiClientBuilder(BuilderOptions.empty),
        _assets('a', 'lib/product.dart', _productSource),
        outputs: {
          'a|lib/product.api_client.dart': decodedMatches(
            allOf(
              contains('(response.data as List)'),
              contains(
                '.map((e) => Product.fromJson(e as Map<String, dynamic>))',
              ),
            ),
          ),
        },
      );
    });

    test('PF-12 getById/create/update deserialize a single object', () async {
      await testBuilder(
        apiClientBuilder(BuilderOptions.empty),
        _assets('a', 'lib/product.dart', _productSource),
        outputs: {
          'a|lib/product.api_client.dart': decodedMatches(
            allOf(
              contains(
                'return Product.fromJson(response.data as Map<String, dynamic>);',
              ),
              isNot(contains('response.data as Product')),
            ),
          ),
        },
      );
    });

    test('PF-12 create and update send toJson() as the body', () async {
      await testBuilder(
        apiClientBuilder(BuilderOptions.empty),
        _assets('a', 'lib/product.dart', _productSource),
        outputs: {
          'a|lib/product.api_client.dart': decodedMatches(
            allOf(
              contains("_dio.post('/products', data: product.toJson())"),
              contains('data: product.toJson())'),
              isNot(contains('data: product)')),
            ),
          ),
        },
      );
    });

    test('PF-12 missing fromJson names the entity', () async {
      final source = _productSource.replaceFirst(
        '  factory Product.fromJson(Map<String, dynamic> json) => throw 0;\n',
        '',
      );
      final error = await _buildError(_assets('a', 'lib/product.dart', source));
      expect(error, contains('Product'));
      expect(error, contains('fromJson'));
      expect(error, isNot(contains('toJson()" method')));
    });

    test('PF-12 missing toJson names the entity', () async {
      final source = _productSource.replaceFirst(
        '  Map<String, dynamic> toJson() => {};\n',
        '',
      );
      final error = await _buildError(_assets('a', 'lib/product.dart', source));
      expect(error, contains('Product'));
      expect(error, contains('toJson()'));
    });
  });
}
