import '../manifest/entity_manifest.dart';
import '../manifest/entity_paths.dart';

/// Source of the `bottom:` argument of an AppBar showing the breadcrumb row
/// for [manifest] (which must have [EntityManifest.hasBreadcrumbs]).
///
/// Each ancestor is a tappable step labelled with the first visible field of
/// the ancestor, read from the ancestor's detail provider; the last step is
/// the entity's own title.
String breadcrumbBottom(EntityManifest manifest, String indent) {
  final lines = <String>[
    'bottom: PrefabBreadcrumbBar(',
    '  items: [',
  ];
  for (var i = 0; i < manifest.ancestors.length; i++) {
    final a = manifest.ancestors[i];
    // Detail provider key: (id, ids of the ancestors above it).
    final key = i == 0
        ? a.paramName
        : '(${[
            a.paramName,
            ...manifest.ancestors.take(i).map((p) => p.paramName),
          ].join(', ')})';
    final access = a.labelIsNullable
        ? '?.${a.labelFieldName}?.toString()'
        : '?.${a.labelFieldName}.toString()';
    final label = "ref.watch(${a.entityNameLower}DetailProvider($key))"
        ".valueOrNull$access ?? '…'";
    lines
      ..add('    PrefabBreadcrumb(')
      ..add('      label: $label,')
      ..add("      onTap: () => context.go('${EntityPaths.ancestorPath(manifest, i)}'),")
      ..add('    ),');
  }
  lines
    ..add("    const PrefabBreadcrumb(label: '${_escape(manifest.title)}'),")
    ..add('  ],')
    ..add('),');
  return lines.map((l) => '$indent$l').join('\n');
}

/// Import URIs for the generated code of ancestors declared in other
/// libraries (their detail providers live in the other `.prefab.dart`).
Set<String> ancestorImports(Iterable<EntityManifest> manifests) => {
      for (final m in manifests)
        if (m.hasBreadcrumbs)
          for (final a in m.ancestors)
            if (!a.inSameLibrary)
              a.libraryUri.replaceFirst(RegExp(r'\.dart$'), '.prefab.dart'),
    };

String _escape(String value) => value
    .replaceAll(r'\', r'\\')
    .replaceAll("'", r"\'")
    .replaceAll(r'$', r'\$');
