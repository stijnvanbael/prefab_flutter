import 'package:material_ui/material_ui.dart';

/// The dialog of an edit conflict: the server answered `409 Conflict` because
/// someone else changed the entity after it was loaded.
///
/// Pops `true` to reload the latest version (the input is discarded) and
/// `false` to cancel and keep the form as it is.
class PrefabConflictDialog extends StatelessWidget {
  const PrefabConflictDialog({super.key, this.title, this.message});

  /// Optional title override. Defaults to "Changed by someone else".
  final String? title;

  /// Optional message override.
  final String? message;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title ?? 'Changed by someone else'),
      content: Text(
        message ??
            'This item was changed by someone else since you opened it. '
                'Reload to get the latest version (your changes in the form '
                'are discarded) or cancel to keep editing.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Reload'),
        ),
      ],
    );
  }
}

/// Shows a [PrefabConflictDialog] and returns `true` when the user chose to
/// reload the latest version.
Future<bool> showPrefabConflictDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (_) => const PrefabConflictDialog(),
  );
  return result ?? false;
}
