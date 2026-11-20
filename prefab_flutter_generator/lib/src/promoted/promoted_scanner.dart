import 'dart:convert';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:build/build.dart';
import 'package:glob/glob.dart';

import '../core/library_emitter.dart';
import 'promoted_shape.dart';

/// Names of the top-level declarations annotated with `@Promoted()` in
/// [source], read from the unresolved syntax tree (so the scan does not depend
/// on generated code). Accepts `@Promoted()` and `@prefix.Promoted()`.
List<String> scanPromotedNames(String source) =>
    [for (final (name, _) in scanPromoted(source)) name];

/// Like [scanPromotedNames], with the shape of each declaration (see
/// `shapeOf`) that the signature check compares with the generated code.
List<(String, Map<String, Object?>)> scanPromoted(String source) {
  final unit = parseString(content: source, throwIfDiagnostics: false).unit;
  final result = <(String, Map<String, Object?>)>[];
  for (final declaration in unit.declarations) {
    if (!declaration.metadata.any(_isPromoted)) continue;
    // ignore: deprecated_member_use
    if (declaration is NamedCompilationUnitMember) {
      // ignore: deprecated_member_use
      result.add((declaration.name.lexeme, shapeOf(declaration)));
    } else if (declaration is TopLevelVariableDeclaration) {
      for (final v in declaration.variables.variables) {
        result.add((v.name.lexeme, shapeOf(declaration, variable: v.name.lexeme)));
      }
    }
  }
  return result;
}

bool _isPromoted(Annotation a) {
  final name = a.name;
  final id = name is PrefixedIdentifier ? name.identifier.name : name.name;
  return id == 'Promoted' && a.constructorName == null;
}

const promotedExtension = '.prefab_promoted.json';

/// Writes `<file>.prefab_promoted.json` for every file with `@Promoted`
/// declarations; files without any get no output, so editing them changes no
/// summary.
class PromotedBuilder implements Builder {
  @override
  Map<String, List<String>> get buildExtensions => const {
        '.dart': [promotedExtension],
      };

  @override
  Future<void> build(BuildStep buildStep) async {
    final id = buildStep.inputId;
    if (id.path.endsWith('.prefab.dart') || id.path.endsWith('.g.dart')) {
      return;
    }
    final source = await buildStep.readAsString(id);
    if (!source.contains('Promoted')) return;
    final found = scanPromoted(source);
    if (found.isEmpty) return;
    final uri = id.uri.toString();
    await buildStep.writeAsString(
      id.changeExtension(promotedExtension),
      jsonEncode([
        for (final (name, shape) in found)
          {'name': name, 'uri': uri, 'shape': shape},
      ]),
    );
  }
}

/// Reads the summaries of all `@Promoted` declarations of the package.
Future<List<PromotedDeclaration>> readPromoted(BuildStep buildStep) async {
  final result = <PromotedDeclaration>[];
  final ids = await buildStep
      .findAssets(Glob('lib/**$promotedExtension'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));
  for (final id in ids) {
    final json = jsonDecode(await buildStep.readAsString(id)) as List;
    for (final entry in json) {
      result.add(PromotedDeclaration(
          entry['name'] as String, entry['uri'] as String,
          shape: (entry['shape'] as Map?)?.cast<String, Object?>()));
    }
  }
  return result;
}
