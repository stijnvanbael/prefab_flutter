import 'package:analyzer/dart/element/element.dart';
import 'package:prefab_flutter/prefab_flutter.dart';
import 'package:source_gen/source_gen.dart';

import 'field_manifest.dart';

const _updateChecker = TypeChecker.fromRuntime(Update);
const _deleteChecker = TypeChecker.fromRuntime(Delete);
const _formFieldChecker = TypeChecker.fromRuntime(FormField);
const _parentChecker = TypeChecker.fromRuntime(Parent);

/// Summarises everything the generators need to know about a single
/// [@View]-annotated entity class.
class EntityManifest {
  /// Dart class name (e.g. `'Product'`).
  final String entityName;

  /// Lower-camel-case version of [entityName] (e.g. `'product'`).
  final String entityNameLower;

  /// Human-readable title from [@View.title].
  final String title;

  /// URL path segment from [@View.path] (e.g. `'products'`).
  final String path;

  /// Whether the entity class carries the [@Update] annotation.
  final bool hasUpdate;

  /// Whether the entity class carries the [@Delete] annotation.
  final bool hasDelete;

  /// All fields declared with [@FormField] in source order.
  final List<FieldManifest> fields;

  EntityManifest({
    required this.entityName,
    required this.title,
    required this.path,
    required this.hasUpdate,
    required this.hasDelete,
    required this.fields,
  }) : entityNameLower = _toLowerCamel(entityName);

  // ---------------------------------------------------------------------------
  // Convenience accessors used by generators
  // ---------------------------------------------------------------------------

  /// All fields that should appear in the detail screen (non-hidden, non-parent).
  List<FieldManifest> get visibleFields =>
      fields.where((f) => !f.hidden && !f.isParent).toList();

  /// All fields that should appear in the form screen (non-hidden, non-parent).
  List<FieldManifest> get formFields => visibleFields;

  /// Name of the first visible field, used as the item label in delete dialogs.
  /// Falls back to `'id'` when no visible fields are declared.
  String get firstLabelFieldName =>
      visibleFields.isNotEmpty ? visibleFields.first.name : 'id';

  // ---------------------------------------------------------------------------
  // Factory
  // ---------------------------------------------------------------------------

  /// Builds an [EntityManifest] from the class element and the already-read
  /// [@View] annotation.
  static EntityManifest from(
    ClassElement element,
    ConstantReader viewAnnotation,
  ) {
    final title = viewAnnotation.read('title').stringValue;
    final path = viewAnnotation.read('path').stringValue;

    final hasUpdate = _updateChecker.hasAnnotationOf(element);
    final hasDelete = _deleteChecker.hasAnnotationOf(element);

    final fields = <FieldManifest>[];
    for (final field in element.fields) {
      if (field.isStatic || field.isSynthetic) continue;

      final formFieldAnnotation = _formFieldChecker.firstAnnotationOf(field);
      if (formFieldAnnotation == null) continue;

      final reader = ConstantReader(formFieldAnnotation);

      final labelReader = reader.read('label');
      final label = labelReader.isNull
          ? _fieldNameToLabel(field.name)
          : labelReader.stringValue;

      final hidden = reader.read('hidden').boolValue;
      final isParent = _parentChecker.hasAnnotationOf(field);

      final validatorsObjList = reader.read('validators').listValue;
      final validators = validatorsObjList
          .map((obj) {
            final name = obj.variable?.name;
            if (name == null) return null;
            try {
              return Validator.values.byName(name);
            } catch (_) {
              return null;
            }
          })
          .whereType<Validator>()
          .toList();

      final widgetName = reader.read('widget').objectValue.variable?.name;
      final fieldWidget = widgetName != null
          ? FieldWidget.values.byName(widgetName)
          : FieldWidget.auto;

      final isEnum = field.type.element is EnumElement;

      fields.add(FieldManifest(
        name: field.name,
        label: label,
        hidden: hidden,
        isParent: isParent,
        dartType: field.type.getDisplayString(withNullability: false),
        validators: validators,
        fieldWidget: fieldWidget,
        isEnum: isEnum,
      ));
    }

    return EntityManifest(
      entityName: element.name,
      title: title,
      path: path,
      hasUpdate: hasUpdate,
      hasDelete: hasDelete,
      fields: fields,
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  static String _toLowerCamel(String name) {
    if (name.isEmpty) return name;
    return name[0].toLowerCase() + name.substring(1);
  }

  /// Converts a camelCase field name to a human-readable Title Case label.
  ///
  /// Examples:
  /// - `'firstName'` → `'First Name'`
  /// - `'price'`     → `'Price'`
  static String _fieldNameToLabel(String fieldName) {
    final withSpaces = fieldName.replaceAllMapped(
      RegExp(r'([A-Z])'),
      (m) => ' ${m[0]}',
    );
    return withSpaces.trim().split(' ').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }
}
