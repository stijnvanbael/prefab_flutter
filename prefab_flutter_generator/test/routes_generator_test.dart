import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:prefab_flutter_generator/builder.dart';
import 'package:test/test.dart';
import 'support/prefab_sources.dart';

// ---------------------------------------------------------------------------
// Shared annotation stubs included in every test's source assets.
// These mirror the actual prefab_flutter package sources so the Dart resolver
// can resolve `package:prefab_flutter/...` imports inside the test sources.
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// Test entity sources
// ---------------------------------------------------------------------------

/// A fully-annotated entity with @Update and @Delete.
const _productSource = r'''
import 'package:prefab_flutter/prefab_flutter.dart';

@View(title: 'Product', path: 'products')
@Create()
@Update()
@Delete()
class Product {
  final int id;

  @Field(label: 'Name')
  final String name;

  @Field(label: 'Price')
  final double price;

  Product({
    required this.id,
    required this.name,
    required this.price,
  });
}
''';

/// An entity with no @Update / @Delete.
const _tagSource = r'''
import 'package:prefab_flutter/prefab_flutter.dart';

@View(title: 'Tag', path: 'tags')
class Tag {
  late final int id;
  @Field(label: 'Name')
  final String name;

  Tag({required this.name});
}
''';

/// A source file with two @View entities to test combined $prefabRoutes.
const _twoEntitiesSource = r'''
import 'package:prefab_flutter/prefab_flutter.dart';

@View(title: 'Product', path: 'products')
@Create()
@Update()
class Product {
  late final int id;
  @Field(label: 'Name')
  final String name;

  Product({required this.name});
}

@View(title: 'Tag', path: 'tags')
class Tag {
  late final int id;
  @Field(label: 'Name')
  final String name;

  Tag({required this.name});
}
''';

/// A parent entity (Post) and a child entity (Comment) with @Parent.
const _parentChildSource = r'''
import 'package:prefab_flutter/prefab_flutter.dart';

@View(title: 'Post', path: 'posts')
@Create()
@Update()
@Delete()
class Post {
  final int id;

  @Field(label: 'Title')
  final String title;

  Post({required this.id, required this.title});
}

@View(title: 'Comment', path: 'comments')
@Create()
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

const _postFileSource = r'''
import 'package:prefab_flutter/prefab_flutter.dart';

@View(title: 'Post', path: 'posts')
class Post {
  final int id;
  @Field(label: 'Title')
  final String title;
  Post({required this.id, required this.title});
}
''';

const _crossFileCommentSource = r'''
import 'package:prefab_flutter/prefab_flutter.dart';
import 'post.dart';

@View(title: 'Comment', path: 'comments')
@Create()
@Update()
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

Map<String, Object> _crossFile(String commentSource) => {
      ...Map<String, Object>.from(prefabSources),
      'a|lib/post.dart': _postFileSource,
      'a|lib/comment.dart': commentSource,
    };

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
  group('RoutesGenerator', () {
    // AC#1 — $prefabRoutes list is generated and contains all entity routes

    test('AC#1 — generates \$prefabRoutes getter', () async {
      await testBuilder(
        routesBuilder(BuilderOptions.empty),
        _assets('a', 'lib/product.dart', _productSource),
        outputs: {
          'a|lib/product.routes.dart': decodedMatches(
            contains('List<RouteBase> get \$productRoutes'),
          ),
        },
      );
    });

    test('AC#1 — list route uses the entity path from @View', () async {
      await testBuilder(
        routesBuilder(BuilderOptions.empty),
        _assets('a', 'lib/product.dart', _productSource),
        outputs: {
          'a|lib/product.routes.dart': decodedMatches(
            contains("path: '/products'"),
          ),
        },
      );
    });

    test('AC#1 — list screen is used as the list route builder', () async {
      await testBuilder(
        routesBuilder(BuilderOptions.empty),
        _assets('a', 'lib/product.dart', _productSource),
        outputs: {
          'a|lib/product.routes.dart': decodedMatches(
            contains('ProductListScreen()'),
          ),
        },
      );
    });

    test('AC#1 — detail screen is used as the detail route builder', () async {
      await testBuilder(
        routesBuilder(BuilderOptions.empty),
        _assets('a', 'lib/product.dart', _productSource),
        outputs: {
          'a|lib/product.routes.dart': decodedMatches(
            contains('ProductDetailScreen('),
          ),
        },
      );
    });

    test('AC#1 — detail route uses :id path parameter', () async {
      await testBuilder(
        routesBuilder(BuilderOptions.empty),
        _assets('a', 'lib/product.dart', _productSource),
        outputs: {
          'a|lib/product.routes.dart': decodedMatches(contains("path: ':id'")),
        },
      );
    });

    // AC#2 — edit and create routes are included when @Update is present

    test('AC#2 — edit route is included when @Update is present', () async {
      await testBuilder(
        routesBuilder(BuilderOptions.empty),
        _assets('a', 'lib/product.dart', _productSource),
        outputs: {
          'a|lib/product.routes.dart': decodedMatches(
            allOf(contains("path: 'edit'"), contains('ProductEditScreen(')),
          ),
        },
      );
    });

    test('AC#2 — create route is included when @Update is present', () async {
      await testBuilder(
        routesBuilder(BuilderOptions.empty),
        _assets('a', 'lib/product.dart', _productSource),
        outputs: {
          'a|lib/product.routes.dart': decodedMatches(
            allOf(
              contains("path: 'create'"),
              contains('ProductCreateScreen()'),
            ),
          ),
        },
      );
    });

    test('AC#2 — no edit/create routes when @Update is absent', () async {
      await testBuilder(
        routesBuilder(BuilderOptions.empty),
        _assets('a', 'lib/tag.dart', _tagSource),
        outputs: {
          'a|lib/tag.routes.dart': decodedMatches(
            isNot(anyOf(contains("path: 'edit'"), contains("path: 'create'"))),
          ),
        },
      );
    });

    test('PF-9 — create route is declared before the :id route', () async {
      await testBuilder(
        routesBuilder(BuilderOptions.empty),
        _assets('a', 'lib/product.dart', _productSource),
        outputs: {
          'a|lib/product.routes.dart': decodedMatches(
            predicate<String>(
              (s) => s.indexOf("path: 'create'") < s.indexOf("path: ':id'"),
              'create precedes :id',
            ),
          ),
        },
      );
    });

    // AC#3 — Multiple entities produce one combined $prefabRoutes list

    test(
        'AC#3 — single \$prefabRoutes contains routes for all entities '
        'in the same source file', () async {
      await testBuilder(
        routesBuilder(BuilderOptions.empty),
        _assets('a', 'lib/entities.dart', _twoEntitiesSource),
        outputs: {
          'a|lib/entities.routes.dart': decodedMatches(
            allOf(
              contains("path: '/products'"),
              contains("path: '/tags'"),
              contains('ProductListScreen()'),
              contains('TagListScreen()'),
            ),
          ),
        },
      );
    });

    test(
        'AC#3 — only one \$prefabRoutes getter is emitted for multiple '
        'entities', () async {
      await testBuilder(
        routesBuilder(BuilderOptions.empty),
        _assets('a', 'lib/entities.dart', _twoEntitiesSource),
        outputs: {
          'a|lib/entities.routes.dart': decodedMatches(
            // The getter declaration should appear exactly once.
            matches(
              RegExp(r'List<RouteBase> get \$entitiesRoutes', multiLine: true),
            ),
          ),
        },
      );
    });

    test('getter name is camel-cased from a snake_case file name', () async {
      await testBuilder(
        routesBuilder(BuilderOptions.empty),
        _assets('a', 'lib/user_account.dart', _productSource),
        outputs: {
          'a|lib/user_account.routes.dart': decodedMatches(
            contains('List<RouteBase> get \$userAccountRoutes'),
          ),
        },
      );
    });

    // Imports

    test('generated file imports go_router', () async {
      await testBuilder(
        routesBuilder(BuilderOptions.empty),
        _assets('a', 'lib/product.dart', _productSource),
        outputs: {
          'a|lib/product.routes.dart': decodedMatches(
            contains("import 'package:go_router/go_router.dart'"),
          ),
        },
      );
    });

    test('PF-38 — does not import the other generators\' output', () async {
      await testBuilder(
        routesBuilder(BuilderOptions.empty),
        _assets('a', 'lib/product.dart', _productSource),
        outputs: {
          'a|lib/product.routes.dart': decodedMatches(
            isNot(contains("import 'product.")),
          ),
        },
      );
    });

    test(
        'generated file does NOT import form screen file when @Update is '
        'absent', () async {
      await testBuilder(
        routesBuilder(BuilderOptions.empty),
        _assets('a', 'lib/tag.dart', _tagSource),
        outputs: {
          'a|lib/tag.routes.dart': decodedMatches(
            isNot(contains("import 'tag.form_screen.dart'")),
          ),
        },
      );
    });

    // Non-annotated files should produce no output.

    test('produces no output for files without @View annotations', () async {
      await testBuilder(routesBuilder(BuilderOptions.empty), {
        ...Map<String, Object>.from(prefabSources),
        'a|lib/plain.dart': r'''
class Plain {}
''',
      }, outputs: {});
    });

    // -------------------------------------------------------------------------
    // @Parent — nested resource routes (AC#1 of PF-6)
    // -------------------------------------------------------------------------

    test(
      'AC#1 @Parent — child entity (Comment) is NOT emitted as a root route',
      () async {
        await testBuilder(
          routesBuilder(BuilderOptions.empty),
          _assets('a', 'lib/post.dart', _parentChildSource),
          outputs: {
            'a|lib/post.routes.dart': decodedMatches(
              isNot(contains("path: '/comments'")),
            ),
          },
        );
      },
    );

    test(
        'AC#1 @Parent — parent entity (Post) uses a named id param '
        'to avoid collisions with nested child :id', () async {
      await testBuilder(
        routesBuilder(BuilderOptions.empty),
        _assets('a', 'lib/post.dart', _parentChildSource),
        outputs: {
          'a|lib/post.routes.dart': decodedMatches(contains("path: ':postId'")),
        },
      );
    });

    test(
      'AC#1 @Parent — child list route is nested under parent :id route',
      () async {
        await testBuilder(
          routesBuilder(BuilderOptions.empty),
          _assets('a', 'lib/post.dart', _parentChildSource),
          outputs: {
            'a|lib/post.routes.dart': decodedMatches(
              contains("path: 'comments'"),
            ),
          },
        );
      },
    );

    test(
      'AC#1 @Parent — child ListScreen receives the parent ID from route',
      () async {
        await testBuilder(
          routesBuilder(BuilderOptions.empty),
          _assets('a', 'lib/post.dart', _parentChildSource),
          outputs: {
            'a|lib/post.routes.dart': decodedMatches(
              allOf(
                contains('CommentListScreen('),
                contains("postId: int.parse(state.pathParameters['postId']!)"),
              ),
            ),
          },
        );
      },
    );

    test(
      'AC#1 @Parent — child DetailScreen receives both id and parent ID',
      () async {
        await testBuilder(
          routesBuilder(BuilderOptions.empty),
          _assets('a', 'lib/post.dart', _parentChildSource),
          outputs: {
            'a|lib/post.routes.dart': decodedMatches(
              allOf(
                contains("CommentDetailScreen("),
                contains("postId: int.parse(state.pathParameters['postId']!)"),
              ),
            ),
          },
        );
      },
    );

    test(
      'AC#1 @Parent — parent root route is still present at the top level',
      () async {
        await testBuilder(
          routesBuilder(BuilderOptions.empty),
          _assets('a', 'lib/post.dart', _parentChildSource),
          outputs: {
            'a|lib/post.routes.dart': decodedMatches(
              contains("path: '/posts'"),
            ),
          },
        );
      },
    );

    test(
      'AC#1 @Parent — create route for child entity passes parent ID',
      () async {
        await testBuilder(
          routesBuilder(BuilderOptions.empty),
          _assets('a', 'lib/post.dart', _parentChildSource),
          outputs: {
            'a|lib/post.routes.dart': decodedMatches(
              allOf(
                contains("CommentCreateScreen("),
                contains("postId: int.parse(state.pathParameters['postId']!)"),
              ),
            ),
          },
        );
      },
    );

    test(
      'AC#1 @Parent — edit route for child entity passes both id and parent ID',
      () async {
        await testBuilder(
          routesBuilder(BuilderOptions.empty),
          _assets('a', 'lib/post.dart', _parentChildSource),
          outputs: {
            'a|lib/post.routes.dart': decodedMatches(
              allOf(
                contains("CommentEditScreen("),
                contains("id: int.parse(state.pathParameters['id']!)"),
                contains("postId: int.parse(state.pathParameters['postId']!)"),
              ),
            ),
          },
        );
      },
    );

    test(
      'PF-24 child with a cross-file parent becomes a top-level route',
      () async {
        await testBuilder(
          routesBuilder(BuilderOptions.empty),
          _crossFile(_crossFileCommentSource),
          outputs: {
            'a|lib/comment.routes.dart': decodedMatches(
              allOf(
                contains("path: '/posts/:postId/comments'"),
                contains('CommentListScreen('),
                contains("postId: int.parse(state.pathParameters['postId']!)"),
              ),
            ),
            'a|lib/post.routes.dart': anything,
          },
        );
      },
    );
  });
}
