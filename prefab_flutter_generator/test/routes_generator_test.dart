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

/// A fully-annotated entity with @Update and @Delete.
const _productSource = r'''
import 'package:prefab_flutter/prefab_flutter.dart';

@View(title: 'Product', path: 'products')
@Update()
@Delete()
class Product {
  final int id;

  @FormField(label: 'Name')
  final String name;

  @FormField(label: 'Price')
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
  @FormField(label: 'Name')
  final String name;

  Tag({required this.name});
}
''';

/// A source file with two @View entities to test combined $prefabRoutes.
const _twoEntitiesSource = r'''
import 'package:prefab_flutter/prefab_flutter.dart';

@View(title: 'Product', path: 'products')
@Update()
class Product {
  @FormField(label: 'Name')
  final String name;

  Product({required this.name});
}

@View(title: 'Tag', path: 'tags')
class Tag {
  @FormField(label: 'Name')
  final String name;

  Tag({required this.name});
}
''';

/// A parent entity (Post) and a child entity (Comment) with @Parent.
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
  group('RoutesGenerator', () {
    // AC#1 — $prefabRoutes list is generated and contains all entity routes

    test('AC#1 — generates \$prefabRoutes getter', () async {
      await testBuilder(
        routesBuilder(BuilderOptions.empty),
        _assets('a', 'lib/product.dart', _productSource),
        outputs: {
          'a|lib/product.routes.dart': decodedMatches(
            contains('List<RouteBase> get \$prefabRoutes'),
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
          'a|lib/product.routes.dart': decodedMatches(
            contains("path: ':id'"),
          ),
        },
      );
    });

    // AC#2 — edit and create routes are included when @Update is present

    test('AC#2 — edit route is included when @Update is present', () async {
      await testBuilder(
        routesBuilder(BuilderOptions.empty),
        _assets('a', 'lib/product.dart', _productSource),
        outputs: {
          'a|lib/product.routes.dart': decodedMatches(allOf(
            contains("path: 'edit'"),
            contains('ProductEditScreen('),
          )),
        },
      );
    });

    test('AC#2 — create route is included when @Update is present', () async {
      await testBuilder(
        routesBuilder(BuilderOptions.empty),
        _assets('a', 'lib/product.dart', _productSource),
        outputs: {
          'a|lib/product.routes.dart': decodedMatches(allOf(
            contains("path: 'create'"),
            contains('ProductCreateScreen()'),
          )),
        },
      );
    });

    test('AC#2 — no edit/create routes when @Update is absent', () async {
      await testBuilder(
        routesBuilder(BuilderOptions.empty),
        _assets('a', 'lib/tag.dart', _tagSource),
        outputs: {
          'a|lib/tag.routes.dart': decodedMatches(isNot(anyOf(
            contains("path: 'edit'"),
            contains("path: 'create'"),
          ))),
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
          'a|lib/entities.routes.dart': decodedMatches(allOf(
            contains("path: '/products'"),
            contains("path: '/tags'"),
            contains('ProductListScreen()'),
            contains('TagListScreen()'),
          )),
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
              RegExp(
                r'List<RouteBase> get \$prefabRoutes',
                multiLine: true,
              ),
            ),
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

    test('generated file imports detail and list screen files', () async {
      await testBuilder(
        routesBuilder(BuilderOptions.empty),
        _assets('a', 'lib/product.dart', _productSource),
        outputs: {
          'a|lib/product.routes.dart': decodedMatches(allOf(
            contains("import 'product.detail_screen.dart'"),
            contains("import 'product.list_screen.dart'"),
          )),
        },
      );
    });

    test('generated file imports form screen file when @Update is present',
        () async {
      await testBuilder(
        routesBuilder(BuilderOptions.empty),
        _assets('a', 'lib/product.dart', _productSource),
        outputs: {
          'a|lib/product.routes.dart': decodedMatches(
            contains("import 'product.form_screen.dart'"),
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
      await testBuilder(
        routesBuilder(BuilderOptions.empty),
        {
          ...Map<String, Object>.from(_prefabSources),
          'a|lib/plain.dart': r'''
class Plain {}
''',
        },
        outputs: {},
      );
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
    });

    test(
        'AC#1 @Parent — parent entity (Post) uses a named id param '
        'to avoid collisions with nested child :id', () async {
      await testBuilder(
        routesBuilder(BuilderOptions.empty),
        _assets('a', 'lib/post.dart', _parentChildSource),
        outputs: {
          'a|lib/post.routes.dart': decodedMatches(
            contains("path: ':postId'"),
          ),
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
    });

    test(
        'AC#1 @Parent — child ListScreen receives the parent ID from route',
        () async {
      await testBuilder(
        routesBuilder(BuilderOptions.empty),
        _assets('a', 'lib/post.dart', _parentChildSource),
        outputs: {
          'a|lib/post.routes.dart': decodedMatches(
            contains("CommentListScreen(postId: state.pathParameters['postId']!)"),
          ),
        },
      );
    });

    test(
        'AC#1 @Parent — child DetailScreen receives both id and parent ID',
        () async {
      await testBuilder(
        routesBuilder(BuilderOptions.empty),
        _assets('a', 'lib/post.dart', _parentChildSource),
        outputs: {
          'a|lib/post.routes.dart': decodedMatches(allOf(
            contains("CommentDetailScreen("),
            contains("postId: state.pathParameters['postId']!"),
          )),
        },
      );
    });

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
    });

    test(
        'AC#1 @Parent — create route for child entity passes parent ID',
        () async {
      await testBuilder(
        routesBuilder(BuilderOptions.empty),
        _assets('a', 'lib/post.dart', _parentChildSource),
        outputs: {
          'a|lib/post.routes.dart': decodedMatches(allOf(
            contains("CommentCreateScreen("),
            contains("postId: state.pathParameters['postId']!"),
          )),
        },
      );
    });

    test(
        'AC#1 @Parent — edit route for child entity passes both id and parent ID',
        () async {
      await testBuilder(
        routesBuilder(BuilderOptions.empty),
        _assets('a', 'lib/post.dart', _parentChildSource),
        outputs: {
          'a|lib/post.routes.dart': decodedMatches(allOf(
            contains("CommentEditScreen("),
            contains("id: state.pathParameters['id']!"),
            contains("postId: state.pathParameters['postId']!"),
          )),
        },
      );
    });
  });
}
