// PF-37 prototype - not part of the published generator. PF-38 implements
// the real core in lib/src/core/ and deletes this directory.

/// Well-known libraries generated code imports.
abstract final class Libs {
  static const materialUi = 'package:material_ui/material_ui.dart';
  static const riverpod = 'package:flutter_riverpod/flutter_riverpod.dart';
  static const goRouter = 'package:go_router/go_router.dart';
  static const widgets =
      'package:prefab_flutter_widgets/prefab_flutter_widgets.dart';
}

/// A fragment of generated Dart source plus the libraries it needs.
///
/// Fragments are written at column 0; the extension point they are added to
/// indents them. A fragment never writes `import` lines itself.
class Code {
  const Code(this.text, {this.imports = const {}});

  final String text;
  final Set<String> imports;
}

/// Collects the imports of every fragment that is emitted into one library.
///
/// [render] reproduces today's `PrefabGenerator` order (package imports
/// sorted, a blank line, other imports sorted), so migrated output stays
/// byte-identical.
class Imports {
  final _uris = <String>{};
  final _exports = <String, Set<String>>{};

  void add(String uri) => _uris.add(uri);

  /// Re-exports [name] from [uri] (used for promoted artifacts).
  void export(String uri, String name) =>
      (_exports[uri] ??= <String>{}).add(name);

  void addAll(Iterable<String> uris) => _uris.addAll(uris);

  String render() {
    final package = _uris.where((u) => u.startsWith('package:')).toList()
      ..sort();
    final other = _uris.where((u) => !u.startsWith('package:')).toList()
      ..sort();
    return [
      for (final u in package) "import '$u';",
      if (package.isNotEmpty && other.isNotEmpty) '',
      for (final u in other) "import '$u';",
      if (_exports.isNotEmpty) '',
      for (final MapEntry(key: u, value: names) in _exports.entries)
        "export '$u' show ${(names.toList()..sort()).join(', ')};",
    ].join('\n');
  }
}

/// Joins [lines], dropping `null`s, so templates can include optional lines
/// with `if (...) '...'` collection elements or `cond ? '...' : null`.
String lines(Iterable<String?> lines) => lines.whereType<String>().join('\n');

/// Indents every non-empty line of [text] by [spaces].
String indent(String text, int spaces) {
  final pad = ' ' * spaces;
  return text.split('\n').map((l) => l.isEmpty ? l : '$pad$l').join('\n');
}
