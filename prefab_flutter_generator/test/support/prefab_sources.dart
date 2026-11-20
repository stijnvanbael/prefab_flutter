import 'dart:io';

import 'package:path/path.dart' as p;

/// The real `prefab_flutter` annotation sources, keyed by asset id, ready to
/// be passed to `testBuilder`'s `sourceAssets`.
///
/// The files are read from `../prefab_flutter/lib/` at test time, so tests
/// always see the annotations that ship, never a stale copy.
final Map<String, String> prefabSources = _loadPrefabSources();

Map<String, String> _loadPrefabSources() {
  final lib = Directory(p.join(_packageRoot(), '..', 'prefab_flutter', 'lib'));
  if (!lib.existsSync()) {
    throw StateError('Cannot find ${lib.path}. Run the tests from the '
        'prefab_flutter_generator package.');
  }
  final sources = <String, String>{};
  for (final file in lib.listSync(recursive: true).whereType<File>()) {
    if (!file.path.endsWith('.dart')) continue;
    final relative =
        p.posix.joinAll(p.split(p.relative(file.path, from: lib.path)));
    sources['prefab_flutter|lib/$relative'] = file.readAsStringSync();
  }
  return sources;
}

/// The directory of the `prefab_flutter_generator` package (the working
/// directory of `dart test`).
String _packageRoot() {
  var dir = Directory.current;
  while (!File(p.join(dir.path, 'pubspec.yaml')).existsSync()) {
    final parent = dir.parent;
    if (parent.path == dir.path) return Directory.current.path;
    dir = parent;
  }
  return dir.path;
}
