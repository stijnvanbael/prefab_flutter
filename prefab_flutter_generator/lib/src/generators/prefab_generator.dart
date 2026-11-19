import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'api_client_generator.dart';
import 'detail_screen_generator.dart';
import 'form_screen_generator.dart';
import 'list_screen_generator.dart';
import 'provider_generator.dart';
import 'routes_generator.dart';

/// Generates everything for a source file into one `.prefab.dart` library.
///
/// Runs the individual generators, drops their imports of each other's
/// output files, merges and de-duplicates the remaining imports, and
/// concatenates the bodies.
class PrefabGenerator extends Generator {
  PrefabGenerator()
      : _generators = [
          ApiClientGenerator(),
          ProviderGenerator(),
          DetailScreenGenerator(),
          ListScreenGenerator(),
          FormScreenGenerator(),
          RoutesGenerator(),
        ];

  final List<Generator> _generators;

  static final _importLine = RegExp(r'''^import '([^']+)';\s*$''');
  static final _siblingImport = RegExp(
      r'\.(api_client|provider|detail_screen|list_screen|form_screen|routes)\.dart$');

  @override
  Future<String> generate(LibraryReader library, BuildStep buildStep) async {
    final imports = <String>{};
    final bodies = <String>[];

    for (final generator in _generators) {
      final output = await generator.generate(library, buildStep);
      if (output == null || output.trim().isEmpty) continue;

      final body = <String>[];
      for (final line in output.split('\n')) {
        final match = _importLine.firstMatch(line);
        if (match != null) {
          if (!_siblingImport.hasMatch(match.group(1)!)) {
            imports.add(match.group(1)!);
          }
        } else {
          body.add(line);
        }
      }
      bodies.add(_stripHeader(body).join('\n').trim());
    }
    if (bodies.isEmpty) return '';

    final package = imports.where((i) => i.startsWith('package:')).toList()
      ..sort();
    final relative = imports.where((i) => !i.startsWith('package:')).toList()
      ..sort();

    final buffer = StringBuffer();
    const sep =
        '// **************************************************************************';
    buffer
      ..writeln('// GENERATED CODE - DO NOT MODIFY BY HAND')
      ..writeln('//')
      ..writeln(sep)
      ..writeln('// PrefabGenerator')
      ..writeln(sep)
      ..writeln();
    for (final i in package) {
      buffer.writeln("import '$i';");
    }
    if (package.isNotEmpty && relative.isNotEmpty) buffer.writeln();
    for (final i in relative) {
      buffer.writeln("import '$i';");
    }
    for (final body in bodies) {
      buffer
        ..writeln()
        ..writeln(body);
    }
    return buffer.toString();
  }

  /// Removes the per-generator "GENERATED CODE" banner (comment lines at the
  /// top of the body).
  List<String> _stripHeader(List<String> lines) {
    var i = 0;
    while (i < lines.length &&
        (lines[i].startsWith('//') || lines[i].trim().isEmpty)) {
      i++;
    }
    return lines.sublist(i);
  }
}
