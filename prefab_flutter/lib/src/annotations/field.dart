import '../enums/field_widget.dart';
import '../enums/form_mode.dart';
import '../enums/place.dart';
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
  final Function? builder;

  /// The forms the field appears in: `{FormMode.create}` for a field that can
  /// only be set at creation, `{FormMode.update}` for one that can only be
  /// changed afterwards. `null` (the default) means both. The create and the
  /// update request carry the field only in the modes it is in.
  final Set<FormMode>? on;

  const FormOptions({
    this.widget = FieldWidget.auto,
    this.validators = const [],
    this.builder,
    this.on,
  });
}

/// Marks a field of an [Entity] for use in the generated list, detail and
/// form screens.
///
/// Display and listing settings (label, places, searching, sorting) live
/// directly on [Field]; form-only settings live in [form].
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

  /// When `true` the generated list screen shows a search bar and the field
  /// is included in the server-side search (the `q` query parameter).
  final bool searchable;

  /// When `true` the generated list screen offers this field in its sort menu.
  final bool sortable;

  /// Form-only settings (widget and validators).
  final FormOptions form;

  /// The places the field appears in: [Place.item], [Place.detail] and
  /// [Place.form]. `null` (the default) means every place; an empty set
  /// keeps the field in the model but shows it nowhere.
  final Set<Place>? on;

  /// A hand-written widget that shows the value in the detail screen and the
  /// list tile instead of its `toString()`, as a constant constructor tear-off
  /// or top-level function (`ColorSwatch.new`). It must take the named
  /// parameter `value` and may take `key` (the `PrefabDisplayBuilder`
  /// contract of `prefab_flutter_widgets`).
  final Function? displayBuilder;

  /// A value the server computes or owns (timestamps, status, totals). The
  /// field is shown in the list and detail screens but is never in a form and
  /// never in the body of a create or update request.
  final bool readOnly;

  const Field({
    this.label,
    this.on,
    this.searchable = false,
    this.sortable = false,
    this.form = const FormOptions(),
    this.displayBuilder,
    this.readOnly = false,
  });
}
