import 'package:material_ui/material_ui.dart';

/// Builds the widget shown when a list has no items.
typedef PrefabEmptyBuilder = Widget Function(BuildContext context);

/// Builds the widget shown while data is loading.
typedef PrefabLoadingBuilder = Widget Function(BuildContext context);

/// Builds the widget shown when loading failed. [error] is what happened.
typedef PrefabErrorBuilder = Widget Function(
  BuildContext context,
  Object error,
  StackTrace? stackTrace,
);

/// Builds one labelled value of a detail screen.
typedef PrefabDetailFieldBuilder = Widget Function(
  BuildContext context,
  String label,
  Widget value,
);

/// Builds the save button of a form screen. [saving] is true while the request
/// is running (then [onPressed] is null).
typedef PrefabSaveButtonBuilder = Widget Function(
  BuildContext context,
  String label,
  VoidCallback? onPressed,
  bool saving,
);

/// Layout decisions of generated list, detail and form screens.
///
/// Set it in `ThemeData.extensions`. Screens fall back to the defaults, which
/// equal the look of the screens without a [PrefabTheme], when it is absent:
///
/// ```dart
/// MaterialApp.router(
///   theme: ThemeData(extensions: [
///     PrefabTheme(listPadding: const EdgeInsets.symmetric(vertical: 8)),
///   ]),
/// )
/// ```
@immutable
class PrefabTheme extends ThemeExtension<PrefabTheme> {
  const PrefabTheme({
    this.listPadding = EdgeInsets.zero,
    this.detailPadding = const EdgeInsets.all(16),
    this.formPadding = const EdgeInsets.all(16),
    this.emptyBuilder = defaultEmptyBuilder,
    this.loadingBuilder = defaultLoadingBuilder,
    this.errorBuilder = defaultErrorBuilder,
    this.detailFieldBuilder = defaultDetailFieldBuilder,
    this.saveButtonBuilder = defaultSaveButtonBuilder,
  });

  /// Padding around the items of list screens.
  final EdgeInsetsGeometry listPadding;

  /// Padding around the fields of detail screens.
  final EdgeInsetsGeometry detailPadding;

  /// Padding around the fields of create and edit screens.
  final EdgeInsetsGeometry formPadding;

  /// Shown by list screens without items.
  final PrefabEmptyBuilder emptyBuilder;

  /// Shown by list, detail and edit screens while loading.
  final PrefabLoadingBuilder loadingBuilder;

  /// Shown by list, detail and edit screens when loading failed.
  final PrefabErrorBuilder errorBuilder;

  /// Layout of one label and value in detail screens.
  final PrefabDetailFieldBuilder detailFieldBuilder;

  /// The save button of create and edit screens.
  final PrefabSaveButtonBuilder saveButtonBuilder;

  /// The defaults, used when no [PrefabTheme] is in the theme.
  static const PrefabTheme fallback = PrefabTheme();

  /// The [PrefabTheme] of [context], or [fallback].
  static PrefabTheme of(BuildContext context) =>
      Theme.of(context).extension<PrefabTheme>() ?? fallback;

  static Widget defaultEmptyBuilder(BuildContext context) =>
      const Center(child: Text('No items found'));

  static Widget defaultLoadingBuilder(BuildContext context) =>
      const Center(child: CircularProgressIndicator());

  static Widget defaultErrorBuilder(
          BuildContext context, Object error, StackTrace? stackTrace) =>
      Center(child: Text('Error: $error'));

  static Widget defaultDetailFieldBuilder(
          BuildContext context, String label, Widget value) =>
      ListTile(title: Text(label), subtitle: value);

  static Widget defaultSaveButtonBuilder(BuildContext context, String label,
          VoidCallback? onPressed, bool saving) =>
      ElevatedButton(
        onPressed: onPressed,
        child: saving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(label),
      );

  @override
  PrefabTheme copyWith({
    EdgeInsetsGeometry? listPadding,
    EdgeInsetsGeometry? detailPadding,
    EdgeInsetsGeometry? formPadding,
    PrefabEmptyBuilder? emptyBuilder,
    PrefabLoadingBuilder? loadingBuilder,
    PrefabErrorBuilder? errorBuilder,
    PrefabDetailFieldBuilder? detailFieldBuilder,
    PrefabSaveButtonBuilder? saveButtonBuilder,
  }) =>
      PrefabTheme(
        listPadding: listPadding ?? this.listPadding,
        detailPadding: detailPadding ?? this.detailPadding,
        formPadding: formPadding ?? this.formPadding,
        emptyBuilder: emptyBuilder ?? this.emptyBuilder,
        loadingBuilder: loadingBuilder ?? this.loadingBuilder,
        errorBuilder: errorBuilder ?? this.errorBuilder,
        detailFieldBuilder: detailFieldBuilder ?? this.detailFieldBuilder,
        saveButtonBuilder: saveButtonBuilder ?? this.saveButtonBuilder,
      );

  /// Paddings are interpolated; builders switch at `t >= 0.5`.
  @override
  PrefabTheme lerp(ThemeExtension<PrefabTheme>? other, double t) {
    if (other is! PrefabTheme) return this;
    final next = t < 0.5 ? this : other;
    return PrefabTheme(
      listPadding:
          EdgeInsetsGeometry.lerp(listPadding, other.listPadding, t)!,
      detailPadding:
          EdgeInsetsGeometry.lerp(detailPadding, other.detailPadding, t)!,
      formPadding: EdgeInsetsGeometry.lerp(formPadding, other.formPadding, t)!,
      emptyBuilder: next.emptyBuilder,
      loadingBuilder: next.loadingBuilder,
      errorBuilder: next.errorBuilder,
      detailFieldBuilder: next.detailFieldBuilder,
      saveButtonBuilder: next.saveButtonBuilder,
    );
  }
}
