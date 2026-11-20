import 'package:analyzer/dart/ast/ast.dart';

/// A JSON-able summary of the syntax of a `@Promoted` declaration: just enough
/// to compare it with the signature generated code calls (see
/// `signature_check.dart`). Read from the unresolved syntax tree, so it does
/// not depend on generated code.
///
/// * class: `{kind: 'class', extends: bool, fields: {name: type},
///   constructors: [{name, const, params}], methods: [{name, params}]}`
/// * top-level variable: `{kind: 'variable', type: text|null}`
/// * top-level function or getter: `{kind: 'function'|'getter', type: text|null,
///   params: [...]}`
/// * anything else: `{kind: 'other'}`
///
/// A parameter is `{name, type: text|null, named, required, positional}`.
Map<String, Object?> shapeOf(CompilationUnitMember declaration,
    {String? variable}) {
  if (declaration is ClassDeclaration) return _classShape(declaration);
  if (declaration is TopLevelVariableDeclaration) {
    final list = declaration.variables;
    final v = list.variables.firstWhere((v) => v.name.lexeme == variable);
    return {
      'kind': 'variable',
      'type': list.type?.toSource() ?? _initializerType(v.initializer),
    };
  }
  if (declaration is FunctionDeclaration) {
    return {
      'kind': declaration.isGetter ? 'getter' : 'function',
      'type': declaration.returnType?.toSource(),
      'params': _params(declaration.functionExpression.parameters, const {}),
    };
  }
  return {'kind': 'other'};
}

/// The type a provider initializer names: `FutureProvider.autoDispose
/// .family<Order, int>` for `FutureProvider.autoDispose.family<Order, int>(...)`;
/// `null` when the initializer does not spell out type arguments.
String? _initializerType(Expression? init) {
  if (init is MethodInvocation && init.typeArguments != null) {
    return '${init.target == null ? '' : '${init.target!.toSource()}.'}'
        '${init.methodName.name}${init.typeArguments!.toSource()}';
  }
  if (init is InstanceCreationExpression &&
      init.constructorName.type.typeArguments != null) {
    return init.constructorName.toSource();
  }
  return null;
}

Map<String, Object?> _classShape(ClassDeclaration c) {
  final fields = <String, String?>{};
  final constructors = <Map<String, Object?>>[];
  final methods = <Map<String, Object?>>[];
  for (final member in c.members) {
    if (member is FieldDeclaration) {
      for (final v in member.fields.variables) {
        fields[v.name.lexeme] = member.fields.type?.toSource();
      }
    }
  }
  for (final member in c.members) {
    if (member is ConstructorDeclaration) {
      constructors.add({
        'name': member.name?.lexeme ?? '',
        'const': member.constKeyword != null,
        'params': _params(member.parameters, fields),
      });
    } else if (member is MethodDeclaration && !member.isGetter) {
      methods.add({
        'name': member.name.lexeme,
        'params': _params(member.parameters, fields),
      });
    }
  }
  if (!constructors.any((c) => c['name'] == '')) {
    constructors.add({'name': '', 'const': false, 'params': <Object?>[]});
  }
  return {
    'kind': 'class',
    'extends': c.extendsClause != null &&
        c.extendsClause!.superclass.name.lexeme != 'Object',
    'fields': fields,
    'constructors': constructors,
    'methods': methods,
  };
}

List<Map<String, Object?>> _params(
    FormalParameterList? list, Map<String, String?> fields) {
  if (list == null) return [];
  return [
    for (final p in list.parameters)
      () {
        final inner = p is DefaultFormalParameter ? p.parameter : p;
        final name = inner.name?.lexeme ?? '';
        String? type;
        if (inner is SimpleFormalParameter) {
          type = inner.type?.toSource();
        } else if (inner is FieldFormalParameter) {
          type = inner.type?.toSource() ?? fields[name];
        }
        return <String, Object?>{
          'name': name,
          'type': type,
          'named': p.isNamed,
          'required': p.isRequired,
          'positional': p.isPositional,
        };
      }(),
  ];
}
