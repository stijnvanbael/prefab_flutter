import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';

import '../core/declarations.dart';
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

/// Reads the `@Promoted` declarations (the names of hand-written artifacts).
class PromotedScanner extends DeclarationScanner<PromotedDeclaration> {
  const PromotedScanner();

  static const instance = PromotedScanner();

  @override
  String get key => 'promoted';

  @override
  String get marker => 'Promoted';

  @override
  List<PromotedDeclaration> scan(String source, String uri) => [
        for (final (name, shape) in scanPromoted(source))
          PromotedDeclaration(name, uri, shape: shape),
      ];

  @override
  Map<String, Object?> toJson(PromotedDeclaration d) =>
      {'name': d.name, 'uri': d.libraryUri, 'shape': d.shape};

  @override
  PromotedDeclaration fromJson(Map<String, dynamic> json) =>
      PromotedDeclaration(json['name'] as String, json['uri'] as String,
          shape: (json['shape'] as Map?)?.cast<String, Object?>());
}
