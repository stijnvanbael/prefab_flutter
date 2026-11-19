import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:prefab_flutter/prefab_flutter.dart';
import 'package:source_gen/source_gen.dart';

import 'field_manifest.dart';

const _createChecker = TypeChecker.fromRuntime(Create);
const _updateChecker = TypeChecker.fromRuntime(Update);
const _deleteChecker = TypeChecker.fromRuntime(Delete);
const _fieldChecker = TypeChecker.fromRuntime(Field);
// ignore: deprecated_member_use
const _formFieldChecker = TypeChecker.fromRuntime(FormField);
const _idChecker = TypeChecker.fromRuntime(Id);
const _viewChecker = TypeChecker.fromRuntime(View);
const _parentChecker = TypeChecker.fromRuntime(Parent);

/// A parameter of the entity's unnamed constructor.
class ConstructorParam {
  /// Parameter name (matches the field it initialises).
  final String name;

  /// Whether the parameter is a named parameter.
  final bool isNamed;

  /// Whether the caller must supply a value (required, non-defaulted).
  final bool isRequired;

  /// Whether the parameter type is nullable.
  final bool isNullable;

  /// Whether the parameter declares a default value.
  final bool hasDefault;

  const ConstructorParam({
    required this.name,
    required this.isNamed,
    required this.isRequired,
    required this.isNullable,
    required this.hasDefault,
  });

  /// Whether the parameter may be left out (or passed `null`) on create.
  bool get isOptional => !isRequired;
}

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

  /// Whether the entity class carries the [@Create] annotation.
  final bool hasCreate;

  /// Whether the entity class carries the [@Update] annotation.
  final bool hasUpdate;

  /// Whether the entity class carries the [@Delete] annotation.
  final bool hasDelete;

  /// All fields declared with [@Field] (or the deprecated [@FormField]) in source order.
  final List<FieldManifest> fields;

  /// Name of the identifier field (the [@Id] field, or `id`).
  final String idFieldName;

  /// Dart type of the identifier field (e.g. `'String'` or `'int'`).
  final String idType;

  /// Whether the identifier field is nullable (e.g. `int? id`).
  final bool idIsNullable;

  /// Dart expression suffix that makes an id access non-null (`!` or empty).
  String get idBang => idIsNullable ? '!' : '';

  /// Class name of the parent entity named in `@Parent(Type)`, or `null`.
  final String? parentEntityName;

  /// URL path of the parent entity (from the parent's `@View.path`).
  final String? parentPath;

  /// Title of the parent entity (from the parent's `@View.title`).
  final String? parentTitle;

  /// Dart type of the parent's `id` field (e.g. `'int'`).
  final String? parentIdType;

  /// Whether the parent is declared in the same library as this entity.
  final bool parentInSameLibrary;

  /// Parameters of the unnamed constructor, or `null` when the class has none.
  final List<ConstructorParam>? constructorParams;

  /// Whether the list is paged server-side ([@View.paged]).
  final bool paged;

  EntityManifest({
    required this.entityName,
    required this.title,
    required this.path,
    required this.hasCreate,
    required this.hasUpdate,
    required this.hasDelete,
    required this.fields,
    this.idFieldName = 'id',
    this.idType = 'String',
    this.idIsNullable = false,
    this.parentEntityName,
    this.parentPath,
    this.parentTitle,
    this.parentIdType,
    this.parentInSameLibrary = true,
    this.constructorParams,
    this.paged = true,
  }) : entityNameLower = _toLowerCamel(entityName);

  // ---------------------------------------------------------------------------
  // Convenience accessors used by generators
  // ---------------------------------------------------------------------------

  /// All fields that should appear in the detail screen (non-hidden, non-parent).
  List<FieldManifest> get visibleFields =>
      fields.where((f) => !f.hidden && !f.isParent).toList();

  /// Visible fields that appear in the view named [viewName]; fields without
  /// a `views` set appear in every view.
  List<FieldManifest> fieldsForView(String viewName) =>
      visibleFields.where((f) => f.inView(viewName)).toList();

  /// Whether any field declares a `views` set.
  bool get hasViews => fields.any((f) => f.views != null);

  /// All fields that should appear in the form screen (non-hidden, non-parent).
  List<FieldManifest> get formFields => visibleFields;

  /// Visible fields that take part in the list search.
  List<FieldManifest> get searchableFields =>
      visibleFields.where((f) => f.searchable).toList();

  /// Visible fields offered in the list sort menu.
  List<FieldManifest> get sortableFields =>
      visibleFields.where((f) => f.sortable).toList();

  /// Whether the list screen shows a search bar.
  bool get hasSearch => searchableFields.isNotEmpty;

  /// Whether the list screen shows a sort menu.
  bool get hasSort => sortableFields.isNotEmpty;

  /// Name of the first visible field, used as the item label in delete dialogs.
  /// Falls back to the id field when no visible fields are declared.
  String get firstLabelFieldName =>
      visibleFields.isNotEmpty ? visibleFields.first.name : idFieldName;

  /// Whether [idType] is `int`.
  bool get idIsInt => idType == 'int';

  /// Dart expression converting the string [expr] to the id type.
  String parseId(String expr) => idIsInt ? 'int.parse($expr)' : expr;

  /// Dart expression converting [expr] to the parent id type.
  String parseParentId(String expr) =>
      parentField?.dartType == 'int' ? 'int.parse($expr)' : expr;

  /// The first field annotated with [@Parent], if any.
  FieldManifest? get parentField => fields.where((f) => f.isParent).firstOrNull;

  /// Whether this entity has a parent reference.
  bool get hasParent => parentField != null;

  /// Lower-camel-case name of the parent entity named in `@Parent(Type)`.
  ///
  /// Example: `Post` → `'post'`.
  String? get parentEntityNameLower =>
      parentEntityName == null ? null : _toLowerCamel(parentEntityName!);

  /// The Dart parameter name used for the parent ID (same as the field name).
  ///
  /// Example: `'postId'`.
  String? get parentParamName => parentField?.name;

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

    final paged = viewAnnotation.peek('paged')?.boolValue ?? true;

    final hasCreate = _createChecker.hasAnnotationOf(element);
    final hasUpdate = _updateChecker.hasAnnotationOf(element);
    final hasDelete = _deleteChecker.hasAnnotationOf(element);

    // Resolve the identifier field: @Id, otherwise a field named `id`.
    final instanceFields =
        element.fields.where((f) => !f.isStatic && !f.isSynthetic).toList();
    final idFields = instanceFields.where(_idChecker.hasAnnotationOf).toList();
    if (idFields.length > 1) {
      throw InvalidGenerationSourceError(
        'Entity "${element.name}" has more than one @Id field.',
        element: element,
      );
    }
    final idField = idFields.isNotEmpty
        ? idFields.first
        : instanceFields.where((f) => f.name == 'id').firstOrNull;
    if (idField == null) {
      throw InvalidGenerationSourceError(
        'Entity "${element.name}" has no identifier. Annotate a field with '
        '@Id or name it "id".',
        element: element,
      );
    }
    final idType = idField.type.getDisplayString(withNullability: false);
    if (idType != 'String' && idType != 'int') {
      throw InvalidGenerationSourceError(
        'The id field "${idField.name}" of "${element.name}" must be of type '
        'String or int, but is $idType.',
        element: idField,
      );
    }

    final fields = <FieldManifest>[];
    ClassElement? parentElement;
    String? parentPath, parentTitle, parentIdType;
    for (final field in instanceFields) {
      if (field == idField) continue;

      final fieldAnnotation = _fieldChecker.firstAnnotationOf(field);
      final legacyAnnotation = fieldAnnotation == null
          ? _formFieldChecker.firstAnnotationOf(field)
          : null;
      final annotation = fieldAnnotation ?? legacyAnnotation;
      if (annotation == null) continue;

      final reader = ConstantReader(annotation);
      // Form-only settings: `@Field.form`, or the top level of `@FormField`.
      final formReader = fieldAnnotation != null ? reader.read('form') : reader;

      final labelReader = reader.read('label');
      final label = labelReader.isNull
          ? _fieldNameToLabel(field.name)
          : labelReader.stringValue;

      final hidden = reader.read('hidden').boolValue;
      final viewsObj = fieldAnnotation == null ? null : reader.peek('views');
      final views = (viewsObj == null || viewsObj.isNull)
          ? null
          : viewsObj.setValue.map((o) => o.toStringValue()!).toSet();
      final parentAnnotation = _parentChecker.firstAnnotationOf(field);
      final isParent = parentAnnotation != null;
      if (isParent) {
        if (parentElement != null) {
          throw InvalidGenerationSourceError(
            'Entity "${element.name}" has more than one @Parent field; '
            'only one level of nesting is supported.',
            element: field,
          );
        }
        final parentType = parentAnnotation.getField('type')?.toTypeValue();
        final parentTypeElement = parentType?.element;
        if (parentTypeElement is! ClassElement) {
          throw InvalidGenerationSourceError(
            '@Parent on "${field.name}" must reference an entity class, '
            'e.g. @Parent(Post).',
            element: field,
          );
        }
        final parentView = _viewChecker.firstAnnotationOf(parentTypeElement);
        if (parentView == null) {
          throw InvalidGenerationSourceError(
            '@Parent(${parentTypeElement.name}) on "${field.name}" references '
            'a class without a @View annotation. Annotate '
            '"${parentTypeElement.name}" with @View.',
            element: field,
          );
        }
        final parentViewReader = ConstantReader(parentView);
        parentPath = parentViewReader.read('path').stringValue;
        parentTitle = parentViewReader.read('title').stringValue;
        final parentIdField = _findIdField(parentTypeElement);
        parentIdType = parentIdField?.type.getDisplayString(
          withNullability: false,
        );
        final fieldType = field.type.getDisplayString(withNullability: false);
        if (parentIdType != null && parentIdType != fieldType) {
          throw InvalidGenerationSourceError(
            'Type mismatch: "${field.name}" is "$fieldType" but '
            '"${parentTypeElement.name}.${parentIdField?.name}" is "$parentIdType".',
            element: field,
          );
        }
        parentElement = parentTypeElement;
      }

      final validators = formReader
          .read('validators')
          .listValue
          .map((obj) => _readValidator(obj, field))
          .toList();

      final widgetName = formReader.read('widget').objectValue.variable?.name;
      final fieldWidget = widgetName != null
          ? FieldWidget.values.byName(widgetName)
          : FieldWidget.auto;

      final isEnum = field.type.element is EnumElement;

      fields.add(
        FieldManifest(
          name: field.name,
          label: label,
          hidden: hidden,
          isParent: isParent,
          dartType: field.type.getDisplayString(withNullability: false),
          validators: validators,
          fieldWidget: fieldWidget,
          isEnum: isEnum,
          isNullable:
              field.type.nullabilitySuffix == NullabilitySuffix.question,
          views: views,
          // peek: tolerate older annotation sources without these flags.
          searchable: reader.peek('searchable')?.boolValue ?? false,
          sortable: reader.peek('sortable')?.boolValue ?? false,
        ),
      );
    }

    return EntityManifest(
      entityName: element.name,
      title: title,
      path: path,
      hasCreate: hasCreate,
      hasUpdate: hasUpdate,
      hasDelete: hasDelete,
      fields: fields,
      idFieldName: idField.name,
      idType: idType,
      idIsNullable:
          idField.type.nullabilitySuffix == NullabilitySuffix.question,
      paged: paged,
      parentEntityName: parentElement?.name,
      parentPath: parentPath,
      parentTitle: parentTitle,
      parentIdType: parentIdType,
      parentInSameLibrary:
          parentElement == null || parentElement.library == element.library,
      constructorParams: element.unnamedConstructor?.parameters
          .map((p) => ConstructorParam(
                name: p.name,
                isNamed: p.isNamed,
                isRequired: p.isRequiredNamed || p.isRequiredPositional,
                isNullable:
                    p.type.nullabilitySuffix == NullabilitySuffix.question,
                hasDefault: p.hasDefaultValue,
              ))
          .toList(),
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// The identifier field of [cls]: the [@Id] field, otherwise a field `id`.
  static FieldElement? _findIdField(ClassElement cls) {
    final fields = cls.fields.where((f) => !f.isStatic && !f.isSynthetic);
    final annotated = fields.where(_idChecker.hasAnnotationOf);
    if (annotated.isNotEmpty) return annotated.first;
    return fields.where((f) => f.name == 'id').firstOrNull;
  }

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

/// Rebuilds a [Validator] from the annotation constant, reading its
/// parameters (and custom message) by field name.
Validator _readValidator(DartObject obj, FieldElement field) {
  final type = obj.type?.element?.name;
  final message =
      (obj.getField('message') ?? obj.getField('(super)')?.getField('message'))
          ?.toStringValue();
  num number() => (obj.getField('value')?.toIntValue() ??
      obj.getField('value')?.toDoubleValue())!;
  switch (type) {
    case 'RequiredValidator':
      return RequiredValidator(message: message);
    case 'EmailValidator':
      return EmailValidator(message: message);
    case 'UrlValidator':
      return UrlValidator(message: message);
    case 'PositiveValidator':
      return PositiveValidator(message: message);
    case 'NonNegativeValidator':
      return NonNegativeValidator(message: message);
    case 'MinValidator':
      return MinValidator(number(), message: message);
    case 'MaxValidator':
      return MaxValidator(number(), message: message);
    case 'MinLengthValidator':
      return MinLengthValidator(
        obj.getField('length')!.toIntValue()!,
        message: message,
      );
    case 'MaxLengthValidator':
      return MaxLengthValidator(
        obj.getField('length')!.toIntValue()!,
        message: message,
      );
    case 'PatternValidator':
      return PatternValidator(
        obj.getField('regex')!.toStringValue()!,
        message: message,
      );
  }
  throw InvalidGenerationSourceError(
    'Unsupported validator on "${field.name}". Use the Validator constants '
    'and factories, e.g. Validator.required or Validator.min(0).',
    element: field,
  );
}
