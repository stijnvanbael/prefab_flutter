import 'package:material_ui/material_ui.dart';

import '../models/prefab_job.dart';

/// The state of a job as a small indicator for a list item: a progress
/// indicator while it [PrefabJobState.running], a check mark when it is
/// [PrefabJobState.done] and an error icon when it [PrefabJobState.failed].
/// Generated list screens of `@JobStatus` entities show it in front of the
/// item's trailing widget.
class PrefabJobIndicator extends StatelessWidget {
  /// The state to show.
  final PrefabJobState state;

  const PrefabJobIndicator({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    switch (state) {
      case PrefabJobState.running:
        return const Tooltip(
          message: 'Running',
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      case PrefabJobState.done:
        return Tooltip(
          message: 'Done',
          child: Icon(Icons.check_circle, color: colors.primary),
        );
      case PrefabJobState.failed:
        return Tooltip(
          message: 'Failed',
          child: Icon(Icons.error, color: colors.error),
        );
    }
  }
}

/// The state of a job at the top of a detail screen: a progress bar while it
/// is running, a confirmation when it is done and, when it failed, the
/// server's [message]. Generated detail screens of `@JobStatus` entities show
/// it above the fields.
class PrefabJobBanner extends StatelessWidget {
  /// The state to show.
  final PrefabJobState state;

  /// The failure message of the server, shown for a failed job.
  final String? message;

  const PrefabJobBanner({super.key, required this.state, this.message});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    switch (state) {
      case PrefabJobState.running:
        return Material(
          color: colors.secondaryContainer,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                dense: true,
                leading: Icon(Icons.hourglass_top,
                    color: colors.onSecondaryContainer),
                title: Text('Running',
                    style: TextStyle(color: colors.onSecondaryContainer)),
              ),
              const LinearProgressIndicator(),
            ],
          ),
        );
      case PrefabJobState.done:
        return Material(
          color: colors.primaryContainer,
          child: ListTile(
            dense: true,
            leading:
                Icon(Icons.check_circle, color: colors.onPrimaryContainer),
            title: Text('Done',
                style: TextStyle(color: colors.onPrimaryContainer)),
          ),
        );
      case PrefabJobState.failed:
        final text = message;
        return Material(
          color: colors.errorContainer,
          child: ListTile(
            dense: true,
            leading: Icon(Icons.error, color: colors.onErrorContainer),
            title: Text('Failed',
                style: TextStyle(color: colors.onErrorContainer)),
            subtitle: text == null || text.isEmpty
                ? null
                : Text(text, style: TextStyle(color: colors.onErrorContainer)),
          ),
        );
    }
  }
}
