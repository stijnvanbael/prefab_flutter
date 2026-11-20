import '../validators/validator_emitters.dart' show dartStringLiteral;

/// One action as the screens show it: a label, an optional icon (a member of
/// `Icons`) and the call that runs it.
///
/// Rendering is shared by every kind of action, so the hand-written
/// `@EntityAction` functions and the named domain operations planned in PF-54
/// look and sort the same.
class ActionItem {
  const ActionItem({
    required this.label,
    required this.call,
    this.icon,
    this.order = 0,
    this.name = '',
  });

  final String label;

  /// Name of a member of `Icons`; `Icons.bolt` when `null`.
  final String? icon;

  /// A Dart expression that runs the action, e.g.
  /// `duplicateProduct(context, ref, productAsync.value!)`.
  final String call;

  /// Sort key: [order], then [label], then [name].
  final int order;
  final String name;
}

/// At most this many actions are shown as icon buttons; the rest go into an
/// overflow menu.
const maxIconButtons = 2;

/// Sorts by `order`, then label (case-insensitive), then name.
List<ActionItem> sortActions(Iterable<ActionItem> items) => [...items]
  ..sort((a, b) {
    final byOrder = a.order.compareTo(b.order);
    if (byOrder != 0) return byOrder;
    final byLabel = a.label.toLowerCase().compareTo(b.label.toLowerCase());
    return byLabel != 0 ? byLabel : a.name.compareTo(b.name);
  });

String _icon(ActionItem a) => 'Icons.${a.icon ?? 'bolt'}';

/// AppBar actions: the first [maxIconButtons] of [items] (already sorted) as
/// icon buttons, the rest in one overflow menu. With [enabledWhen] (a boolean
/// expression) the actions are disabled while it is false, for example while
/// the entity is loading. Written at column 0, one widget after the other.
String renderAppBarActions(List<ActionItem> items, {String? enabledWhen}) {
  final lines = <String>[];
  for (final a in items.take(maxIconButtons)) {
    final onPressed = enabledWhen == null
        ? '() => ${a.call}'
        : '$enabledWhen ? () => ${a.call} : null';
    lines
      ..add('IconButton(')
      ..add('  icon: const Icon(${_icon(a)}),')
      ..add('  tooltip: ${dartStringLiteral(a.label)},')
      ..add('  onPressed: $onPressed,')
      ..add('),');
  }
  final overflow = items.skip(maxIconButtons).toList();
  if (overflow.isNotEmpty) {
    lines
      ..add('PopupMenuButton<void>(')
      ..add("  tooltip: 'More actions',")
      ..add('  itemBuilder: (_) => [');
    for (final a in overflow) {
      lines.addAll(_menuEntry(a, enabledWhen).map((l) => '    $l'));
    }
    lines
      ..add('  ],')
      ..add('),');
  }
  return lines.join('\n');
}

/// The entries of a menu, one `PopupMenuItem` per action, at column 0.
String renderMenuEntries(List<ActionItem> items) =>
    [for (final a in items) ..._menuEntry(a, null)].join('\n');

List<String> _menuEntry(ActionItem a, String? enabledWhen) => [
      'PopupMenuItem<void>(',
      if (enabledWhen != null) '  enabled: $enabledWhen,',
      '  onTap: () => ${a.call},',
      if (a.icon == null)
        '  child: const Text(${dartStringLiteral(a.label)}),'
      else ...[
        '  child: const Row(',
        '    children: [',
        '      Icon(${_icon(a)}),',
        '      SizedBox(width: 8),',
        '      Text(${dartStringLiteral(a.label)}),',
        '    ],',
        '  ),',
      ],
      '),',
    ];
