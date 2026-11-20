// PF-37 prototype - not part of the published generator.

import 'code.dart';

/// A place in an artifact template that feature modules contribute code to.
///
/// Contributions are rendered by ascending [Contribution.order] (ties broken
/// by feature name), so the output does not depend on the order in which
/// features are registered.
class ExtensionPoint {
  ExtensionPoint(this.name, {this.maxContributions});

  /// Qualified name used in error messages and docs, e.g.
  /// `detailScreen.appBarActions`.
  final String name;

  /// Upper bound for single-valued points such as `appBar.bottom`.
  final int? maxContributions;

  final _contributions = <Contribution>[];

  void add(String feature, Code code, {int order = 0}) {
    if (maxContributions != null &&
        _contributions.length >= maxContributions!) {
      final others = _contributions.map((c) => c.feature).join(', ');
      throw StateError(
          '$feature cannot contribute to $name: already taken by $others.');
    }
    _contributions.add(Contribution(feature, code, order));
  }

  bool get isEmpty => _contributions.isEmpty;

  List<Contribution> get contributions => [..._contributions]..sort((a, b) {
      final byOrder = a.order.compareTo(b.order);
      return byOrder != 0 ? byOrder : a.feature.compareTo(b.feature);
    });

  /// Imports needed by all contributions.
  Set<String> get imports =>
      {for (final c in _contributions) ...c.code.imports};

  /// The contributions' text, each indented by [spaces], one after another.
  String render(int spaces) =>
      contributions.map((c) => indent(c.code.text, spaces)).join('\n');
}

class Contribution {
  const Contribution(this.feature, this.code, this.order);

  final String feature;
  final Code code;
  final int order;
}
