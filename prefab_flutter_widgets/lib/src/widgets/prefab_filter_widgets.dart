import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../models/prefab_backend.dart';

/// One choice of a [PrefabEnumFilter].
class PrefabFilterOption {
  const PrefabFilterOption({required this.value, required this.label});

  /// What is sent to the backend.
  final String value;

  /// What the user sees.
  final String label;
}

/// A labelled row of choice chips: one chip per option, tapping the selected
/// chip clears the filter. Used by generated list screens for enum fields
/// marked `@Field(filterable: true)`.
class PrefabEnumFilter extends StatelessWidget {
  const PrefabEnumFilter({
    super.key,
    required this.label,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  final String label;
  final List<PrefabFilterOption> options;

  /// The selected option's value, or `null`.
  final String? selected;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        for (final option in options)
          ChoiceChip(
            label: Text(option.label),
            selected: option.value == selected,
            onSelected: (on) => onChanged(on ? option.value : null),
          ),
      ],
    );
  }
}

/// A labelled Yes / No toggle; tapping the selected chip clears the filter.
/// Used for bool fields.
class PrefabBoolFilter extends StatelessWidget {
  const PrefabBoolFilter({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.yesLabel = 'Yes',
    this.noLabel = 'No',
  });

  final String label;
  final bool? value;
  final ValueChanged<bool?> onChanged;
  final String yesLabel;
  final String noLabel;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        ChoiceChip(
          label: Text(yesLabel),
          selected: value == true,
          onSelected: (on) => onChanged(on ? true : null),
        ),
        ChoiceChip(
          label: Text(noLabel),
          selected: value == false,
          onSelected: (on) => onChanged(on ? false : null),
        ),
      ],
    );
  }
}

/// A button that opens a date range picker, with a clear button once a range
/// is chosen. Used for date fields.
class PrefabDateRangeFilter extends StatelessWidget {
  const PrefabDateRangeFilter({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final PrefabDateRange? value;
  final ValueChanged<PrefabDateRange?> onChanged;

  static String _format(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final range = value;
    final text = range == null
        ? label
        : '$label: ${range.start == null ? '…' : _format(range.start!)}'
            ' – ${range.end == null ? '…' : _format(range.end!)}';
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        OutlinedButton.icon(
          icon: const Icon(Icons.date_range),
          label: Text(text),
          onPressed: () async {
            final picked = await showDateRangePicker(
              context: context,
              firstDate: DateTime(1900),
              lastDate: DateTime(2200),
              initialDateRange: range?.start != null && range?.end != null
                  ? DateTimeRange(start: range!.start!, end: range.end!)
                  : null,
            );
            if (picked != null) {
              onChanged(PrefabDateRange(start: picked.start, end: picked.end));
            }
          },
        ),
        if (range != null)
          IconButton(
            icon: const Icon(Icons.clear),
            tooltip: 'Clear $label',
            onPressed: () => onChanged(null),
          ),
      ],
    );
  }
}

/// A text field that applies its text after a short pause, with suggestions
/// from [suggest] when given (the backend's autocomplete endpoint). Used for
/// text fields.
class PrefabTextFilter extends StatefulWidget {
  const PrefabTextFilter({
    super.key,
    required this.label,
    required this.initialValue,
    required this.onChanged,
    this.suggest,
  });

  final String label;
  final String initialValue;

  /// Called with the text (empty clears the filter) after a pause in typing
  /// or when a suggestion is chosen.
  final ValueChanged<String> onChanged;

  /// Looks up suggestions for the typed text; `null` shows none.
  final Future<List<String>> Function(String text)? suggest;

  @override
  State<PrefabTextFilter> createState() => _PrefabTextFilterState();
}

class _PrefabTextFilterState extends State<PrefabTextFilter> {
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _changed(String text) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 300),
      () => widget.onChanged(text),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      child: Autocomplete<String>(
        initialValue: TextEditingValue(text: widget.initialValue),
        optionsBuilder: (value) async {
          final suggest = widget.suggest;
          if (suggest == null || value.text.isEmpty) return const [];
          return suggest(value.text);
        },
        onSelected: (text) {
          _debounce?.cancel();
          widget.onChanged(text);
        },
        fieldViewBuilder: (context, controller, focusNode, onSubmitted) =>
            TextField(
          controller: controller,
          focusNode: focusNode,
          onChanged: _changed,
          decoration: InputDecoration(
            labelText: widget.label,
            border: const OutlineInputBorder(),
            isDense: true,
          ),
        ),
      ),
    );
  }
}
