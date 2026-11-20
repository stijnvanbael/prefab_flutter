import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:prefab_flutter_generator/builder.dart';
import 'package:prefab_flutter_generator/src/core/extension_point.dart';
import 'package:prefab_flutter_generator/src/core/field_registries.dart';
import 'package:prefab_flutter_generator/src/features/nullable_fields/nullable_fields_feature.dart';
import 'package:prefab_flutter_generator/src/manifest/field_manifest.dart';
import 'package:test/test.dart';

import 'support/prefab_sources.dart';

const _source = r'''
import 'package:prefab_flutter/prefab_flutter.dart';

@Entity(title: 'Note', path: 'notes')
class Note {
  final int id;

  @Field(label: 'Remark')
  final String? remark;

  @Field(label: 'Title')
  final String title;

  Note({required this.id, required this.title, this.remark});
}
''';

void main() {
  group('PF-61 nullable fields', () {
    test('fieldValue shows an em dash only for nullable fields', () {
      final point = ValuePoint<FieldValue>('x.fieldValue')
        ..add('nullable_fields', NullableFieldsFeature.fieldValue, order: 10);
      final nullable = FieldManifest(
          name: 'remark',
          dartType: 'String',
          label: 'Remark',
          isParent: false,
          isNullable: true);
      final plain = FieldManifest(
          name: 'title',
          dartType: 'String',
          label: 'Title',
          isParent: false);
      expect(fieldValueText(point, nullable, 'note'),
          "note.remark?.toString() ?? '—'");
      expect(fieldValueText(point, plain, 'note'), 'note.title.toString()');
    });

    test('without the feature a nullable field uses the default display', () {
      final nullable = FieldManifest(
          name: 'remark',
          dartType: 'String',
          label: 'Remark',
          isParent: false,
          isNullable: true);
      expect(fieldValueText(ValuePoint<FieldValue>('x'), nullable, 'note'),
          'note.remark.toString()');
    });

    for (final (builder, ext) in [
      (detailScreenBuilder, 'detail_screen'),
      (listScreenBuilder, 'list_screen'),
    ]) {
      test('$ext shows nullable values with an em dash', () async {
        await testBuilder(
          builder(BuilderOptions.empty),
          {...prefabSources, 'a|lib/note.dart': _source},
          outputs: {
            'a|lib/note.$ext.dart': decodedMatches(
              contains("note.remark?.toString() ?? '—'"),
            ),
          },
        );
      });
    }
  });
}
