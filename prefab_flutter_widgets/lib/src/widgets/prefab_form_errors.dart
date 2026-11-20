import 'package:material_ui/material_ui.dart';

import '../models/prefab_api_error.dart';

/// The server errors of one generated form: a message per field (by JSON
/// name) and the messages that belong to no field of the form.
class PrefabFormErrors extends ChangeNotifier {
  final _fields = <String, String>{};
  final _focus = <String, FocusNode>{};
  String? _general;
  final _unmatched = <String>[];

  /// The message of the field with this JSON name.
  String? fieldError(String field) => _fields[field];

  /// The general message and the messages of fields the form does not have,
  /// shown above the form.
  List<String> get generalMessages => [
        if (_general != null) _general!,
        ..._unmatched,
      ];

  bool get isEmpty => _fields.isEmpty && generalMessages.isEmpty;

  /// Replaces the errors with [error]. Entries of [PrefabApiError.fieldErrors]
  /// for a JSON name in [knownFields] are shown under that field, the others
  /// above the form.
  void setError(PrefabApiError error, Set<String> knownFields) {
    _fields.clear();
    _unmatched.clear();
    _general = error.message;
    error.fieldErrors.forEach((field, message) {
      if (knownFields.contains(field)) {
        _fields[field] = message;
      } else {
        _unmatched.add('$field: $message');
      }
    });
    notifyListeners();
  }

  /// Removes every error (before a new save).
  void clear() {
    if (isEmpty) return;
    _fields.clear();
    _unmatched.clear();
    _general = null;
    notifyListeners();
  }

  /// Removes the field errors of the fields that have the focus; called when
  /// the form changes, i.e. when the user edits a field.
  void clearEdited() {
    final edited = [
      for (final e in _focus.entries)
        if (e.value.hasFocus && _fields.containsKey(e.key)) e.key,
    ];
    if (edited.isEmpty) return;
    edited.forEach(_fields.remove);
    notifyListeners();
  }
}

/// Wraps the widgets of one form field and shows the server error of the
/// field below them until the user edits the field.
class PrefabFieldError extends StatefulWidget {
  const PrefabFieldError({
    super.key,
    required this.errors,
    required this.field,
    required this.children,
  });

  final PrefabFormErrors errors;

  /// The JSON name of the field.
  final String field;
  final List<Widget> children;

  @override
  State<PrefabFieldError> createState() => _PrefabFieldErrorState();
}

class _PrefabFieldErrorState extends State<PrefabFieldError> {
  final _node = FocusNode(
    debugLabel: 'PrefabFieldError',
    canRequestFocus: false,
    skipTraversal: true,
  );

  @override
  void initState() {
    super.initState();
    widget.errors._focus[widget.field] = _node;
  }

  @override
  void dispose() {
    if (widget.errors._focus[widget.field] == _node) {
      widget.errors._focus.remove(widget.field);
    }
    _node.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.errors,
      builder: (context, _) {
        final message = widget.errors.fieldError(widget.field);
        return Focus(
          focusNode: _node,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ...widget.children,
              if (message != null)
                Padding(
                  padding: const EdgeInsets.only(left: 12, top: 4, bottom: 4),
                  child: Text(
                    message,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Shows the general server messages above a form; nothing when there are
/// none.
class PrefabFormErrorBanner extends StatelessWidget {
  const PrefabFormErrorBanner({super.key, required this.errors});

  final PrefabFormErrors errors;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: errors,
      builder: (context, _) {
        final messages = errors.generalMessages;
        if (messages.isEmpty) return const SizedBox.shrink();
        final scheme = Theme.of(context).colorScheme;
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: scheme.errorContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final m in messages)
                Text(m, style: TextStyle(color: scheme.onErrorContainer)),
            ],
          ),
        );
      },
    );
  }
}
