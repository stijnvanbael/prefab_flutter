import '../core/artifact.dart';
import '../manifest/entity_manifest.dart';

/// Compares the shape of a `@Promoted` declaration (see `promoted_shape.dart`)
/// with the signature the generated code calls, for the artifact of [kind]
/// named [name] of [manifest]. Returns `null` when it matches, else a message
/// with the expected signature and the difference.
///
/// The check is deliberately lenient: it reports only what it can see in the
/// syntax. A type it cannot read (a `super.` parameter, a provider built by a
/// helper function) is not a mismatch. The signatures are the ones documented
/// in `docs/user_guide/promoting.md`.
String? checkPromotedSignature(ArtifactKind kind, String name,
    EntityManifest manifest, Map<String, Object?> shape) {
  switch (kind) {
    case ArtifactKind.detailScreen:
    case ArtifactKind.editScreen:
    case ArtifactKind.operationScreen:
      return _screen(name, shape, [_Param('id', manifest.idType), ..._ids(manifest)]);
    case ArtifactKind.listScreen:
    case ArtifactKind.createScreen:
      return _screen(name, shape, _ids(manifest));
    case ArtifactKind.apiClient:
      return _apiClient(name, manifest, shape);
    case ArtifactKind.apiClientProvider:
      return _provider(name, shape, '<${manifest.entityName}ApiClient>',
          'Provider<${manifest.entityName}ApiClient>');
    case ArtifactKind.detailProvider:
      final key = _key(manifest, withId: true);
      return _provider(name, shape, '<${manifest.entityName}, $key>',
          'FutureProvider.autoDispose.family<${manifest.entityName}, $key>');
    case ArtifactKind.listProvider:
      final e = manifest.entityName;
      final key = manifest.hasParent ? _key(manifest, withId: false) : null;
      return _provider(
          name,
          shape,
          '<${e}sNotifier, PrefabPage<$e>${key == null ? '>' : ', $key>'}',
          'AsyncNotifierProvider<${e}sNotifier, PrefabPage<$e>${key == null ? '' : ', $key'}>'
              '${key == null ? '' : ' (a family keyed by the ancestor ids)'}');
    case ArtifactKind.routes:
      return _routes(name, shape);
    case ArtifactKind.breadcrumbs:
      return null;
  }
}

class _Param {
  _Param(this.name, this.type);
  final String name;
  final String type;
  String get required => 'required $type $name';
}

List<_Param> _ids(EntityManifest m) =>
    [for (final a in m.ancestors) _Param(a.paramName, a.idType)];

/// The key type of a family: the id type alone, or a record of all id types.
String _key(EntityManifest m, {required bool withId}) {
  final types = [if (withId) m.idType, for (final a in m.ancestors) a.idType];
  return types.length == 1 ? types.first : '(${types.join(', ')})';
}

String _norm(String s) => s.replaceAll(RegExp(r'\s+'), '');

String _message(String name, String expected, String found, String diff) =>
    'does not match the generated code that uses it. Expected: $expected. '
    'Found: $found. $diff';

List<Map<String, Object?>> _list(Object? o) =>
    [for (final e in (o as List? ?? const [])) (e as Map).cast<String, Object?>()];

String _renderParams(List<Map<String, Object?>> params) {
  String one(Map<String, Object?> p) {
    final type = p['type'] == null ? '' : '${p['type']} ';
    return '${p['required'] == true && p['named'] == true ? 'required ' : ''}$type${p['name']}';
  }

  final positional = [for (final p in params) if (p['positional'] == true) p];
  final named = [for (final p in params) if (p['named'] == true) p];
  final required = [for (final p in positional) if (p['required'] == true) p];
  final optional = [for (final p in positional) if (p['required'] != true) p];
  return [
    ...required.map(one),
    if (optional.isNotEmpty) '[${optional.map(one).join(', ')}]',
    if (named.isNotEmpty) '{${named.map(one).join(', ')}}',
  ].join(', ');
}

Map<String, Object?>? _unnamedConstructor(Map<String, Object?> shape) {
  for (final c in _list(shape['constructors'])) {
    if (c['name'] == '') return c;
  }
  return null;
}

/// Differences between the named parameters of [params] and [expected]: the
/// parameters the generated code passes must exist with the same type, any
/// other parameter must be optional, and nothing may be required positionally.
List<String> _namedDifferences(
    List<Map<String, Object?>> params, List<_Param> expected) {
  final diffs = <String>[];
  for (final e in expected) {
    final p = params.where((p) => p['name'] == e.name).firstOrNull;
    if (p == null || p['named'] != true) {
      diffs.add('missing named parameter ${e.required}');
      continue;
    }
    final type = p['type'] as String?;
    if (type != null && _norm(type).replaceFirst(RegExp(r'\?$'), '') != _norm(e.type)) {
      diffs.add('parameter ${e.name} has type $type, expected ${e.type}');
    }
  }
  for (final p in params) {
    final known = expected.any((e) => e.name == p['name']);
    if (p['positional'] == true && p['required'] == true) {
      diffs.add('positional parameter ${p['name']} must not be required');
    } else if (p['named'] == true && p['required'] == true && !known) {
      diffs.add('parameter ${p['name']} must not be required, the generated '
          'code does not pass it');
    }
  }
  return diffs;
}

String? _screen(String name, Map<String, Object?> shape, List<_Param> params) {
  final expected = 'const $name({super.key${[
    for (final p in params) ', ${p.required}',
  ].join()}})';
  if (shape['kind'] != 'class') {
    return _message(name, expected, 'a ${shape['kind']}',
        'A screen must be a class (a widget).');
  }
  final ctor = _unnamedConstructor(shape)!;
  final found =
      '${ctor['const'] == true ? 'const ' : ''}$name(${_renderParams(_list(ctor['params']))})';
  final diffs = [
    if (ctor['const'] != true) 'the constructor must be const',
    ..._namedDifferences(_list(ctor['params']), params),
  ];
  return diffs.isEmpty ? null : _message(name, expected, found, '${diffs.join('; ')}.');
}

String? _apiClient(String name, EntityManifest m, Map<String, Object?> shape) {
  final methods = [
    'list',
    'getById',
    if (m.hasCreate) 'create',
    if (m.hasUpdate) 'update',
    if (m.hasDelete) 'delete',
  ];
  final expected = '$name(Dio, [PrefabListAdapter]) with the methods '
      '${methods.join(', ')}'
      '${m.hasParent ? ' (each also taking ${[for (final a in m.ancestors) 'required ${a.idType} ${a.paramName}'].join(', ')})' : ''}';
  if (shape['kind'] != 'class') {
    return _message(
        name, expected, 'a ${shape['kind']}', 'An API client must be a class.');
  }
  final diffs = <String>[];
  final ctor = _unnamedConstructor(shape)!;
  final params = _list(ctor['params']);
  final positional = params.where((p) => p['positional'] == true).toList();
  final requiredPositional =
      positional.where((p) => p['required'] == true).length;
  if (positional.length < 2 || requiredPositional > 2) {
    diffs.add('the constructor must take the Dio and the PrefabListAdapter '
        'as positional parameters');
  } else if (params.any((p) => p['named'] == true && p['required'] == true)) {
    diffs.add('the constructor must not have required named parameters');
  }
  // Methods inherited from a superclass cannot be seen.
  if (shape['extends'] != true) {
    final byName = {for (final x in _list(shape['methods'])) x['name']: x};
    for (final method in methods) {
      final x = byName[method];
      if (x == null) {
        diffs.add('missing method $method');
        continue;
      }
      for (final a in m.ancestors) {
        final p = _list(x['params']).where((p) => p['name'] == a.paramName);
        if (p.isEmpty || p.first['named'] != true) {
          diffs.add('$method is missing the named parameter '
              'required ${a.idType} ${a.paramName}');
        }
      }
    }
  }
  final found = '$name(${_renderParams(params)})'
      ' with the methods ${[for (final x in _list(shape['methods'])) x['name']].join(', ')}';
  return diffs.isEmpty ? null : _message(name, expected, found, '${diffs.join('; ')}.');
}

/// [needle] is the type arguments the declared type or the initializer must
/// contain (whitespace is ignored).
String? _provider(String name, Map<String, Object?> shape, String needle,
    String expected) {
  final kind = shape['kind'];
  if (kind != 'variable' && kind != 'getter') {
    return _message(name, expected, 'a $kind',
        'A provider must be a top-level variable.');
  }
  final type = shape['type'] as String?;
  // A provider built by a helper has no readable type: nothing to compare.
  if (type == null || _norm(type).contains(_norm(needle))) return null;
  return _message(name, expected, type,
      'The type arguments must contain $needle.');
}

String? _routes(String name, Map<String, Object?> shape) {
  const expected = 'List<RouteBase>';
  final kind = shape['kind'];
  if (kind != 'variable' && kind != 'getter') {
    return _message(name, 'a top-level getter `$expected get $name`',
        'a $kind', 'Routes are spread into the router as `...$name`.');
  }
  final type = shape['type'] as String?;
  if (type == null || _norm(type) == _norm(expected)) return null;
  return _message(name, 'a top-level getter `$expected get $name`', type,
      'The type must be $expected.');
}
