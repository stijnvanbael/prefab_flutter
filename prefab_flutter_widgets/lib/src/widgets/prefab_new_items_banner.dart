import 'package:material_ui/material_ui.dart';

/// A banner telling that [count] items were created on the server that the
/// list does not show (they do not belong on the current page or in the
/// current search or sort), with a button to reload the list. Generated list
/// screens of `@Streaming` entities show it from `PrefabPage.newItems`.
class PrefabNewItemsBanner extends StatelessWidget {
  /// How many items are not shown.
  final int count;

  /// Called when the user asks to reload the list.
  final VoidCallback onRefresh;

  const PrefabNewItemsBanner({
    super.key,
    required this.count,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.secondaryContainer,
      child: ListTile(
        dense: true,
        leading: Icon(Icons.fiber_new, color: colors.onSecondaryContainer),
        title: Text(
          count == 1 ? '1 new item' : '$count new items',
          style: TextStyle(color: colors.onSecondaryContainer),
        ),
        trailing: TextButton(
          onPressed: onRefresh,
          child: const Text('Refresh'),
        ),
      ),
    );
  }
}
