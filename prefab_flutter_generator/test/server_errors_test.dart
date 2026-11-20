import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:prefab_flutter_generator/builder.dart';
import 'package:test/test.dart';

import 'support/prefab_sources.dart';

const _jsonAnnotation = r'''
enum FieldRename { none, kebab, snake, pascal, screamingSnake }
class JsonSerializable {
  final FieldRename? fieldRename;
  const JsonSerializable({this.fieldRename});
}
class JsonKey {
  final String? name;
  const JsonKey({this.name});
}
''';

const _source = '''
import 'package:json_annotation/json_annotation.dart';
import 'package:prefab_flutter/prefab_flutter.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
@Entity(title: 'Product', path: 'products')
@Create()
@Update()
class Product {
  final int? id;
  @Field()
  final String name;
  @Field()
  final double unitPrice;
  @JsonKey(name: 'created')
  @Field()
  final String createdAt;

  Product({this.id, required this.name, required this.unitPrice,
      required this.createdAt});
}
''';

Map<String, Object> _assets() => {
      ...Map<String, Object>.from(prefabSources),
      'json_annotation|lib/json_annotation.dart': _jsonAnnotation,
      'a|lib/product.dart': _source,
    };

String _flat(String s) => s.replaceAll(RegExp(r'\s+'), '');

void main() {
  group('PF-51 server errors', () {
    test('form fields are keyed by their JSON names', () async {
      await testBuilder(
        formScreenBuilder(BuilderOptions.empty),
        _assets(),
        outputs: {
          'a|lib/product.form_screen.dart': decodedMatches(predicate<String>(
            (s) {
              final flat = _flat(s);
              return flat.contains(_flat("field: 'unit_price',")) &&
                  flat.contains(_flat("field: 'created',")) &&
                  flat.contains(_flat("field: 'name',")) &&
                  !flat.contains(_flat("field: 'unitPrice',")) &&
                  flat.contains(
                      _flat("const {'name', 'unit_price', 'created'},"));
            },
            'fields use the JSON names',
          )),
        },
      );
    });

    test('forms show errors above the fields and clear them on edit',
        () async {
      await testBuilder(
        formScreenBuilder(BuilderOptions.empty),
        _assets(),
        outputs: {
          'a|lib/product.form_screen.dart': decodedMatches(predicate<String>(
            (s) {
              final flat = _flat(s);
              return flat.contains('PrefabFormErrorBanner(errors:_formErrors)') &&
                  flat.contains('onChanged:_formErrors.clearEdited') &&
                  flat.contains('_formErrors.clear();') &&
                  flat.contains(_flat(
                      '_formErrors.setError(ref.read(prefabBackendProvider).parseError(e)')) &&
                  !s.contains('showSnackBar');
            },
            'banner, clear-on-edit and parsed errors',
          )),
        },
      );
    });

    test('the edit screen shows a not-found state on 404', () async {
      await testBuilder(
        formScreenBuilder(BuilderOptions.empty),
        _assets(),
        outputs: {
          'a|lib/product.form_screen.dart': decodedMatches(predicate<String>(
            (s) => _flat(s).contains(_flat(
                "prefabTheme.notFoundBuilder(context, () => context.go('/products'))")),
            'not-found state with a way back to /products',
          )),
        },
      );
    });

    test('the detail screen shows a not-found state on 404', () async {
      await testBuilder(
        detailScreenBuilder(BuilderOptions.empty),
        _assets(),
        outputs: {
          'a|lib/product.detail_screen.dart': decodedMatches(predicate<String>(
            (s) =>
                _flat(s).contains(_flat('parseError(error).isNotFound')) &&
                _flat(s).contains(_flat(
                    "notFoundBuilder(context, () => context.go('/products'))")),
            'not-found state with a way back to /products',
          )),
        },
      );
    });
  });
}
