import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:prefab_flutter_generator/builder.dart';
import 'package:test/test.dart';
import 'support/prefab_sources.dart';

// ---------------------------------------------------------------------------
// Test entity sources
// ---------------------------------------------------------------------------

const _productSource = r'''
import 'package:prefab_flutter/prefab_flutter.dart';

@View(title: 'Product', path: 'products')
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

const _viewsSource = r'''
import 'package:prefab_flutter/prefab_flutter.dart';

@View(title: 'Item', path: 'items')
class Item {
  final int id;

  @Field(views: {'detail'})
  final String secret;

  @Field(views: {'list'})
  final String name;

  @Field(views: {'list', 'detail'})
  final String? note;

  @Field(views: {'list'})
  final int count;

  @Field(views: {'list'})
  final int extra;

  Item({required this.id, required this.secret, required this.name,
      this.note, required this.count, required this.extra});
}
''';

const _searchSortSource = r'''
import 'package:prefab_flutter/prefab_flutter.dart';

@View(title: 'Product', path: 'products')
class Product {
  final int id;

  @Field(label: 'Name', searchable: true, sortable: true)
  final String name;

  @Field(label: 'Unit price', sortable: true)
  final double price;

  Product({required this.id, required this.name, required this.price});
}
''';

const _unpagedSource = r'''
import 'package:prefab_flutter/prefab_flutter.dart';

@View(title: 'Product', path: 'products', paged: false)
class Product {
  final int id;

  @Field(label: 'Name')
  final String name;

  Product({required this.id, required this.name});
}
''';

const _parentSearchSource = r'''
import 'package:prefab_flutter/prefab_flutter.dart';

@View(title: 'Post', path: 'posts')
class Post {
  final int id;
  @Field()
  final String title;
  Post({required this.id, required this.title});
}

@View(title: 'Comment', path: 'comments')
class Comment {
  final int id;

  @Parent(Post)
  @Field(hidden: true)
  final int postId;

  @Field(searchable: true, sortable: true)
  final String content;

  Comment({required this.id, required this.postId, required this.content});
}
''';

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
  group('ListScreenGenerator', () {
    test('PF-16 — fills title, subtitle and trailing from the list view',
        () async {
      await testBuilder(
        listScreenBuilder(BuilderOptions.empty),
        _assets('a', 'lib/item.dart', _viewsSource),
        outputs: {
          'a|lib/item.list_screen.dart': decodedMatches(
            allOf(
              contains('title: Text(item.name.toString())'),
              contains("subtitle: Text(item.note?.toString() ?? '\u2014')"),
              contains('trailing: Text(item.count.toString())'),
              isNot(contains('item.secret')),
              isNot(contains('item.extra')),
            ),
          ),
        },
      );
    });

    test('PF-16 — without views only the title slot is filled', () async {
      await testBuilder(
        listScreenBuilder(BuilderOptions.empty),
        _assets('a', 'lib/product.dart', _productSource),
        outputs: {
          'a|lib/product.list_screen.dart': decodedMatches(
            allOf(
              contains('title: Text(product.name.toString())'),
              isNot(contains('subtitle:')),
              isNot(contains('trailing:')),
            ),
          ),
        },
      );
    });

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

    test(
      'non-parent screen watches the list provider without family arg',
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
      },
    );

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
          'a|lib/product.list_screen.dart': decodedMatches(
            allOf(
              contains("import 'package:material_ui/material_ui.dart'"),
              contains(
                "import 'package:flutter_riverpod/flutter_riverpod.dart'",
              ),
              contains("import 'package:go_router/go_router.dart'"),
            ),
          ),
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
                'const CommentListScreen({super.key, required this.postId})',
              ),
            ),
          },
        );
      },
    );

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
      },
    );

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
      },
    );

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
      },
    );

    // PF-26 — create entry point

    const editableProduct = r'''
import 'package:prefab_flutter/prefab_flutter.dart';

@View(title: 'Product', path: 'products')
@Create()
@Update()
class Product {
  final int id;

  @Field(label: 'Name')
  final String name;

  Product({required this.id, required this.name});
}
''';

    test(
      'PF-26 AC#1 FAB pushes the create route and reloads the list',
      () async {
        await testBuilder(
          listScreenBuilder(BuilderOptions.empty),
          _assets('a', 'lib/product.dart', editableProduct),
          outputs: {
            'a|lib/product.list_screen.dart': decodedMatches(
              allOf(
                contains('FloatingActionButton('),
                contains("await context.push('/products/create');"),
                contains('ref.invalidate(productsProvider);'),
              ),
            ),
          },
        );
      },
    );

    test(
      'PF-26 AC#2 nested entity FAB pushes the nested create route',
      () async {
        await testBuilder(
          listScreenBuilder(BuilderOptions.empty),
          _assets('a', 'lib/post.dart', _parentChildSource),
          outputs: {
            'a|lib/post.list_screen.dart': decodedMatches(
              allOf(
                contains(
                  r"await context.push('/posts/$postId/comments/create');",
                ),
                contains('ref.invalidate(commentsProvider(postId));'),
              ),
            ),
          },
        );
      },
    );

    test('PF-26 AC#4 list shows an empty state message', () async {
      await testBuilder(
        listScreenBuilder(BuilderOptions.empty),
        _assets('a', 'lib/product.dart', _productSource),
        outputs: {
          'a|lib/product.list_screen.dart': decodedMatches(
            contains('prefabTheme.emptyBuilder(context)'),
          ),
        },
      );
    });

    test('PF-26 AC#5 no FAB when the entity has no @Update', () async {
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

  group('PF-13 search, sort and pagination', () {
    Future<void> expectScreen(String source, Matcher matcher,
        {String file = 'product'}) {
      return testBuilder(
        listScreenBuilder(BuilderOptions.empty),
        _assets('a', 'lib/$file.dart', source),
        outputs: {'a|lib/$file.list_screen.dart': decodedMatches(matcher)},
      );
    }

    test('AC#3 searchable field adds a PrefabSearchBar', () async {
      await expectScreen(
        _searchSortSource,
        allOf(
          contains('PrefabSearchBar('),
          contains('onChanged: notifier.setSearch'),
          contains('initialValue: notifier.search'),
          contains(
              "import 'package:prefab_flutter_widgets/prefab_flutter_widgets.dart'"),
        ),
      );
    });

    test('AC#3 without searchable fields there is no search bar', () async {
      await expectScreen(_productSource, isNot(contains('PrefabSearchBar')));
    });

    test('AC#4 sortable fields are listed in a PrefabSortMenu', () async {
      await expectScreen(
        _searchSortSource,
        allOf(
          contains('PrefabSortMenu<Product>('),
          contains("id: 'name'"),
          contains("id: '-name'"),
          contains("id: 'price'"),
          contains("label: 'Unit price ↓'"),
          contains('notifier.setSort('),
        ),
      );
    });

    test('AC#4 without sortable fields there is no sort menu', () async {
      await expectScreen(_productSource, isNot(contains('PrefabSortMenu')));
    });

    test('AC#5 paged list has a PrefabPaginationBar footer', () async {
      await expectScreen(
        _productSource,
        allOf(
          contains('PrefabPaginationBar.controlled('),
          contains('onPageChanged: notifier.goToPage'),
          contains('.totalPages'),
          contains('page.items'),
        ),
      );
    });

    test('AC#5 @View(paged: false) has no pagination bar', () async {
      await expectScreen(
        _unpagedSource,
        allOf(
          isNot(contains('PrefabPaginationBar')),
          contains('page.items'),
        ),
      );
    });

    test('@Parent list screen drives the family notifier', () async {
      await expectScreen(
        _parentSearchSource,
        allOf(
          contains('ref.read(commentsProvider(postId).notifier)'),
          contains('PrefabSearchBar('),
          contains('PrefabSortMenu<Comment>('),
        ),
        file: 'post',
      );
    });
  });
}
