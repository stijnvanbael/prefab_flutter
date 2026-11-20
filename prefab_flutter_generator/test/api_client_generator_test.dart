import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:prefab_flutter_generator/builder.dart';
import 'package:test/test.dart';
import 'support/prefab_sources.dart';

// ---------------------------------------------------------------------------
// Test entity sources
// ---------------------------------------------------------------------------

/// A simple entity without @Parent.
const _productSource = r'''
import 'package:prefab_flutter/prefab_flutter.dart';

@Entity(title: 'Product', path: 'products')
@Create()
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

@Entity(title: 'Post', path: 'posts')
@Create()
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

@Entity(title: 'Comment', path: 'comments')
@Create()
@Update()
@Delete()
class Comment {
  final int id;

  @Parent(Post)
  @Field(on: {})
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

@Entity(title: 'Post', path: 'posts')
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

@Entity(title: 'Comment', path: 'comments')
@Create()
@Update()
class Comment {
  final int id;
  @Parent(Post)
  @Field(on: {})
  final int postId;
  @Field(label: 'Content')
  final String content;
  Comment({required this.id, required this.postId, required this.content});
  factory Comment.fromJson(Map<String, dynamic> json) => throw 0;
  Map<String, dynamic> toJson() => {};
}
''';

Map<String, Object> _crossFile(String commentSource) => {
      ...Map<String, Object>.from(prefabSources),
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
      ...Map<String, Object>.from(prefabSources),
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
            matches(RegExp(
                r'Future<PrefabPage<Product>> list\(\s*\{String\? search')),
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
            matches(RegExp(
                r'Future<PrefabPage<Comment>> list\(\s*\{required int postId,')),
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
            matches(
                RegExp(r'Future<PrefabPage<Post>> list\(\s*\{String\? search')),
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
                matches(RegExp(
                    r'Future<PrefabPage<Comment>> list\(\s*\{required int postId,')),
              ),
            ),
            'a|lib/post.api_client.dart': anything,
          },
        );
      },
    );

    test('PF-24 @Parent(Type) without @Entity on the type is an error', () async {
      final source = _crossFileCommentSource
          .replaceFirst(
            'import \'post.dart\';',
            'import \'post.dart\';\nclass Plain { final int id = 0; }',
          )
          .replaceFirst('@Parent(Post)', '@Parent(Plain)');
      expect(
        await _buildError(_crossFile(source)),
        contains('without an @Entity annotation'),
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
              contains('_adapter.parsePage('),
              contains('Product.fromJson,'),
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

  group('PF-13 list query', () {
    test('AC#7 list accepts search, sort and page and returns a PrefabPage',
        () async {
      await testBuilder(
        apiClientBuilder(BuilderOptions.empty),
        _assets('a', 'lib/product.dart', _productSource),
        outputs: {
          'a|lib/product.api_client.dart': decodedMatches(
            allOf([
              contains('Future<PrefabPage<Product>> list('),
              contains('String? search'),
              contains('String? sort'),
              contains('bool descending = false'),
              contains('int page = 0'),
              contains('int? pageSize'),
              contains('_adapter.queryParameters('),
              contains('_adapter.parsePage('),
              contains(
                  "import 'package:prefab_flutter_widgets/prefab_flutter_widgets.dart'"),
              contains('final PrefabListAdapter _adapter')
            ]),
          ),
        },
      );
    });

    test('@Entity(paged: false) sends no page parameters', () async {
      final source = _productSource.replaceFirst(
          "path: 'products')", "path: 'products', paged: false)");
      await testBuilder(
        apiClientBuilder(BuilderOptions.empty),
        _assets('a', 'lib/product.dart', source),
        outputs: {
          'a|lib/product.api_client.dart': decodedMatches(
            isNot(contains('page: page')),
          ),
        },
      );
    });
  });
}
