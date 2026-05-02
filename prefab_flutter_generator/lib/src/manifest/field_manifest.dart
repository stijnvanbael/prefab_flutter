/// Describes a single field on an entity class as understood by the generators.
class FieldManifest {
  /// Dart field name (e.g. `'firstName'`).
  final String name;

  /// Human-readable label (from [@FormField.label] or derived from [name]).
  final String label;

  /// When `true` the field is excluded from form and detail screens.
  final bool hidden;

  /// When `true` the field references a parent entity (annotated with [@Parent]).
  final bool isParent;

  /// Dart type display string (e.g. `'String'`, `'int'`, `'bool'`).
  final String dartType;

  const FieldManifest({
    required this.name,
    required this.label,
    required this.hidden,
    required this.isParent,
    required this.dartType,
  });
}
