import 'package:material_ui/material_ui.dart';

import '../models/prefab_backend.dart';

/// Runs a named operation (`@Update(path: ...)` without parameters) started
/// from a generated screen.
///
/// Asks for confirmation first when [confirm] is set, runs [run], and shows
/// the problem of a failed request (its Problem Details message, see
/// [PrefabBackend.parseError]) in a snack bar. Returns `true` when the
/// operation ran, `false` when the user cancelled or it failed.
Future<bool> runPrefabOperation({
  required BuildContext context,
  required PrefabBackend backend,
  required String label,
  required Future<void> Function() run,
  String? confirm,
}) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (confirm != null) {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(label),
        content: Text(confirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(label),
          ),
        ],
      ),
    );
    if (confirmed != true) return false;
  }
  try {
    await run();
    return true;
  } catch (error) {
    messenger?.showSnackBar(
      SnackBar(content: Text(backend.parseError(error).toString())),
    );
    return false;
  }
}
