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

const _productSource = r'''
import 'package:prefab_flutter/prefab_flutter.dart';

@View(title: 'Product', path: 'products')
class Product {
  final int id;

  @FormField(label: 'Name')
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
  group('ListScreenGenerator', () {
    // Non-parent entity

    test('generates a ListScreen ConsumerWidget for an entity', () async {
      await testBuilder(
        listScreenBuilder(BuilderOptions.empty),
        _assets('a', 'lib/product.dart', _productSource),
        outputs: {
          'a|lib/product.list_screen.dart': decodedMatches(
            contains('class ProductListScreen extends ConsumerWidget'),
          ),
        },
      );
    });

    test('non-parent screen has a const no-arg constructor', () async {
      await testBuilder(
        listScreenBuilder(BuilderOptions.empty),
        _assets('a', 'lib/product.dart', _productSource),
        outputs: {
          'a|lib/product.list_screen.dart': decodedMatches(
            contains('const ProductListScreen({super.key})'),
          ),
        },
      );
    });

    test('non-parent screen watches the list provider without family arg',
        () async {
      await testBuilder(
        listScreenBuilder(BuilderOptions.empty),
        _assets('a', 'lib/product.dart', _productSource),
        outputs: {
          'a|lib/product.list_screen.dart': decodedMatches(
            contains('ref.watch(productsProvider)'),
          ),
        },
      );
    });

    test('AppBar title uses the entity title from @View', () async {
      await testBuilder(
        listScreenBuilder(BuilderOptions.empty),
        _assets('a', 'lib/product.dart', _productSource),
        outputs: {
          'a|lib/product.list_screen.dart': decodedMatches(
            contains("const Text('Product')"),
          ),
        },
      );
    });

    test('generated file imports flutter, riverpod and go_router', () async {
      await testBuilder(
        listScreenBuilder(BuilderOptions.empty),
        _assets('a', 'lib/product.dart', _productSource),
        outputs: {
          'a|lib/product.list_screen.dart': decodedMatches(allOf(
            contains("import 'package:flutter/material.dart'"),
            contains("import 'package:flutter_riverpod/flutter_riverpod.dart'"),
            contains("import 'package:go_router/go_router.dart'"),
          )),
        },
      );
    });

    // AC#4 — @Parent: list screen receives parent ID and passes to provider

    test(
        'AC#4 @Parent — list screen constructor requires the parent ID',
        () async {
      await testBuilder(
        listScreenBuilder(BuilderOptions.empty),
        _assets('a', 'lib/post.dart', _parentChildSource),
        outputs: {
          'a|lib/post.list_screen.dart': decodedMatches(
            contains(
                'const CommentListScreen({super.key, required this.postId})'),
          ),
        },
      );
    });

    test(
        'AC#4 @Parent — list screen stores the parent ID as a field',
        () async {
      await testBuilder(
        listScreenBuilder(BuilderOptions.empty),
        _assets('a', 'lib/post.dart', _parentChildSource),
        outputs: {
          'a|lib/post.list_screen.dart': decodedMatches(
            contains('final int postId'),
          ),
        },
      );
    });

    test(
        'AC#4 @Parent — list screen passes parent ID to the list provider',
        () async {
      await testBuilder(
        listScreenBuilder(BuilderOptions.empty),
        _assets('a', 'lib/post.dart', _parentChildSource),
        outputs: {
          'a|lib/post.list_screen.dart': decodedMatches(
            contains('ref.watch(commentsProvider(postId))'),
          ),
        },
      );
    });

    test(
        'AC#4 @Parent — parent entity list screen is unaffected '
        '(no parent ID field)', () async {
      await testBuilder(
        listScreenBuilder(BuilderOptions.empty),
        _assets('a', 'lib/post.dart', _parentChildSource),
        outputs: {
          'a|lib/post.list_screen.dart': decodedMatches(
            contains('const PostListScreen({super.key})'),
          ),
        },
      );
    });

    test(
        'AC#4 @Parent — parent entity list screen watches non-family provider',
        () async {
      await testBuilder(
        listScreenBuilder(BuilderOptions.empty),
        _assets('a', 'lib/post.dart', _parentChildSource),
        outputs: {
          'a|lib/post.list_screen.dart': decodedMatches(
            contains('ref.watch(postsProvider)'),
          ),
        },
      );
    });

    // PF-9 — FAB for Create when @Update is present

    const productWithUpdateSource = r'''
import 'package:prefab_flutter/prefab_flutter.dart';

@View(title: 'Product', path: 'products')
@Update()
class Product {
  final int id;

  @FormField(label: 'Name')
  final String name;

  Product({required this.id, required this.name});
}
''';

    test('PF-9 — FAB is generated when @Update is present', () async {
      await testBuilder(
        listScreenBuilder(BuilderOptions.empty),
        _assets('a', 'lib/product.dart', productWithUpdateSource),
        outputs: {
          'a|lib/product.list_screen.dart': decodedMatches(allOf(
            contains('FloatingActionButton('),
            contains("'/products/create'"),
            contains('Icons.add'),
          )),
        },
      );
    });

    test('PF-9 — no FAB when @Update is absent', () async {
      await testBuilder(
        listScreenBuilder(BuilderOptions.empty),
        _assets('a', 'lib/product.dart', _productSource),
        outputs: {
          'a|lib/product.list_screen.dart': decodedMatches(
            isNot(contains('FloatingActionButton')),
          ),
        },
      );
    });
  });
}
