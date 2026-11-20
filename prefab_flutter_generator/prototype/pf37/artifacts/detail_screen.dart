// PF-37 prototype - not part of the published generator.

import '../core/artifact.dart';
import '../core/code.dart';
import '../core/entity_context.dart';
import '../core/extension_point.dart';

/// `{Entity}DetailScreen`: the template owns the skeleton (constructor,
/// provider watch, Scaffold, the field list); features fill the extension
/// points.
class DetailScreenArtifact extends Artifact {
  DetailScreenArtifact(this.entity);

  final EntityContext entity;

  /// `IconButton`s in `AppBar.actions`. The `actions:` list is only emitted
  /// when at least one feature contributes.
  final appBarActions = ExtensionPoint('detailScreen.appBarActions');

  /// The `bottom:` argument of the AppBar (one contribution at most).
  final appBarBottom =
      ExtensionPoint('detailScreen.appBarBottom', maxContributions: 1);

  @override
  ArtifactId get id =>
      ArtifactId(ArtifactKind.detailScreen, entity.manifest.entityName);

  @override
  String get primaryName => '${entity.manifest.entityName}DetailScreen';

  @override
  Code emit() {
    final m = entity.manifest;
    final e = m.entityNameLower;
    final ctorParams = [
      'super.key',
      'required this.id',
      for (final a in m.ancestors) 'required this.${a.paramName}',
    ].join(', ');
    final key = m.detailKeyExpr('id', (a) => a.paramName);
    final detailFields = m.fieldsForView('detail');
    final fields = detailFields.isEmpty ? m.visibleFields : detailFields;

    final text = lines([
      'class $primaryName extends ConsumerWidget {',
      '  final ${m.idType} id;',
      for (final a in m.ancestors) '  final ${a.idType} ${a.paramName};',
      '',
      '  const $primaryName({$ctorParams});',
      '',
      '  @override',
      '  Widget build(BuildContext context, WidgetRef ref) {',
      '    final ${e}Async = ref.watch(${e}DetailProvider($key));',
      '    return Scaffold(',
      '      appBar: AppBar(',
      "        title: const Text('${m.title}'),",
      if (!appBarBottom.isEmpty) appBarBottom.render(8),
      if (!appBarActions.isEmpty) ...[
        '        actions: [',
        appBarActions.render(10),
        '        ],',
      ],
      '      ),',
      '      body: ${e}Async.when(',
      '        data: ($e) => ListView(',
      '          padding: const EdgeInsets.all(16),',
      '          children: [',
      for (final f in fields) ...[
        '            ListTile(',
        "              title: const Text('${f.label}'),",
        f.isNullable
            ? "              subtitle: Text($e.${f.name}?.toString() ?? '—'),"
            : '              subtitle: Text($e.${f.name}.toString()),',
        '            ),',
      ],
      '          ],',
      '        ),',
      '        loading: () => const Center(child: CircularProgressIndicator()),',
      "        error: (error, stackTrace) => Center(child: Text('Error: \$error')),",
      '      ),',
      '    );',
      '  }',
      '}',
    ]);
    return Code(text, imports: {
      Libs.materialUi,
      Libs.riverpod,
      entity.sourceFileName,
      ...appBarActions.imports,
      ...appBarBottom.imports,
    });
  }
}
