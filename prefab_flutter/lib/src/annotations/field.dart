import '../enums/field_widget.dart';
import '../enums/validator.dart';

/// Form-only settings of a [Field], passed as [Field.form].
///
/// Example:
/// ```dart
/// @Field(form: FormOptions(validators: [Validator.required]))
/// final String name;
/// ```
class FormOptions {
  /// Widget hint for the form-screen generator.
  final FieldWidget widget;

  /// Validation rules applied to this field in the form screen.
  final List<Validator> validators;

  /// A hand-written form widget for this field, as a constant constructor
  /// tear-off or top-level function (`ColorField.new`). It replaces the
  /// generated widget; [widget] is then ignored.
  ///
  /// The reference must take the named parameters `initialValue`, `onChanged`
  /// and `label`, and may take `validator` and `key` (the `PrefabFieldBuilder`
  /// contract of `prefab_flutter_widgets`). Only [Validator.required] can be
  /// combined with it.
  final Function? custom;

  const FormOptions({
    this.widget = FieldWidget.auto,
    this.validators = const [],
    this.custom,
  });
}

/// Marks a field on a [@View] entity for inclusion in the generated list,
/// detail and form screens.
///
/// Display and listing concerns (label, visibility, and later searching,
/// sorting and views) live directly on [Field]; form-only settings live in
/// [form].
///
/// Example:
/// ```dart
/// @Field(label: 'Product name', form: FormOptions(validators: [Validator.required]))
/// final String name;
/// ```
class Field {
  /// Human-readable label shown next to the field. Defaults to the field name
  /// converted to title case when omitted (`firstName` → `First Name`).
  final String? label;

  /// When `true` the field is excluded from both the form and detail screens.
  final bool hidden;

  /// When `true` the generated list screen shows a search bar and the field
  /// is included in the server-side search (the `q` query parameter).
  final bool searchable;

  /// When `true` the generated list screen offers this field in its sort menu.
  final bool sortable;

  /// Form-only settings (widget and validators).
  final FormOptions form;

  /// Names of the views the field appears in (`'list'`, `'detail'`).
  /// `null` (the default) means the field appears in all views.
  final Set<String>? views;

  /// A hand-written widget that shows the value in the detail screen and the
  /// list tile instead of its `toString()`, as a constant constructor tear-off
  /// or top-level function (`ColorSwatch.new`). It must take the named
  /// parameter `value` and may take `key` (the `PrefabDisplayBuilder`
  /// contract of `prefab_flutter_widgets`).
  final Function? display;

  const Field({
    this.label,
    this.hidden = false,
    this.views,
    this.searchable = false,
    this.sortable = false,
    this.form = const FormOptions(),
    this.display,
  });
}

/// Deprecated predecessor of [Field].
///
/// Equivalent to `@Field(label: ..., hidden: ..., form: FormOptions(widget:
/// ..., validators: ...))`. Kept for one release.
@Deprecated('Use @Field (with form: FormOptions(...)) instead.')
class FormField {
  final String? label;
  final FieldWidget widget;
  final List<Validator> validators;
  final bool hidden;

  const FormField({
    this.label,
    this.widget = FieldWidget.auto,
    this.validators = const [],
    this.hidden = false,
  });
}
