import 'package:flutter/material.dart';

/// Describes a single sort option available inside [PrefabSortMenu].
class PrefabSortOption<T> {
  /// Unique identifier / key for this sort option.
  final String id;

  /// Human-readable label shown in the menu.
  final String label;

  /// Optional icon shown next to the label.
  final IconData? icon;

  const PrefabSortOption({
    required this.id,
    required this.label,
    this.icon,
  });
}

/// A pop-up sort menu widget for list screens.
///
/// Displays the currently selected sort option on the button and a
/// [PopupMenuButton] with all available options. Calls [onSortChanged]
/// whenever the user selects a different option.
///
/// Example:
/// ```dart
/// PrefabSortMenu<Product>(
///   options: const [
///     PrefabSortOption(id: 'name_asc',  label: 'Name (A → Z)', icon: Icons.arrow_upward),
///     PrefabSortOption(id: 'name_desc', label: 'Name (Z → A)', icon: Icons.arrow_downward),
///     PrefabSortOption(id: 'price_asc', label: 'Price (low → high)'),
///   ],
///   selectedId: currentSort,
///   onSortChanged: (option) => ref.read(sortProvider.notifier).state = option.id,
/// )
/// ```
class PrefabSortMenu<T> extends StatelessWidget {
  /// All available sort options.
  final List<PrefabSortOption<T>> options;

  /// The [PrefabSortOption.id] of the currently active sort.
  final String? selectedId;

  /// Called when the user picks a different sort option.
  final ValueChanged<PrefabSortOption<T>>? onSortChanged;

  /// Tooltip shown on the menu button.
  final String tooltip;

  const PrefabSortMenu({
    super.key,
    required this.options,
    this.selectedId,
    this.onSortChanged,
    this.tooltip = 'Sort',
  });

  PrefabSortOption<T>? get _selected =>
      options.where((o) => o.id == selectedId).firstOrNull;

  @override
  Widget build(BuildContext context) {
    final selected = _selected;

    return PopupMenuButton<PrefabSortOption<T>>(
      tooltip: tooltip,
      icon: const Icon(Icons.sort),
      onSelected: onSortChanged,
      itemBuilder: (context) => options.map((option) {
        final isSelected = option.id == selectedId;
        return PopupMenuItem<PrefabSortOption<T>>(
          value: option,
          child: Row(
            children: [
              if (option.icon != null) ...[
                Icon(
                  option.icon,
                  size: 18,
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  option.label,
                  style: isSelected
                      ? TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        )
                      : null,
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
            ],
          ),
        );
      }).toList(),
      child: selected != null
          ? Chip(
              avatar: selected.icon != null ? Icon(selected.icon, size: 16) : null,
              label: Text(selected.label),
            )
          : null,
    );
  }
}
