import 'package:flutter/material.dart';

/// A generic confirmation dialog used before deleting an entity.
///
/// Returns `true` when the user confirms deletion and `false` (or `null`)
/// when they cancel.
///
/// Example:
/// ```dart
/// final confirmed = await showDialog<bool>(
///   context: context,
///   builder: (_) => PrefabDeleteDialog<Product>(
///     item: product,
///     itemLabel: product.name,
///     onDelete: () => ref.read(productsProvider.notifier).delete(product),
///   ),
/// );
/// ```
class PrefabDeleteDialog<T> extends StatelessWidget {
  /// The entity that will be deleted.
  final T item;

  /// Human-readable label for [item] shown inside the dialog.
  final String itemLabel;

  /// Async callback executed when the user confirms the deletion.
  /// The dialog is closed with `true` after this completes.
  final Future<void> Function()? onDelete;

  /// Optional title override. Defaults to "Delete [itemLabel]?".
  final String? title;

  const PrefabDeleteDialog({
    super.key,
    required this.item,
    required this.itemLabel,
    this.onDelete,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title ?? 'Delete $itemLabel?'),
      content: Text('Are you sure you want to delete "$itemLabel"? '
          'This action cannot be undone.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
          ),
          onPressed: () async {
            await onDelete?.call();
            if (context.mounted) {
              Navigator.of(context).pop(true);
            }
          },
          child: const Text('Delete'),
        ),
      ],
    );
  }
}

/// Convenience function to show a [PrefabDeleteDialog] and await the result.
///
/// Returns `true` if the user confirmed, `false` otherwise.
Future<bool> showPrefabDeleteDialog<T>({
  required BuildContext context,
  required T item,
  required String itemLabel,
  Future<void> Function()? onDelete,
  String? title,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (_) => PrefabDeleteDialog<T>(
      item: item,
      itemLabel: itemLabel,
      onDelete: onDelete,
      title: title,
    ),
  );
  return result ?? false;
}
