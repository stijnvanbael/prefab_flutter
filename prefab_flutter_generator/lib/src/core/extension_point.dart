import 'code.dart';

/// A place in an artifact template that feature modules contribute code to.
///
/// Contributions are rendered by ascending order (ties broken by feature
/// name), so the output does not depend on the order in which features are
/// registered. A single-valued point ([maxContributions] set) fails with both
/// feature names when a feature claims it twice.
class ExtensionPoint {
  ExtensionPoint(this.name, {this.maxContributions});

  /// Qualified name used in error messages and docs, e.g.
  /// `detailScreen.appBarActions`.
  final String name;

  /// Upper bound for single-valued points such as `appBarBottom`.
  final int? maxContributions;

  final _contributions = <Contribution>[];

  void add(String feature, Code code, {int order = 0}) =>
      addLazy(feature, () => code, order: order);

  /// Like [add], but [build] runs when the artifact is emitted, so the code
  /// can use what other features add to the artifact after this one ran (e.g.
  /// the `familyKey` of nested resources).
  void addLazy(String feature, Code Function() build, {int order = 0}) {
    if (maxContributions != null &&
        _contributions.length >= maxContributions!) {
      final others = _contributions.map((c) => c.feature).join(', ');
      throw StateError(
          '$feature cannot contribute to $name: already taken by $others.');
    }
    _contributions.add(Contribution(feature, build, order));
  }

  bool get isEmpty => _contributions.isEmpty;

  List<Contribution> get contributions => [..._contributions]..sort((a, b) {
      final byOrder = a.order.compareTo(b.order);
      return byOrder != 0 ? byOrder : a.feature.compareTo(b.feature);
    });

  /// Imports needed by all contributions.
  Set<String> get imports =>
      {for (final c in _contributions) ...c.code.imports};

  /// The contributions' text, each indented by [spaces], one after another
  /// and joined by [separator] (`'\n\n'` puts a blank line between members).
  String render(int spaces, {String separator = '\n'}) => contributions
      .map((c) => indent(c.code.text, spaces))
      .join(separator);
}

class Contribution {
  const Contribution(this.feature, this._build, this.order);

  final String feature;
  final Code Function() _build;
  final int order;

  Code get code => _build();
}

/// A place in an artifact template that holds typed values instead of code,
/// for contributions that several features combine and the template renders
/// (e.g. the query parameters of the list request).
///
/// Values are ordered like an [ExtensionPoint]: by `order`, then feature
/// name, then the order in which they were added.
class ValuePoint<T> {
  ValuePoint(this.name);

  /// Qualified name, e.g. `apiClient.listQueryParameters`.
  final String name;

  final _entries = <(String, int, T)>[];

  void add(String feature, T value, {int order = 0}) =>
      _entries.add((feature, order, value));

  bool get isEmpty => _entries.isEmpty;

  List<T> get values {
    final indexed = [
      for (var i = 0; i < _entries.length; i++) (i, _entries[i]),
    ];
    indexed.sort((a, b) {
      final byOrder = a.$2.$2.compareTo(b.$2.$2);
      if (byOrder != 0) return byOrder;
      final byFeature = a.$2.$1.compareTo(b.$2.$1);
      return byFeature != 0 ? byFeature : a.$1.compareTo(b.$1);
    });
    return [for (final e in indexed) e.$2.$3];
  }
}

/// A named argument of a generated call, e.g. `search: _search`.
class NamedArgument {
  const NamedArgument(this.name, this.expression);

  final String name;
  final String expression;

  @override
  String toString() => '$name: $expression';
}

/// A parameter of the API client's `list` method.
///
/// It is always declared. With [query] it is also passed to
/// `PrefabBackend.queryParameters`, with [parse] also to `parsePage`.
class QueryParameter {
  const QueryParameter(
    this.name,
    this.type, {
    this.defaultValue,
    this.query = true,
    this.parse = false,
  });

  final String name;
  final String type;
  final String? defaultValue;
  final bool query;
  final bool parse;

  String get declaration =>
      defaultValue == null ? '$type $name' : '$type $name = $defaultValue';
}
