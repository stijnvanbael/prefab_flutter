import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:prefab_flutter_generator/builder.dart';
import 'package:test/test.dart';
import 'support/prefab_sources.dart';

// PF-11: the generated form screens build the entity and call the provider.

const _itemSource = r"""
import 'package:prefab_flutter/prefab_flutter.dart';

enum Color { red, green }

@Entity(title: 'Item', path: 'items')
@Create()
@Update()
class Item {
  final int? id;
  @Field(label: 'Name')
  final String name;
  @Field(label: 'Nickname')
  final String? nickname;
  @Field(label: 'Count')
  final int count;
  @Field(label: 'Age')
  final int? age;
  @Field(label: 'Price')
  final double price;
  @Field(label: 'Active')
  final bool active;
  @Field(label: 'Born')
  final DateTime born;
  @Field(label: 'Color')
  final Color color;
  @Field(label: 'Secret', on: {})
  final String? secret;
  final String? untracked;

  Item({
    this.id,
    required this.name,
    this.nickname,
    required this.count,
    this.age,
    required this.price,
    required this.active,
    required this.born,
    required this.color,
    this.secret,
    this.untracked,
  });
}
""";

const _nestedSource = r"""
import 'package:prefab_flutter/prefab_flutter.dart';

@Entity(title: 'Post', path: 'posts')
@Create()
@Update()
class Post {
  final int? id;
  @Field(label: 'Title')
  final String title;
  Post({this.id, required this.title});
}

@Entity(title: 'Comment', path: 'comments')
@Create()
@Update()
class Comment {
  final int? id;
  @Parent(Post)
  @Field(on: {})
  final int postId;
  @Field(label: 'Content')
  final String content;
  Comment({this.id, required this.postId, required this.content});
}
""";

String _bad(String ctor, String fields) => """
import 'package:prefab_flutter/prefab_flutter.dart';

@Entity(title: 'Item', path: 'items')
@Create()
@Update()
class Item {
  final int id;
  @Field(label: 'Name')
  final String name;
  $fields
  $ctor
}
""";

Map<String, Object> _assets(String source) => {
      ...Map<String, Object>.from(prefabSources),
      'a|lib/item.dart': source,
    };

String _flat(String s) => s.replaceAll(RegExp(r'\s+'), '');

/// Matches decoded output containing every part, ignoring whitespace.
Matcher _hasAll(List<String> parts) => decodedMatches(predicate<String>((s) {
      final flat = _flat(s);
      return parts.every((p) => flat.contains(_flat(p)));
    }, 'contains all parts'));

void main() {
  group('PF-11 form save', () {
    test('create screen builds the entity and calls create()', () async {
      await testBuilder(
        formScreenBuilder(BuilderOptions.empty),
        _assets(_itemSource),
        outputs: {
          'a|lib/item.form_screen.dart': decodedMatches(predicate<String>((s) {
            final create = _flat(s.substring(
                s.indexOf('class _ItemCreateScreenState'),
                s.indexOf('class ItemEditScreen')));
            return create.contains(_flat('Future<void> _save() async')) &&
                create.contains(_flat('final entity = Item(')) &&
                // id and untracked/hidden fields are omitted on create
                !create.contains(_flat('id:')) &&
                !create.contains(_flat('secret:')) &&
                !create.contains(_flat('untracked:')) &&
                create.contains(_flat('name: _nameController.text,')) &&
                create.contains(_flat(
                    'nickname: _nicknameController.text.isEmpty ? null : _nicknameController.text,')) &&
                create.contains(
                    _flat('count: int.parse(_countController.text),')) &&
                create.contains(_flat(
                    'age: _ageController.text.isEmpty ? null : int.parse(_ageController.text),')) &&
                create.contains(
                    _flat('price: double.parse(_priceController.text),')) &&
                create.contains(_flat('active: _activeValue,')) &&
                create.contains(_flat('born: _bornValue!,')) &&
                create.contains(_flat('color: _colorValue!,')) &&
                create.contains(_flat(
                    'await ref.read(itemsProvider.notifier).create(entity);')) &&
                create.indexOf(_flat('.create(entity)')) <
                    create.indexOf(_flat('context.pop()'));
          }, 'create screen saves via create() before popping')),
        },
      );
    });

    test('edit screen preserves id and non-form fields and calls update()',
        () async {
      await testBuilder(
        formScreenBuilder(BuilderOptions.empty),
        _assets(_itemSource),
        outputs: {
          'a|lib/item.form_screen.dart': decodedMatches(predicate<String>((s) {
            final edit =
                _flat(s.substring(s.indexOf('class _ItemEditScreenState')));
            return edit.contains(_flat('Item? _item;')) &&
                edit.contains(_flat('_item = item;')) &&
                edit.contains(_flat('id: widget.id,')) &&
                edit.contains(_flat('secret: _item!.secret,')) &&
                edit.contains(_flat('untracked: _item!.untracked,')) &&
                edit.contains(_flat(
                    'await ref.read(itemsProvider.notifier).updateEntity(entity);')) &&
                edit.indexOf(_flat('.updateEntity(entity)')) <
                    edit.indexOf(_flat('context.pop()'));
          }, 'edit screen saves via update()')),
        },
      );
    });

    test('save shows progress, disables the button and reports errors',
        () async {
      await testBuilder(
        formScreenBuilder(BuilderOptions.empty),
        _assets(_itemSource),
        outputs: {
          'a|lib/item.form_screen.dart': _hasAll([
            'bool _saving = false;',
            '_saving ? null : _save,',
            'prefabTheme.saveButtonBuilder(',
            'setState(() => _saving = true);',
            'setState(() => _saving = false);',
            '_formErrors.setError(',
            'ref.read(prefabBackendProvider).parseError(e)',
            'ref.listenManual(itemsProvider',
            'subscription.close();',
            "if (value == null || value.isEmpty) return 'Required';",
            'int.tryParse(value) == null',
            'double.tryParse(value) == null',
          ]),
        },
      );
    });

    test('nested entity passes the parent id and uses the parent family',
        () async {
      await testBuilder(
        formScreenBuilder(BuilderOptions.empty),
        {
          ...Map<String, Object>.from(prefabSources),
          'a|lib/item.dart': _nestedSource,
        },
        outputs: {
          'a|lib/item.form_screen.dart': _hasAll([
            'postId: widget.postId,',
            'ref.read(commentsProvider(widget.postId).notifier).create(entity)',
            'ref.read(commentsProvider(widget.postId).notifier).updateEntity(entity)',
          ]),
        },
      );
    });

    Future<String> failure(String source) async {
      final logs = <String>[];
      Object? error;
      try {
        await testBuilder(
          formScreenBuilder(BuilderOptions.empty),
          _assets(source),
          outputs: {},
          onLog: (r) => logs.add(r.message),
        );
      } catch (e) {
        error = e;
      }
      return '$error\n${logs.join('\n')}';
    }

    test('required id without a value source is a build-time error', () async {
      final message = await failure(
          _bad('Item({required this.id, required this.name});', ''));
      expect(message, contains('constructor parameter "id" is required'));
    });

    test('required field outside the form without a value source is an error', () async {
      final message = await failure(_bad(
              'Item({this.id, required this.name, required this.owner});',
              'final String owner;')
          .replaceAll('final int id;', 'final int? id;'));
      expect(message, contains('"owner"'));
    });

    test('unsupported field type is an error naming the field', () async {
      final message = await failure(_bad(
              'Item({this.id, required this.name, required this.tags});',
              "@Field(label: 'Tags') final List<String> tags;")
          .replaceAll('final int id;', 'final int? id;'));
      expect(message, contains('"tags"'));
    });
  });
}
