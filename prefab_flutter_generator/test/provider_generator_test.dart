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
@Create()
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
                'class ProductsNotifier extends AutoDisposeAsyncNotifier<PrefabPage<Product>>',
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
              contains('Future<void> updateEntity('),
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
                contains('.family<CommentsNotifier, PrefabPage<Comment>, int>'),
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
              contains(
                  'AutoDisposeFamilyAsyncNotifier<PrefabPage<Comment>, int>'),
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
              matches(RegExp(
                  r'_client\.list\(\s*postId: postId,\s*search: _search')),
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
                  r'updateEntity\(Product product\) async \{\n[^}]*'
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

  group('PF-13 list query state', () {
    const unpaged = r'''
import 'package:prefab_flutter/prefab_flutter.dart';

@View(title: 'Product', path: 'products', paged: false)
class Product {
  final int id;
  @Field()
  final String name;
  Product({required this.id, required this.name});
}
''';

    Future<void> expectProvider(String path, String source, Matcher m) =>
        testBuilder(
          providerBuilder(BuilderOptions.empty),
          _assets('a', 'lib/$path.dart', source),
          outputs: {'a|lib/$path.provider.dart': decodedMatches(m)},
        );

    test('AC#6 notifier holds search, sort, direction and page', () async {
      await expectProvider(
        'product',
        _productSource,
        allOf(
          contains('String _search'),
          contains('String? _sort'),
          contains('bool _descending'),
          contains('int _page'),
          contains('void setSearch(String query)'),
          contains('Future<void> setSort(String? field'),
          contains('Future<void> goToPage(int page)'),
        ),
      );
    });

    test('AC#6 search input is debounced and resets the page', () async {
      await expectProvider(
        'product',
        _productSource,
        allOf(
          contains("import 'dart:async'"),
          contains('Timer(const Duration(milliseconds: 300)'),
          contains('_page = 0'),
          contains('_searchDebounce?.cancel()'),
        ),
      );
    });

    test('AC#6 every query change reloads through _load', () async {
      await expectProvider(
        'product',
        _productSource,
        allOf(
          matches(RegExp(r'setSort\([^)]*\)\s*\{[^}]*return _load\(\);')),
          matches(RegExp(r'goToPage\(int page\)\s*\{[^}]*return _load\(\);')),
        ),
      );
    });

    test('API client provider passes the list adapter', () async {
      await expectProvider(
        'product',
        _productSource,
        contains('ref.watch(prefabListAdapterProvider)'),
      );
    });

    test('@Parent family notifier keeps the query state too', () async {
      await expectProvider(
        'post',
        _parentChildSource,
        allOf(
          contains('void setSearch(String query)'),
          contains('AutoDisposeFamilyAsyncNotifier<PrefabPage<Comment>, int>'),
        ),
      );
    });

    test('@View(paged: false) has no paging methods', () async {
      await expectProvider(
        'product',
        unpaged,
        allOf(
          contains('void setSearch'),
          isNot(contains('goToPage')),
          isNot(contains('page: _page')),
        ),
      );
    });
  });
}
