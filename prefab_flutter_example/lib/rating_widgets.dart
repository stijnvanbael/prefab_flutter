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
  });

  final int? initialValue;
  final ValueChanged<int?> onChanged;
  final String label;

  @override
  State<RatingField> createState() => _RatingFieldState();
}

class _RatingFieldState extends State<RatingField> {
  late int? _value = widget.initialValue;

  @override
  Widget build(BuildContext context) {
    return Row(
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
              widget.onChanged(next);
            },
          ),
      ],
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
