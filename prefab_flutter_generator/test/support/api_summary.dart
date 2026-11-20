import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/analysis/utilities.dart';

/// Extracts the public API of generated source: every public top-level
/// declaration with the signatures of its public members, without bodies,
/// annotations or comments. Private declarations are not part of the API.
String extractPublicApi(String source) {
  final unit = parseString(content: source, throwIfDiagnostics: false).unit;
  final out = StringBuffer();
  String text(AstNode node, {int? end}) {
    final start = node is AnnotatedNode
        ? node.firstTokenAfterCommentAndMetadata.offset
        : node.offset;
    return source.substring(start, end ?? node.end).replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  bool public(String? name) => name == null || !name.startsWith('_');

  for (final d in unit.declarations) {
    if (d is ClassDeclaration) {
      if (!public(d.name.lexeme)) continue;
      out.writeln(text(d, end: d.leftBracket.offset));
      for (final m in d.members) {
        if (m is ConstructorDeclaration) {
          if (!public(m.name?.lexeme)) continue;
          out.writeln('  ${text(m, end: m.body.offset)};');
        } else if (m is MethodDeclaration) {
          if (!public(m.name.lexeme)) continue;
          out.writeln('  ${text(m, end: m.body.offset)};');
        } else if (m is FieldDeclaration) {
          for (final v in m.fields.variables) {
            if (!public(v.name.lexeme)) continue;
            final prefix = [
              if (m.isStatic) 'static',
              if (m.fields.isFinal) 'final',
              if (m.fields.type != null) text(m.fields.type!),
            ].join(' ');
            out.writeln('  $prefix ${v.name.lexeme};');
          }
        }
      }
    } else if (d is FunctionDeclaration) {
      if (!public(d.name.lexeme)) continue;
      out.writeln('${text(d, end: d.functionExpression.body.offset)};');
    } else if (d is TopLevelVariableDeclaration) {
      for (final v in d.variables.variables) {
        if (!public(v.name.lexeme)) continue;
        final type = d.variables.type;
        final init = v.initializer;
        // The initializer without its arguments shows the provider kind and
        // type arguments, e.g. `AsyncNotifierProvider.autoDispose<N, T>`.
        var shown = '';
        if (init is MethodInvocation) {
          shown = ' = ${init.target == null ? '' : '${text(init.target!)}.'}'
              '${init.methodName.name}${init.typeArguments == null ? '' : text(init.typeArguments!)}';
        }
        out.writeln('final${type == null ? '' : ' ${text(type)}'} ${v.name.lexeme}$shown;');
      }
    }
  }
  return out.toString();
}
