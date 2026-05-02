import 'package:flutter/material.dart';

/// A search input bar that notifies listeners whenever the query changes.
///
/// Wrap this widget in the app bar or body of a list screen to provide
/// live-filter functionality to generated list screens.
///
/// Example:
/// ```dart
/// PrefabSearchBar(
///   onChanged: (query) => ref.read(searchProvider.notifier).state = query,
/// )
/// ```
class PrefabSearchBar extends StatefulWidget {
  /// Called with the current search string every time the user edits the field.
  final ValueChanged<String>? onChanged;

  /// Placeholder text shown when the search field is empty.
  final String hintText;

  /// Initial value of the search field.
  final String initialValue;

  const PrefabSearchBar({
    super.key,
    this.onChanged,
    this.hintText = 'Search…',
    this.initialValue = '',
  });

  @override
  State<PrefabSearchBar> createState() => _PrefabSearchBarState();
}

class _PrefabSearchBarState extends State<PrefabSearchBar> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      onChanged: widget.onChanged,
      decoration: InputDecoration(
        hintText: widget.hintText,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                tooltip: 'Clear search',
                onPressed: () {
                  _controller.clear();
                  widget.onChanged?.call('');
                },
              )
            : null,
        border: const OutlineInputBorder(),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
      ),
    );
  }
}
