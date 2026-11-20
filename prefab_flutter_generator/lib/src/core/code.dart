/// Well-known libraries generated code imports.
abstract final class Libs {
  static const dio = 'package:dio/dio.dart';
  static const dartAsync = 'dart:async';
  static const flutterServices = 'package:flutter/services.dart';
  static const materialUi = 'package:material_ui/material_ui.dart';
  static const riverpod = 'package:flutter_riverpod/flutter_riverpod.dart';
  static const goRouter = 'package:go_router/go_router.dart';
  static const widgets =
      'package:prefab_flutter_widgets/prefab_flutter_widgets.dart';
}

/// A fragment of generated Dart source plus the libraries it needs.
///
/// A fragment never contains `import` lines; the libraries it needs are named
/// in [imports] and collected by the core.
class Code {
  const Code(this.text, {this.imports = const {}});

  final String text;
  final Set<String> imports;
}

/// Collects the imports of every fragment that is emitted into one library.
///
/// [render] orders them as the generator always did: package imports sorted,
/// a blank line, other imports sorted, then the exports of promoted artifacts.
class Imports {
  final _uris = <String>{};
  final _exports = <String, Set<String>>{};

  void add(String uri) => _uris.add(uri);

  void addAll(Iterable<String> uris) => _uris.addAll(uris);

  /// Re-exports [name] from [uri] (used for promoted artifacts).
  void export(String uri, String name) =>
      (_exports[uri] ??= <String>{}).add(name);

  bool get isEmpty => _uris.isEmpty && _exports.isEmpty;

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

/// Indents every non-empty line of [text] by [spaces].
String indent(String text, int spaces) {
  final pad = ' ' * spaces;
  return text.split('\n').map((l) => l.isEmpty ? l : '$pad$l').join('\n');
}
