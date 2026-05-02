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
@Update()
@Delete()
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

    test('generates a list StateNotifier for an entity', () async {
      await testBuilder(
        providerBuilder(BuilderOptions.empty),
        _assets('a', 'lib/product.dart', _productSource),
        outputs: {
          'a|lib/product.provider.dart': decodedMatches(
            contains('class ProductsNotifier'),
          ),
        },
      );
    });

    test('list notifier has load, create, update and delete methods', () async {
      await testBuilder(
        providerBuilder(BuilderOptions.empty),
        _assets('a', 'lib/product.dart', _productSource),
        outputs: {
          'a|lib/product.provider.dart': decodedMatches(allOf(
            contains('_load()'),
            contains('Future<void> create('),
            contains('Future<void> update('),
            contains('Future<void> delete('),
          )),
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

    // AC#3 — @Parent: parent ID threaded through all operations

    test(
        'AC#3 @Parent — detail provider is keyed on (Object, parentType) record',
        () async {
      await testBuilder(
        providerBuilder(BuilderOptions.empty),
        _assets('a', 'lib/post.dart', _parentChildSource),
        outputs: {
          'a|lib/post.provider.dart': decodedMatches(
            contains('FutureProvider.autoDispose'
                '.family<Comment, (Object, int)>'),
          ),
        },
      );
    });

    test(
        'AC#3 @Parent — detail provider passes both id and parentId to API client',
        () async {
      await testBuilder(
        providerBuilder(BuilderOptions.empty),
        _assets('a', 'lib/post.dart', _parentChildSource),
        outputs: {
          'a|lib/post.provider.dart': decodedMatches(allOf(
            contains('args.\$1'),
            contains('postId: args.\$2'),
          )),
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
            contains('StateNotifierProvider.autoDispose'
                '.family<CommentsNotifier, AsyncValue<List<Comment>>, int>'),
          ),
        },
      );
    });

    test(
        'AC#3 @Parent — StateNotifier accepts and stores the parent ID',
        () async {
      await testBuilder(
        providerBuilder(BuilderOptions.empty),
        _assets('a', 'lib/post.dart', _parentChildSource),
        outputs: {
          'a|lib/post.provider.dart': decodedMatches(allOf(
            contains('class CommentsNotifier'),
            contains('final int postId'),
          )),
        },
      );
    });

    test(
        'AC#3 @Parent — StateNotifier _load passes parentId to API client',
        () async {
      await testBuilder(
        providerBuilder(BuilderOptions.empty),
        _assets('a', 'lib/post.dart', _parentChildSource),
        outputs: {
          'a|lib/post.provider.dart': decodedMatches(
            contains('_client.list(postId: postId)'),
          ),
        },
      );
    });

    test(
        'AC#3 @Parent — create passes parentId to API client', () async {
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

    test(
        'AC#3 @Parent — update passes parentId to API client', () async {
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

    test(
        'AC#3 @Parent — delete passes parentId to API client', () async {
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
            contains('FutureProvider.autoDispose.family<Post, Object>'),
          ),
        },
      );
    });
  });
}
