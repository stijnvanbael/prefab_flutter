import 'package:analyzer/dart/element/element.dart';
import 'package:prefab_flutter/prefab_flutter.dart';
import 'package:prefab_flutter_generator/src/core/artifact.dart';
import 'package:prefab_flutter_generator/src/core/code.dart';
import 'package:prefab_flutter_generator/src/core/entity_context.dart';
import 'package:prefab_flutter_generator/src/core/extension_point.dart';
import 'package:prefab_flutter_generator/src/core/field_registries.dart';
import 'package:prefab_flutter_generator/src/core/library_emitter.dart';
import 'package:prefab_flutter_generator/src/manifest/entity_manifest.dart';
import 'package:prefab_flutter_generator/src/manifest/entity_paths.dart';
import 'package:prefab_flutter_generator/src/manifest/field_manifest.dart';
import 'package:test/test.dart';

/// An artifact that renders fixed text, for testing the core without
/// analyzing sources.
class _FakeArtifact extends Artifact {
  _FakeArtifact(this.kind, this.entityName, this.text, this.imports,
      {this.names = const []});

  final ArtifactKind kind;
  final String entityName;
  final String text;
  final Set<String> imports;
  final List<String> names;

  @override
  ArtifactId get id => ArtifactId(kind, entityName);

  @override
  String get primaryName => '${entityName}Thing';

  @override
  List<String> get declaredNames => [primaryName, ...names];

  @override
  Code emit() => Code(text, imports: imports);
}

// The emitter never reads the entity of an artifact it is not given, so a
// null-ish context is enough: factories below ignore it.
EntityContext _context(String name) => EntityContext(
      manifest: _manifestStub,
      paths: const EntityPaths([]),
      sourceFileName: '$name.dart',
      element: _elementStub,
      libraryManifests: const [],
    );

final EntityManifest _manifestStub = _ManifestStub();
final ClassElement _elementStub = _ElementStub();

class _ManifestStub implements EntityManifest {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

class _ElementStub implements ClassElement {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

LibraryEmitter _emitter({List<PromotedDeclaration> promoted = const []}) =>
    LibraryEmitter(
      artifactFactories: [
        (e) => [
              _FakeArtifact(ArtifactKind.detailScreen, 'Product',
                  'class ProductThing {}', {Libs.materialUi, 'product.dart'}),
            ],
        (e) => [
              _FakeArtifact(ArtifactKind.listScreen, 'Order',
                  'class OrderThing {}', {Libs.goRouter, Libs.materialUi},
                  names: ['OrderState']),
            ],
      ],
      promoted: promoted,
    );

void main() {
  group('LibraryEmitter', () {
    test('emits the artifacts one after another with merged imports', () {
      final out = _emitter().emit([_context('a')], header: '// header\n');
      expect(
        out,
        '''// header

import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'product.dart';

class ProductThing {}

class OrderThing {}
''',
      );
    });

    test('skips an artifact by primary name, imports and re-exports it', () {
      final out = _emitter(promoted: const [
        PromotedDeclaration('ProductThing', 'package:shop/product_thing.dart'),
      ]).emit([_context('a')], header: '// header\n');
      expect(out, isNot(contains('class ProductThing')));
      expect(out, contains('class OrderThing {}'));
      expect(out, contains("import 'package:shop/product_thing.dart';"));
      expect(
          out,
          contains(
              "export 'package:shop/product_thing.dart' show ProductThing;"));
    });

    test('skips an artifact by any name it declares', () {
      final out = _emitter(promoted: const [
        PromotedDeclaration('OrderState', 'package:shop/order_state.dart'),
      ]).emit([_context('a')], header: '// header\n');
      expect(out, isNot(contains('class OrderThing')));
      expect(out, contains('class ProductThing {}'));
    });

    test('imports of a skipped artifact are not collected', () {
      final out = _emitter(promoted: const [
        PromotedDeclaration('OrderThing', 'package:shop/order.dart'),
      ]).emit([_context('a')], header: '// header\n');
      expect(out, isNot(contains('go_router')));
    });

    test('returns an empty string when nothing is generated', () {
      final out = const LibraryEmitter(artifactFactories: [])
          .emit([_context('a')], header: '// header\n');
      expect(out, '');
    });
  });

  group('ExtensionPoint', () {
    test('renders contributions by order, then feature name', () {
      final point = ExtensionPoint('detailScreen.appBarActions')
        ..add('delete', const Code('B,'), order: 20)
        ..add('update', const Code('A,'), order: 10)
        ..add('breadcrumbs', const Code('C,'), order: 20);
      expect(point.render(2), '  A,\n  C,\n  B,');
    });

    test('collects the imports of its contributions', () {
      final point = ExtensionPoint('x')
        ..add('a', const Code('A', imports: {Libs.goRouter}))
        ..add('b', const Code('B', imports: {Libs.widgets}));
      expect(point.imports, {Libs.goRouter, Libs.widgets});
    });

    test('a single-valued point names both features on a conflict', () {
      final point =
          ExtensionPoint('listScreen.appBarBottom', maxContributions: 1)
            ..add('breadcrumbs', const Code('A'));
      expect(
        () => point.add('tabs', const Code('B')),
        throwsA(isA<StateError>().having(
            (e) => e.message,
            'message',
            allOf(contains('tabs'), contains('breadcrumbs'),
                contains('listScreen.appBarBottom')))),
      );
    });
  });

  group('Imports', () {
    test('sorts package imports, a blank line, then other imports', () {
      final imports = Imports()
        ..addAll(['b.dart', 'dart:async', Libs.riverpod, Libs.goRouter]);
      expect(imports.render(), '''
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'b.dart';
import 'dart:async';''');
    });
  });

  group('field registries', () {
    const field = FieldManifest(
      name: 'price',
      label: 'Price',
      hidden: false,
      isParent: false,
      dartType: 'int',
      isNullable: true,
    );

    test('the default field display marks nullable fields with a dash', () {
      expect(fieldDisplays.resolve(field).text(field, 'p'),
          "p.price?.toString() ?? '—'");
    });

    test('FieldEmitters resolve explicit widgets and auto inference', () {
      final emitters = FieldEmitters<_Emitter>(const [
        _Emitter(FieldWidget.toggle, 'bool'),
        _Emitter(FieldWidget.auto, ''),
      ]);
      const flag = FieldManifest(
          name: 'f',
          label: 'F',
          hidden: false,
          isParent: false,
          dartType: 'bool');
      expect(emitters.resolve(flag).widget, FieldWidget.toggle);
      expect(emitters.resolve(field).widget, FieldWidget.auto);
      const explicit = FieldManifest(
          name: 'f',
          label: 'F',
          hidden: false,
          isParent: false,
          dartType: 'String',
          fieldWidget: FieldWidget.toggle);
      expect(emitters.resolve(explicit).widget, FieldWidget.toggle);
    });

    test('ValidatorEmitters fail clearly for an unregistered validator', () {
      expect(() => ValidatorEmitters({}).resolve(const EmailValidator()),
          throwsA(isA<StateError>()));
    });
  });
}

class _Emitter extends FieldEmitter {
  const _Emitter(this.widget, this.type);

  @override
  final FieldWidget widget;
  final String type;

  @override
  bool accepts(FieldManifest field) => type.isEmpty || field.dartType == type;

  @override
  Code formField(FieldManifest field) => const Code('');

  @override
  String valueExpression(FieldManifest field) => '';
}
