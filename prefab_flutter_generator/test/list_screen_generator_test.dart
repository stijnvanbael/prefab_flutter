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
  final bool searchable;
  final bool sortable;
  const FormField({
    this.label,
    this.widget = FieldWidget.auto,
    this.validators = const [],
    this.hidden = false,
    this.searchable = false,
    this.sortable = false,
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

/// Entity with a searchable field — should produce a search bar (AC#1).
const _searchableSource = r'''
import 'package:prefab_flutter/prefab_flutter.dart';

@View(title: 'Product', path: 'products')
class Product {
  final int id;

  @FormField(label: 'Name', searchable: true)
  final String name;

  Product({required this.id, required this.name});
}
''';

/// Entity with a sortable field — should produce sort controls (AC#2).
const _sortableSource = r'''
import 'package:prefab_flutter/prefab_flutter.dart';

@View(title: 'Product', path: 'products')
class Product {
  final int id;

  @FormField(label: 'Name', sortable: true)
  final String name;

  Product({required this.id, required this.name});
}
''';

/// Entity with both searchable and sortable fields.
const _searchableSortableSource = r'''
import 'package:prefab_flutter/prefab_flutter.dart';

@View(title: 'Article', path: 'articles')
class Article {
  final int id;

  @FormField(label: 'Title', searchable: true, sortable: true)
  final String title;

  Article({required this.id, required this.title});
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

    // AC#1 — search bar is generated when searchable fields exist

    test('AC#1 — search bar is generated when a field has searchable: true',
        () async {
      await testBuilder(
        listScreenBuilder(BuilderOptions.empty),
        _assets('a', 'lib/searchable.dart', _searchableSource),
        outputs: {
          'a|lib/searchable.list_screen.dart': decodedMatches(allOf(
            contains('TextField('),
            contains('_searchQuery'),
          )),
        },
      );
    });

    test(
        'AC#1 — search bar filters using the searchable field value',
        () async {
      await testBuilder(
        listScreenBuilder(BuilderOptions.empty),
        _assets('a', 'lib/searchable.dart', _searchableSource),
        outputs: {
          'a|lib/searchable.list_screen.dart': decodedMatches(allOf(
            contains('_searchQuery.isNotEmpty'),
            contains('product.name.toString().toLowerCase().contains(query)'),
          )),
        },
      );
    });

    test(
        'AC#1 — list screen becomes ConsumerStatefulWidget when searchable',
        () async {
      await testBuilder(
        listScreenBuilder(BuilderOptions.empty),
        _assets('a', 'lib/searchable.dart', _searchableSource),
        outputs: {
          'a|lib/searchable.list_screen.dart': decodedMatches(
            contains(
                'class ProductListScreen extends ConsumerStatefulWidget'),
          ),
        },
      );
    });

    test('AC#1 — no search bar when no field has searchable: true', () async {
      await testBuilder(
        listScreenBuilder(BuilderOptions.empty),
        _assets('a', 'lib/product.dart', _productSource),
        outputs: {
          'a|lib/product.list_screen.dart': decodedMatches(
            isNot(contains('_searchQuery')),
          ),
        },
      );
    });

    // AC#2 — sort column is generated when sortable fields exist

    test('AC#2 — sort control is generated when a field has sortable: true',
        () async {
      await testBuilder(
        listScreenBuilder(BuilderOptions.empty),
        _assets('a', 'lib/sortable.dart', _sortableSource),
        outputs: {
          'a|lib/sortable.list_screen.dart': decodedMatches(allOf(
            contains('DropdownButton<String>('),
            contains('_sortColumn'),
          )),
        },
      );
    });

    test(
        'AC#2 — sort dropdown includes a menu item for each sortable field',
        () async {
      await testBuilder(
        listScreenBuilder(BuilderOptions.empty),
        _assets('a', 'lib/sortable.dart', _sortableSource),
        outputs: {
          'a|lib/sortable.list_screen.dart': decodedMatches(allOf(
            contains("DropdownMenuItem(value: 'name'"),
            contains("Text('Name')"),
          )),
        },
      );
    });

    test('AC#2 — sort applies compareTo on the sortable field value', () async {
      await testBuilder(
        listScreenBuilder(BuilderOptions.empty),
        _assets('a', 'lib/sortable.dart', _sortableSource),
        outputs: {
          'a|lib/sortable.list_screen.dart': decodedMatches(
            contains('a.name.toString().compareTo(b.name.toString())'),
          ),
        },
      );
    });

    test('AC#2 — no sort control when no field has sortable: true', () async {
      await testBuilder(
        listScreenBuilder(BuilderOptions.empty),
        _assets('a', 'lib/product.dart', _productSource),
        outputs: {
          'a|lib/product.list_screen.dart': decodedMatches(
            isNot(contains('_sortColumn')),
          ),
        },
      );
    });

    test(
        'AC#1+AC#2 — screen has both search bar and sort control when '
        'fields are both searchable and sortable', () async {
      await testBuilder(
        listScreenBuilder(BuilderOptions.empty),
        _assets('a', 'lib/article.dart', _searchableSortableSource),
        outputs: {
          'a|lib/article.list_screen.dart': decodedMatches(allOf(
            contains('TextField('),
            contains('_searchQuery'),
            contains('DropdownButton<String>('),
            contains('_sortColumn'),
          )),
        },
      );
    });
  });
}
