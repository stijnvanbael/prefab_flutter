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
export 'src/annotations/field.dart';
export 'src/annotations/parent.dart';
export 'src/enums/field_widget.dart';
export 'src/enums/validator.dart';
''',
  'prefab_flutter|lib/src/annotations/view.dart': r'''
class View {
  final String title;
  final String path;
  final bool paged;
  const View({required this.title, required this.path, this.paged = true});
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
  'prefab_flutter|lib/src/annotations/field.dart': r'''
import 'package:prefab_flutter/src/enums/field_widget.dart';
import 'package:prefab_flutter/src/enums/validator.dart';
class FormOptions {
  final FieldWidget widget;
  final List<Validator> validators;
  const FormOptions({
    this.widget = FieldWidget.auto,
    this.validators = const [],
  });
}
class Field {
  final String? label;
  final bool hidden;
  final bool searchable;
  final bool sortable;
  final FormOptions form;
  final Set<String>? views;
  const Field({
    this.label,
    this.hidden = false,
    this.views,
    this.searchable = false,
    this.sortable = false,
    this.form = const FormOptions(),
  });
}
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
/// Validation rules that the form-screen generator wires into form fields.
///
/// Parameterless rules are available as static constants
/// (`Validator.required`, `Validator.email`, ...); rules that carry a value are
/// created with the const factories (`Validator.min(0)`,
/// `Validator.pattern(r'^[A-Z]+$')`).
///
/// Every rule accepts an optional custom error [message]. For the parameterless
/// rules use the subclass constructor, e.g. `EmailValidator(message: 'Bad')`.
sealed class Validator {
  /// Custom error message shown instead of the default one.
  final String? message;

  const Validator({this.message});

  /// Field must not be empty (or, on dropdowns, must have a selection).
  static const Validator required = RequiredValidator();

  /// Field value must be a valid e-mail address.
  static const Validator email = EmailValidator();

  /// Field value must be a parseable absolute URL.
  static const Validator url = UrlValidator();

  /// Field value must be a number greater than zero.
  static const Validator positive = PositiveValidator();

  /// Alias of [positive], kept for backwards compatibility.
  static const Validator positiveNumber = PositiveValidator();

  /// Field value must be a number greater than or equal to zero.
  static const Validator nonNegative = NonNegativeValidator();

  /// Field value must be a number greater than or equal to [value].
  const factory Validator.min(num value, {String? message}) = MinValidator;

  /// Field value must be a number less than or equal to [value].
  const factory Validator.max(num value, {String? message}) = MaxValidator;

  /// Field value must be at least [length] characters long.
  const factory Validator.minLength(int length, {String? message}) =
      MinLengthValidator;

  /// Field value must be at most [length] characters long.
  const factory Validator.maxLength(int length, {String? message}) =
      MaxLengthValidator;

  /// Field value must match the regular expression [regex].
  const factory Validator.pattern(String regex, {String? message}) =
      PatternValidator;
}

/// See [Validator.required].
final class RequiredValidator extends Validator {
  const RequiredValidator({super.message});
}

/// See [Validator.email].
final class EmailValidator extends Validator {
  const EmailValidator({super.message});
}

/// See [Validator.url].
final class UrlValidator extends Validator {
  const UrlValidator({super.message});
}

/// See [Validator.positive].
final class PositiveValidator extends Validator {
  const PositiveValidator({super.message});
}

/// See [Validator.nonNegative].
final class NonNegativeValidator extends Validator {
  const NonNegativeValidator({super.message});
}

/// See [Validator.min].
final class MinValidator extends Validator {
  final num value;
  const MinValidator(this.value, {super.message});
}

/// See [Validator.max].
final class MaxValidator extends Validator {
  final num value;
  const MaxValidator(this.value, {super.message});
}

/// See [Validator.minLength].
final class MinLengthValidator extends Validator {
  final int length;
  const MinLengthValidator(this.length, {super.message});
}

/// See [Validator.maxLength].
final class MaxLengthValidator extends Validator {
  final int length;
  const MaxLengthValidator(this.length, {super.message});
}

/// See [Validator.pattern].
final class PatternValidator extends Validator {
  final String regex;
  const PatternValidator(this.regex, {super.message});
}
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

  @Field(label: 'Name')
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

  @Field(label: 'Title')
  final String title;

  Post({required this.id, required this.title});
}

@View(title: 'Comment', path: 'comments')
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
      ...Map<String, Object>.from(_prefabSources),
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
            contains("Text('No items found')"),
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
