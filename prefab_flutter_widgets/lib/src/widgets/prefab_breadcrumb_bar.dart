import 'package:material_ui/material_ui.dart';

/// One step of a [PrefabBreadcrumbBar].
class PrefabBreadcrumb {
  /// Text shown for this step.
  final String label;

  /// Called when the step is tapped; `null` for the current (last) step.
  final VoidCallback? onTap;

  const PrefabBreadcrumb({required this.label, this.onTap});
}

/// A single-line breadcrumb row for use as `AppBar.bottom`.
///
/// Shows the [items] separated by chevrons and scrolls horizontally when they
/// do not fit. Items with an `onTap` are tappable so users can jump back to
/// any ancestor.
class PrefabBreadcrumbBar extends StatelessWidget
    implements PreferredSizeWidget {
  /// The steps, outermost ancestor first.
  final List<PrefabBreadcrumb> items;

  const PrefabBreadcrumbBar({super.key, required this.items});

  @override
  Size get preferredSize => const Size.fromHeight(40);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final children = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      if (i > 0) {
        children.add(const Icon(Icons.chevron_right, size: 16));
      }
      final isLast = i == items.length - 1;
      final text = Text(
        item.label,
        style: item.onTap == null
            ? theme.textTheme.bodyMedium
                ?.copyWith(fontWeight: isLast ? FontWeight.bold : null)
            : theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.primary,
                decoration: TextDecoration.underline,
              ),
      );
      children.add(
        item.onTap == null
            ? text
            : InkWell(onTap: item.onTap, child: text),
      );
    }
    return SizedBox(
      height: preferredSize.height,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(children: children),
      ),
    );
  }
}
