import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:prefab_flutter_generator/builder.dart';
import 'package:prefab_flutter_generator/src/features/actions/action_scanner.dart';
import 'package:test/test.dart';

import 'support/prefab_sources.dart';

const _source = '''
import 'package:prefab_flutter/prefab_flutter.dart';

@Entity()
@Create()
@Update()
class Product {
  @Id()
  late final int id;
  @Field()
  final String name;
  @Field(on: {Place.item, Place.detail})
  final String? code;
  @Field(on: {})
  final String? secret;
  Product({required this.name, this.code, this.secret});
}
''';

Future<String> _failure(Builder builder, String source) async {
  final logs = <String>[];
  Object? error;
  try {
    await testBuilder(
      builder,
      {...Map<String, Object>.from(prefabSources), 'a|lib/product.dart': source},
      outputs: {},
      onLog: (r) => logs.add(r.message),
    );
  } catch (e) {
    error = e;
  }
  return '$error\n${logs.join('\n')}';
}

void main() {
  test('PF-73 - a field without Place.form is not in the form', () async {
    await testBuilder(
      formScreenBuilder(BuilderOptions.empty),
      {...prefabSources, 'a|lib/product.dart': _source},
      outputs: {
        'a|lib/product.form_screen.dart': decodedMatches(allOf(
          contains("labelText: 'Name'"),
          isNot(contains("labelText: 'Code'")),
          isNot(contains("labelText: 'Secret'")),
          // Edit keeps the stored values of fields outside the form.
          contains('code: _item!.code'),
          contains('secret: _item!.secret'),
        )),
      },
      onLog: (_) {},
    );
  });

  test('PF-73 - a field with on: {} is shown nowhere', () async {
    await testBuilder(
      detailScreenBuilder(BuilderOptions.empty),
      {...prefabSources, 'a|lib/product.dart': _source},
      outputs: {
        'a|lib/product.detail_screen.dart': decodedMatches(allOf(
          contains('product.code'),
          isNot(contains('product.secret')),
        )),
      },
      onLog: (_) {},
    );
  });

  test('PF-73 - Place.list on a field fails the build', () async {
    final message = await _failure(
      listScreenBuilder(BuilderOptions.empty),
      '''
import 'package:prefab_flutter/prefab_flutter.dart';

@Entity()
class Product {
  @Id()
  final int id;
  @Field(on: {Place.list})
  final String name;
  Product(this.id, this.name);
}
''',
    );
    expect(message, contains('Use Place.item'));
  });

  test('PF-73 - Place.form on an action fails the build', () {
    expect(
      () => scanActions('''
import 'package:prefab_flutter/prefab_flutter.dart';

@EntityAction(Product, label: 'X', on: {Place.form})
void a(BuildContext context, WidgetRef ref, Product product) {}
''', 'package:a/actions.dart'),
      throwsA(isA<ActionException>().having(
          (e) => e.message, 'message', contains('Place.form is for fields'))),
    );
  });
}
