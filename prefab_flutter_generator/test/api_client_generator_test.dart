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
  final Type type;
  const Parent(this.type);
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

  @Parent(Post)
  @FormField(hidden: true)
  final int postId;

  @FormField(label: 'Content')
  final String content;

  Comment({required this.id, required this.postId, required this.content});
}
''';


const _postFileSource = r'''
import 'package:prefab_flutter/prefab_flutter.dart';

@View(title: 'Post', path: 'posts')
class Post {
  final int id;
  @FormField(label: 'Title')
  final String title;
  Post({required this.id, required this.title});
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
  @FormField(hidden: true)
  final int postId;
  @FormField(label: 'Content')
  final String content;
  Comment({required this.id, required this.postId, required this.content});
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

    // PF-24 — cross-file parents and build-time validation

    test('PF-24 @Parent(Type) resolves a parent declared in another file',
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
    });

    test('PF-24 @Parent(Type) without @View on the type is an error',
        () async {
      final source = _crossFileCommentSource.replaceFirst(
          'import \'post.dart\';',
          'import \'post.dart\';\nclass Plain { final int id = 0; }').replaceFirst(
          '@Parent(Post)', '@Parent(Plain)');
      expect(
        await _buildError(_crossFile(source)),
        contains('without a @View annotation'),
      );
    });

    test('PF-24 @Parent field type must match the parent id type', () async {
      final source = _crossFileCommentSource.replaceFirst(
          'final int postId;', 'final String postId;');
      expect(
        await _buildError(_crossFile(source)),
        contains('Type mismatch'),
      );
    });
  });
}
