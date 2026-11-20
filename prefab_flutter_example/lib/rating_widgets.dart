import 'package:material_ui/material_ui.dart';

/// A hand-written form widget for `Review.quality` (PF-65): one to five stars.
/// It follows the `PrefabFieldBuilder<int>` contract of
/// `prefab_flutter_widgets`.
class RatingField extends StatefulWidget {
  const RatingField({
    super.key,
    required this.initialValue,
    required this.onChanged,
    required this.label,
    this.validator,
  });

  final int? initialValue;
  final ValueChanged<int?> onChanged;
  final String label;
  final String? Function(int?)? validator;

  @override
  State<RatingField> createState() => _RatingFieldState();
}

class _RatingFieldState extends State<RatingField> {
  late int? _value = widget.initialValue;

  @override
  Widget build(BuildContext context) {
    return FormField<int>(
      initialValue: widget.initialValue,
      validator: widget.validator,
      builder: (state) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(widget.label),
              const SizedBox(width: 16),
              for (var star = 1; star <= 5; star++)
                IconButton(
                  key: Key('rating-$star'),
                  icon: Icon(
                    (_value ?? 0) >= star ? Icons.star : Icons.star_border,
                  ),
                  onPressed: () {
                    // Tapping the current rating clears it.
                    final next = _value == star ? null : star;
                    setState(() => _value = next);
                    state.didChange(next);
                    widget.onChanged(next);
                  },
                ),
            ],
          ),
          if (state.hasError)
            Text(state.errorText!,
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ],
      ),
    );
  }
}

/// A hand-written display widget for `Review.quality` (PF-65), following the
/// `PrefabDisplayBuilder<int?>` contract.
class RatingStars extends StatelessWidget {
  const RatingStars({super.key, required this.value});

  final int? value;

  @override
  Widget build(BuildContext context) =>
      Text(value == null ? 'Not rated' : '★' * value!);
}
