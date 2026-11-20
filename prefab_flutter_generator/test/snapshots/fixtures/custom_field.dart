import 'package:prefab_flutter/prefab_flutter.dart';

/// Stand-ins for hand-written widgets (the snapshot is never compiled).
class ColorField {
  const ColorField({
    super.key,
    required this.initialValue,
    required this.onChanged,
    required this.label,
    this.validator,
  });
  final int? initialValue;
  final void Function(int?) onChanged;
  final String label;
  final String? Function(int?)? validator;
}

class ColorSwatch {
  const ColorSwatch({super.key, required this.value});
  final int? value;
}

@Entity(title: 'Theme', path: 'themes')
@Create()
@Update()
class AppTheme {
  final int? id;

  @Field(label: 'Name')
  final String name;

  @Field(
    label: 'Accent colour',
    form: FormOptions(builder: ColorField.new, validators: [Validator.required]),
    displayBuilder: ColorSwatch.new,
  )
  final int accent;

  @Field(form: FormOptions(builder: ColorField.new), displayBuilder: ColorSwatch.new)
  final int? highlight;

  AppTheme({
    this.id,
    required this.name,
    required this.accent,
    this.highlight,
  });

  factory AppTheme.fromJson(Map<String, dynamic> json) => throw 0;
  Map<String, dynamic> toJson() => {};
}
