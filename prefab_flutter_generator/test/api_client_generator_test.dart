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

/// A simple entity without @Parent.
const _productSource = r'''
import 'package:prefab_flutter/prefab_flutter.dart';

@View(title: 'Product', path: 'products')
@Update()
@Delete()
class Product {
  final int id;

  @FormField(label: 'Name')
  final String name;

  Product({required this.id, required this.name});
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

  @FormField(label: 'Title')
  final String title;

  Post({required this.id, required this.title});
}

@View(title: 'Comment', path: 'comments')
@Update()
@Delete()
class Comment {
  final int id;

  @Parent()
  @FormField(hidden: true)
  final int postId;

  @FormField(label: 'Content')
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
            contains('Future<Product> getById(Object id)'),
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
            contains('Future<Comment> getById(Object id, {required int postId})'),
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
                'Future<Comment> create(Comment comment, {required int postId})'),
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
                'Future<Comment> update(Comment comment, {required int postId})'),
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
                'Future<void> delete(Comment comment, {required int postId})'),
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
  });
}
