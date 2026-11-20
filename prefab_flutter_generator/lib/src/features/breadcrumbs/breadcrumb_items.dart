import '../../manifest/entity_manifest.dart';
import '../../manifest/entity_paths.dart';

/// The `PrefabBreadcrumb(...)` entries for every ancestor of [manifest], one
/// line each, outermost first. Each is labelled with the first visible field
/// of the ancestor (read from its detail provider) and goes to its detail
/// screen when tapped.
List<String> ancestorBreadcrumbItems(EntityManifest manifest) {
  final lines = <String>[];
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
      ..add(
          "      onTap: () => context.go('${EntityPaths.ancestorPath(manifest, i)}'),")
      ..add('    ),');
  }
  return lines;
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

String escapeDartString(String value) => value
    .replaceAll(r'\', r'\\')
    .replaceAll("'", r"\'")
    .replaceAll(r'$', r'\$');

/// What only the breadcrumbs feature needs to know about an entity.
extension BreadcrumbsManifest on EntityManifest {
  /// Whether list and detail screens show a breadcrumb row (two or more
  /// ancestors).
  bool get hasBreadcrumbs => depth >= 2;
}
