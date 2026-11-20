/// An id that scopes a resource family: one ancestor of a nested entity.
class FamilyId {
  const FamilyId({required this.name, required this.type, required this.path});

  /// Dart parameter name carrying the id (`orderId`).
  final String name;

  /// Dart type of the id (`int`, `String`).
  final String type;

  /// URL path segment of the resource that owns the id (`orders`).
  final String path;
}

/// The ids a feature added to the `familyKey` point of an artifact, outermost
/// first, and the Dart snippets the templates build from them. Empty for an
/// entity that is not scoped by any other.
class FamilyKey {
  const FamilyKey(this.ids);

  final List<FamilyId> ids;

  bool get isEmpty => ids.isEmpty;

  int get depth => ids.length;

  /// Key type of the list provider: the id type for one id, a positional
  /// record of all id types otherwise.
  String get listType =>
      depth == 1 ? ids.first.type : '(${ids.map((i) => i.type).join(', ')})';

  /// Expression building the list provider key from [value] of each id.
  String listExpr(String Function(FamilyId id) value) =>
      depth == 1 ? value(ids.first) : '(${ids.map(value).join(', ')})';

  /// Type of the detail provider key: `(idType, ancestor id types...)`.
  String detailType(String idType) =>
      '($idType, ${ids.map((i) => i.type).join(', ')})';

  /// Detail provider key: [idExpr] alone without ids, else a record of
  /// [idExpr] and [value] of each id.
  String detailExpr(String idExpr, String Function(FamilyId id) value) =>
      isEmpty ? idExpr : '($idExpr, ${ids.map(value).join(', ')})';

  /// `required int orderId, required int orderLineId`.
  String get requiredParams =>
      ids.map((i) => 'required ${i.type} ${i.name}').join(', ');

  /// `required this.orderId, required this.orderLineId`.
  String get requiredThis =>
      ids.map((i) => 'required this.${i.name}').join(', ');

  /// `orderId: orderId, ...`, each value prefixed with [prefix].
  String namedArgs([String prefix = '']) =>
      ids.map((i) => '${i.name}: $prefix${i.name}').join(', ');

  /// URL prefix of the resource: `/orders/$orderId/lines/$orderLineId`.
  String get urlPrefix =>
      [for (final i in ids) '/${i.path}/\$${i.name}'].join();
}
