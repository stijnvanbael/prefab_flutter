// isSynthetic is deprecated from analyzer 9; the supported range is analyzer 8.
// ignore_for_file: deprecated_member_use

import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:prefab_flutter/prefab_flutter.dart';
import 'package:source_gen/source_gen.dart';

import 'field_manifest.dart';

final _createChecker = TypeChecker.typeNamed(Create, inPackage: 'prefab_flutter');
final _updateChecker = TypeChecker.typeNamed(Update, inPackage: 'prefab_flutter');
final _deleteChecker = TypeChecker.typeNamed(Delete, inPackage: 'prefab_flutter');
final _fieldChecker = TypeChecker.typeNamed(Field, inPackage: 'prefab_flutter');
final _idChecker = TypeChecker.typeNamed(Id, inPackage: 'prefab_flutter');
final _versionChecker =
    TypeChecker.typeNamed(Version, inPackage: 'prefab_flutter');
final _entityChecker = TypeChecker.typeNamed(Entity, inPackage: 'prefab_flutter');
final _parentChecker = TypeChecker.typeNamed(Parent, inPackage: 'prefab_flutter');

/// Reads the `fieldRename` of the class's `@JsonSerializable` (by name, so the
/// generator needs no dependency on `json_annotation`), or `none`.
/// The display string of [type] without nullability markers (`int?` -> `int`).
String? _plainType(DartType? type) =>
    type?.getDisplayString().replaceAll('?', '');

/// Reads a hand-written widget reference (PF-65) and checks that it is a
/// constructor or function with the named parameters of the contract.
CustomWidgetRef? _readCustomWidget(
  ConstantReader? reader,
  FieldElement field,
  ClassElement entity,
  String annotation, {
  required Set<String> required,
  required Set<String> optional,
}) {
  if (reader == null || reader.isNull) return null;
  final fn = reader.objectValue.toFunctionValue();
  if (fn == null) {
    throw InvalidGenerationSourceError(
      'Field "${field.name}": $annotation must be a constructor tear-off or '
      'a top-level function (for example ColorField.new).',
      element: field,
    );
  }
  final named = {
    for (final p in fn.formalParameters)
      if (p.isNamed) p.name!: p,
  };
  final expected = {...required, ...optional};
  final missing = required.where((n) => !named.containsKey(n)).toList();
  final extra = [
    for (final p in fn.formalParameters)
      if (!p.isNamed || !expected.contains(p.name))
        if (p.isRequired) p.name,
  ];
  if (missing.isNotEmpty || extra.isNotEmpty) {
    throw InvalidGenerationSourceError(
      'Field "${field.name}": $annotation references "${fn.displayName}", '
      'which must take the named parameters ${required.join(', ')}'
      '${optional.isEmpty ? '' : ' (and optionally ${optional.join(', ')})'}'
      '${missing.isEmpty ? '' : '; missing: ${missing.join(', ')}'}'
      '${extra.isEmpty ? '' : '; unsupported required parameters: '
          '${extra.join(', ')}'}.',
      element: field,
    );
  }
  final String invocation;
  final enclosing = fn.enclosingElement;
  if (fn is ConstructorElement) {
    final cls = enclosing!.name!;
    invocation = fn.name == 'new' || fn.name!.isEmpty ? cls : '$cls.${fn.name}';
  } else if (enclosing is InterfaceElement) {
    invocation = '${enclosing.name}.${fn.name}';
  } else {
    invocation = fn.name!;
  }
  final uri = fn.library.uri.toString();
  return CustomWidgetRef(
    invocation: invocation,
    libraryUri: uri == entity.library.uri.toString() ? null : uri,
    parameters: named.keys.toSet(),
  );
}

/// Reads `@Field.on`: `null` for every place, otherwise the set of places.
/// [Place.list] is the list screen's AppBar, where no field can appear.
Set<Place>? _readFieldPlaces(
    ConstantReader field, String entityName, String fieldName) {
  final on = field.peek('on');
  if (on == null || on.isNull) return null;
  final places = {
    for (final o in on.setValue) Place.values.byName(o.variable!.name!)
  };
  if (places.contains(Place.list)) {
    throw InvalidGenerationSourceError(
      'Field "$entityName.$fieldName" has Place.list in on:, but fields '
      'cannot appear in the list screen\'s AppBar. Use Place.item to show '
      'the field in each list item.',
    );
  }
  return places;
}

/// Reads `FormOptions.on`: `null` for both forms, otherwise the set of modes.
Set<FormMode>? _readFormModes(ConstantReader form) {
  final on = form.peek('on');
  if (on == null || on.isNull) return null;
  return {
    for (final o in on.setValue) FormMode.values.byName(o.variable!.name!)
  };
}

String _readFieldRename(ClassElement element) {
  for (final meta in element.metadata.annotations) {
    final value = meta.computeConstantValue();
    if (value?.type?.element?.name != 'JsonSerializable') continue;
    final rename = value!.getField('fieldRename');
    final name = rename?.getField('_name')?.toStringValue();
    if (name != null) return name;
    final index = rename?.getField('index')?.toIntValue();
    const order = ['none', 'kebab', 'snake', 'pascal', 'screamingSnake'];
    if (index != null && index < order.length) return order[index];
  }
  return 'none';
}

/// The JSON name of [field]: `@JsonKey(name:)`, else [fieldRename] applied to
/// the Dart name.
String _readJsonName(FieldElement field, String fieldRename) {
  for (final meta in field.metadata.annotations) {
    final value = meta.computeConstantValue();
    if (value?.type?.element?.name != 'JsonKey') continue;
    final name = value!.getField('name')?.toStringValue();
    if (name != null) return name;
  }
  final words = field.name!
      .replaceAllMapped(RegExp('(?<=[a-z0-9])([A-Z])'), (m) => '_${m[1]}')
      .toLowerCase()
      .split('_');
  switch (fieldRename) {
    case 'kebab':
      return words.join('-');
    case 'snake':
      return words.join('_');
    case 'pascal':
      return words.map((w) => w[0].toUpperCase() + w.substring(1)).join();
    case 'screamingSnake':
      return words.join('_').toUpperCase();
    default:
      return field.name!;
  }
}

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

  /// The Dart type without nullability (`String`, `int`, `Status`).
  final String typeName;

  /// Whether the type is an enum.
  final bool isEnum;

  const ConstructorParam({
    required this.name,
    required this.isNamed,
    required this.isRequired,
    required this.isNullable,
    required this.hasDefault,
    this.typeName = 'Object',
    this.isEnum = false,
  });

  /// Whether the parameter may be left out (or passed `null`) on create.
  bool get isOptional => !isRequired;
}

/// One entity in the `@Parent` chain above an entity (see
/// [EntityManifest.ancestors]).
class AncestorManifest {
  /// Class name, e.g. `Order`.
  final String entityName;

  /// Lower-camel-case class name, e.g. `order`.
  final String entityNameLower;

  /// URL path from the ancestor's `@Entity.path`.
  final String path;

  /// Title from the ancestor's `@Entity.title`.
  final String title;

  /// Dart type of the ancestor's id (`'int'` or `'String'`).
  final String idType;

  /// Name of the ancestor's id field.
  final String idFieldName;

  /// Name of the field used as the ancestor's label in breadcrumbs.
  final String labelFieldName;

  /// Whether [labelFieldName] is nullable.
  final bool labelIsNullable;

  /// Dart parameter name carrying this ancestor's id in the entity's screens,
  /// providers and API client: the `@Parent` field name for the direct parent,
  /// `<entity>Id` for the others.
  final String paramName;

  /// Import URI of the library declaring the ancestor.
  final String libraryUri;

  /// Whether the ancestor is declared in the same library as the entity.
  final bool inSameLibrary;

  const AncestorManifest({
    required this.entityName,
    required this.entityNameLower,
    required this.path,
    required this.title,
    required this.idType,
    required this.idFieldName,
    required this.labelFieldName,
    required this.labelIsNullable,
    required this.paramName,
    required this.libraryUri,
    required this.inSameLibrary,
  });

  /// GoRouter path parameter name for this ancestor's id (`orderId`).
  String get routeParam => '${entityNameLower}Id';

  /// Dart expression converting the string [expr] to the id type.
  String parse(String expr) => idType == 'int' ? 'int.parse($expr)' : expr;
}

/// Summarises everything the generators need to know about a single
/// [@Entity]-annotated entity class.
class EntityManifest {
  /// Dart class name (e.g. `'Product'`).
  final String entityName;

  /// Lower-camel-case version of [entityName] (e.g. `'product'`).
  final String entityNameLower;

  /// Human-readable title from [@Entity.title].
  final String title;

  /// URL path segment from [@Entity.path] (e.g. `'products'`).
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

  /// Name of the version field for optimistic locking (the [@Version] field,
  /// or `version`), or `null` when the entity has none.
  final String? versionFieldName;

  /// The name the server knows the version field by (see
  /// [FieldManifest.jsonName]).
  final String? versionJsonName;

  /// Whether the entity is optimistically locked.
  bool get hasVersion => versionFieldName != null;

  /// Dart expression suffix that makes an id access non-null (`!` or empty).
  String get idBang => idIsNullable ? '!' : '';

  /// Class name of the parent entity named in `@Parent(Type)`, or `null`.
  final String? parentEntityName;

  /// URL path of the parent entity (from the parent's `@Entity.path`).
  final String? parentPath;

  /// Title of the parent entity (from the parent's `@Entity.title`).
  final String? parentTitle;

  /// Dart type of the parent's `id` field (e.g. `'int'`).
  final String? parentIdType;

  /// Whether the parent is declared in the same library as this entity.
  final bool parentInSameLibrary;

  /// Parameters of the unnamed constructor, or `null` when the class has none.
  final List<ConstructorParam>? constructorParams;

  /// Whether the list is paged server-side ([@Entity.paged]).
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
    this.versionFieldName,
    this.versionJsonName,
    this.parentEntityName,
    this.parentPath,
    this.parentTitle,
    this.parentIdType,
    this.parentInSameLibrary = true,
    this.ancestors = const [],
    this.constructorParams,
    this.paged = true,
  }) : entityNameLower = _toLowerCamel(entityName);

  // ---------------------------------------------------------------------------
  // Convenience accessors used by generators
  // ---------------------------------------------------------------------------

  /// All fields shown in at least one place (not `on: {}`), without the
  /// parent field.
  List<FieldManifest> get visibleFields =>
      fields.where((f) => !f.isShownNowhere && !f.isParent).toList();

  /// All fields that appear in the create or the edit form: in
  /// [Place.form], not read-only and in at least one [FormMode].
  List<FieldManifest> get formFields =>
      visibleFields.where((f) => f.inForm(FormMode.create) || f.inForm(FormMode.update)).toList();

  /// The fields of the create form, which are also the fields of the create
  /// request body (with the parent field).
  List<FieldManifest> get createFormFields =>
      visibleFields.where((f) => f.inForm(FormMode.create)).toList();

  /// The fields of the edit form.
  List<FieldManifest> get updateFormFields =>
      visibleFields.where((f) => f.inForm(FormMode.update)).toList();

  /// The JSON names the create request carries: the create form fields and
  /// the parent field. The id and the other fields are never sent.
  List<String> get createJsonNames => [
        for (final f in fields)
          if (f.isParent || f.inForm(FormMode.create)) f.jsonName,
      ];

  /// The JSON names the update request leaves out of `toJson()`: read-only
  /// and create-only fields.
  List<String> get updateExcludedJsonNames => [
        for (final f in fields)
          if (f.readOnly || !f.isOnMode(FormMode.update)) f.jsonName,
      ];

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

  /// The `@Parent` chain above this entity, outermost first; the last element
  /// is the direct parent. Empty for root entities.
  final List<AncestorManifest> ancestors;

  /// Number of ancestors (0 for a root entity).
  int get depth => ancestors.length;


  /// Type of the key of the list provider family: the parent id type for one
  /// ancestor, a positional record of all ancestor id types otherwise.
  String get parentKeyType => depth == 1
      ? ancestors.first.idType
      : '(${ancestors.map((a) => a.idType).join(', ')})';

  /// Expression building the list provider key from [value] of each ancestor.
  String parentKeyExpr(String Function(AncestorManifest a) value) => depth == 1
      ? value(ancestors.first)
      : '(${ancestors.map(value).join(', ')})';

  /// Type of the detail provider key: `(idType, ancestor id types...)`.
  String get detailKeyType =>
      '($idType, ${ancestors.map((a) => a.idType).join(', ')})';

  /// Expression building the detail provider key from [idExpr] and [value] of
  /// each ancestor (just [idExpr] for a root entity).
  String detailKeyExpr(String idExpr, String Function(AncestorManifest a) value) =>
      hasParent ? '($idExpr, ${ancestors.map(value).join(', ')})' : idExpr;

  /// Declarations of the ancestor id parameters, e.g.
  /// `int orderId, int orderLineId`.
  String get ancestorParamDecls =>
      ancestors.map((a) => '${a.idType} ${a.paramName}').join(', ');

  /// Named arguments passing every ancestor id, e.g.
  /// `orderId: orderId, orderLineId: orderLineId`.
  String ancestorNamedArgs([String prefix = '']) =>
      ancestors.map((a) => '${a.paramName}: $prefix${a.paramName}').join(', ');

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
  /// [@Entity] annotation.
  static EntityManifest from(
    ClassElement element,
    ConstantReader viewAnnotation,
  ) {
    final title = viewTitle(viewAnnotation, element.name!);
    final path = viewPath(viewAnnotation, element.name!);

    final paged = viewAnnotation.peek('paged')?.boolValue ?? true;

    final hasCreate = _createChecker.hasAnnotationOf(element);
    final hasUpdate = _updateChecker
        .annotationsOf(element)
        .any((a) => a.getField('path')?.isNull ?? true);
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
    final idType = _plainType(idField.type)!;
    if (idType != 'String' && idType != 'int') {
      throw InvalidGenerationSourceError(
        'The id field "${idField.name}" of "${element.name}" must be of type '
        'String or int, but is $idType.',
        element: idField,
      );
    }

    final versionFields =
        instanceFields.where(_versionChecker.hasAnnotationOf).toList();
    if (versionFields.length > 1) {
      throw InvalidGenerationSourceError(
        'Entity "${element.name}" has more than one @Version field.',
        element: element,
      );
    }
    final versionField = versionFields.isNotEmpty
        ? versionFields.first
        : instanceFields.where((f) => f.name == 'version').firstOrNull;
    if (versionField != null && versionField == idField) {
      throw InvalidGenerationSourceError(
        'The field "${versionField.name}" of "${element.name}" cannot be both '
        '@Id and @Version.',
        element: versionField,
      );
    }

    final fieldRename = _readFieldRename(element);
    final fields = <FieldManifest>[];
    ClassElement? parentElement;
    String? parentPath, parentTitle, parentIdType, parentParamName;
    for (final field in instanceFields) {
      if (field == idField || field == versionField) continue;

      final annotation = _fieldChecker.firstAnnotationOf(field);
      if (annotation == null) continue;

      final parentAnnotation = _parentChecker.firstAnnotationOf(field);
      final isParent = parentAnnotation != null;
      if (isParent) {
        if (parentElement != null) {
          throw InvalidGenerationSourceError(
            'Entity "${element.name}" has more than one @Parent field; '
            'an entity can only have one parent.',
            element: field,
          );
        }
        final parentType = parentAnnotation.getField('entity')?.toTypeValue();
        final parentTypeElement = parentType?.element;
        if (parentTypeElement is! ClassElement) {
          throw InvalidGenerationSourceError(
            '@Parent on "${field.name}" must reference an entity class, '
            'e.g. @Parent(Post).',
            element: field,
          );
        }
        final parentEntity = _entityChecker.firstAnnotationOf(parentTypeElement);
        if (parentEntity == null) {
          throw InvalidGenerationSourceError(
            '@Parent(${parentTypeElement.name}) on "${field.name}" references '
            'a class without an @Entity annotation. Annotate '
            '"${parentTypeElement.name}" with @Entity.',
            element: field,
          );
        }
        final parentEntityReader = ConstantReader(parentEntity);
        parentPath = viewPath(parentEntityReader, parentTypeElement.name!);
        parentTitle = viewTitle(parentEntityReader, parentTypeElement.name!);
        final parentIdField = _findIdField(parentTypeElement);
        parentIdType = _plainType(parentIdField?.type);
        final fieldType = _plainType(field.type)!;
        if (parentIdType != null && parentIdType != fieldType) {
          throw InvalidGenerationSourceError(
            'Type mismatch: "${field.name}" is "$fieldType" but '
            '"${parentTypeElement.name}.${parentIdField?.name}" is "$parentIdType".',
            element: field,
          );
        }
        parentElement = parentTypeElement;
        parentParamName = field.name;
      }

      fields.add(_readField(field, annotation, element, fieldRename,
          isParent: isParent));
    }

    return EntityManifest(
      entityName: element.name!,
      title: title,
      path: path,
      hasCreate: hasCreate,
      hasUpdate: hasUpdate,
      hasDelete: hasDelete,
      fields: fields,
      idFieldName: idField.name!,
      idType: idType,
      idIsNullable:
          idField.type.nullabilitySuffix == NullabilitySuffix.question,
      versionFieldName: versionField?.name,
      versionJsonName:
          versionField == null ? null : _readJsonName(versionField, fieldRename),
      paged: paged,
      parentEntityName: parentElement?.name,
      parentPath: parentPath,
      parentTitle: parentTitle,
      parentIdType: parentIdType,
      parentInSameLibrary:
          parentElement == null || parentElement.library == element.library,
      ancestors: parentElement == null
          ? const []
          : _resolveAncestors(element, parentElement, parentParamName!),
      constructorParams: element.unnamedConstructor?.formalParameters
          .map((p) => ConstructorParam(
                name: p.name!,
                isNamed: p.isNamed,
                isRequired: p.isRequiredNamed || p.isRequiredPositional,
                isNullable:
                    p.type.nullabilitySuffix == NullabilitySuffix.question,
                hasDefault: p.hasDefaultValue,
                typeName: _plainType(p.type)!,
                isEnum: p.type.element is EnumElement,
              ))
          .toList(),
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Reads one `@Field` of [element] (an entity or an operation's parameters
  /// class) with the defaults and inference of every field.
  static FieldManifest _readField(
    FieldElement field,
    DartObject annotation,
    ClassElement element,
    String fieldRename, {
    required bool isParent,
  }) {
    final reader = ConstantReader(annotation);
    final formReader = reader.read('form');
    final labelReader = reader.read('label');
    final label = labelReader.isNull
        ? _fieldNameToLabel(field.name!)
        : labelReader.stringValue;
    final places = _readFieldPlaces(reader, element.name!, field.name!);
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
    final customForm = _readCustomWidget(
      formReader.peek('builder'),
      field,
      element,
      'FormOptions.builder',
      required: const {'initialValue', 'onChanged', 'label'},
      optional: const {'key', 'validator'},
    );
    final customDisplay = _readCustomWidget(
      reader.peek('displayBuilder'),
      field,
      element,
      'Field.displayBuilder',
      required: const {'value'},
      optional: const {'key'},
    );

    return FieldManifest(
        name: field.name!,
        label: label,
        isParent: isParent,
        dartType: _plainType(field.type)!,
        validators: validators,
        fieldWidget: fieldWidget,
        customForm: customForm,
        customDisplay: customDisplay,
        isEnum: isEnum,
        isNullable:
            field.type.nullabilitySuffix == NullabilitySuffix.question,
        places: places,
        readOnly: reader.peek('readOnly')?.boolValue ?? false,
        formModes: _readFormModes(formReader),
        // peek: tolerate older annotation sources without these flags.
        searchable: reader.peek('searchable')?.boolValue ?? false,
        sortable: reader.peek('sortable')?.boolValue ?? false,
        jsonName: _readJsonName(field, fieldRename),
    );
  }

  /// The form fields of an operation's parameters class (`@Update.parameters`):
  /// its `@Field` fields, read like the fields of an entity.
  static List<FieldManifest> readParameterFields(ClassElement element) {
    final fieldRename = _readFieldRename(element);
    return [
      for (final field in element.fields)
        if (!field.isStatic && !field.isSynthetic)
          if (_fieldChecker.firstAnnotationOf(field) case final annotation?)
            _readField(field, annotation, element, fieldRename,
                isParent: false),
    ];
  }

  /// The unnamed constructor of [element] as [ConstructorParam]s, or `null`.
  static List<ConstructorParam>? readConstructorParams(ClassElement element) =>
      element.unnamedConstructor?.formalParameters
          .map((p) => ConstructorParam(
                name: p.name!,
                isNamed: p.isNamed,
                isRequired: p.isRequiredNamed || p.isRequiredPositional,
                isNullable:
                    p.type.nullabilitySuffix == NullabilitySuffix.question,
                hasDefault: p.hasDefaultValue,
                typeName: _plainType(p.type)!,
                isEnum: p.type.element is EnumElement,
              ))
          .toList();

  /// The identifier field of [cls]: the [@Id] field, otherwise a field `id`.
  static FieldElement? _findIdField(ClassElement cls) {
    final fields = cls.fields.where((f) => !f.isStatic && !f.isSynthetic);
    final annotated = fields.where(_idChecker.hasAnnotationOf);
    if (annotated.isNotEmpty) return annotated.first;
    return fields.where((f) => f.name == 'id').firstOrNull;
  }

  /// Walks the `@Parent` chain upwards from [parent] and returns it outermost
  /// first. [directParamName] is the `@Parent` field name of [element].
  static List<AncestorManifest> _resolveAncestors(
    ClassElement element,
    ClassElement parent,
    String directParamName,
  ) {
    final chain = <ClassElement>[parent];
    var current = parent;
    while (true) {
      final parentField = current.fields
          .where((f) => !f.isStatic && !f.isSynthetic)
          .where(_parentChecker.hasAnnotationOf)
          .firstOrNull;
      if (parentField == null) break;
      final type = _parentChecker
          .firstAnnotationOf(parentField)
          ?.getField('entity')
          ?.toTypeValue()
          ?.element;
      if (type is! ClassElement) {
        throw InvalidGenerationSourceError(
          '@Parent on "${parentField.name}" must reference an entity class, '
          'e.g. @Parent(Post).',
          element: parentField,
        );
      }
      if (type == element || chain.contains(type)) {
        throw InvalidGenerationSourceError(
          'Circular @Parent chain: ${[
            element.name,
            ...chain.map((c) => c.name),
            type.name,
          ].join(' -> ')}.',
          element: element,
        );
      }
      if (_entityChecker.firstAnnotationOf(type) == null) {
        throw InvalidGenerationSourceError(
          '@Parent(${type.name}) on "${parentField.name}" references a class '
          'without an @Entity annotation. Annotate "${type.name}" with @Entity.',
          element: parentField,
        );
      }
      chain.add(type);
      current = type;
    }

    final result = <AncestorManifest>[];
    for (var i = chain.length - 1; i >= 0; i--) {
      final cls = chain[i];
      final view = ConstantReader(_entityChecker.firstAnnotationOf(cls)!);
      final idField = _findIdField(cls);
      final label = cls.fields
          .where((f) => !f.isStatic && !f.isSynthetic && f != idField)
          .where((f) => !_parentChecker.hasAnnotationOf(f))
          .where((f) {
        final a = _fieldChecker.firstAnnotationOf(f);
        if (a == null) return false;
        final on = ConstantReader(a).peek('on');
        return on == null || on.isNull || on.setValue.isNotEmpty;
      }).firstOrNull;
      final labelField = label ?? idField;
      final lower = _toLowerCamel(cls.name!);
      result.add(AncestorManifest(
        entityName: cls.name!,
        entityNameLower: lower,
        path: viewPath(view, cls.name!),
        title: viewTitle(view, cls.name!),
        idType: _plainType(idField?.type) ??
            'String',
        idFieldName: idField?.name ?? 'id',
        labelFieldName: labelField?.name ?? 'id',
        labelIsNullable:
            labelField?.type.nullabilitySuffix == NullabilitySuffix.question,
        paramName: '${lower}Id',
        libraryUri: cls.library.uri.toString(),
        inSameLibrary: cls.library == element.library,
      ));
    }
    // The direct parent (last) is named after the @Parent field.
    final direct = result.removeLast();
    result.add(AncestorManifest(
      entityName: direct.entityName,
      entityNameLower: direct.entityNameLower,
      path: direct.path,
      title: direct.title,
      idType: direct.idType,
      idFieldName: direct.idFieldName,
      labelFieldName: direct.labelFieldName,
      labelIsNullable: direct.labelIsNullable,
      paramName: directParamName,
      libraryUri: direct.libraryUri,
      inSameLibrary: direct.inSameLibrary,
    ));
    final names = result.map((a) => a.paramName).toList();
    if (names.toSet().length != names.length) {
      throw InvalidGenerationSourceError(
        'Ancestor id parameters of "${element.name}" clash: '
        '${names.join(', ')}. Rename the @Parent field.',
        element: element,
      );
    }
    return result;
  }

  static String _toLowerCamel(String name) {
    if (name.isEmpty) return name;
    return name[0].toLowerCase() + name.substring(1);
  }

  /// The `@Entity.title` of an entity: the explicit value, or the class name in
  /// title case (`ProductOrder` → `Product Order`).
  static String viewTitle(ConstantReader view, String className) {
    final explicit = view.peek('title');
    if (explicit != null && !explicit.isNull) return explicit.stringValue;
    return classNameWords(className).map(_capitalize).join(' ');
  }

  /// The `@Entity.path` of an entity: the explicit value, or the kebab-case
  /// plural of the class name (`ProductOrder` → `product-orders`).
  static String viewPath(ConstantReader view, String className) {
    final explicit = view.peek('path');
    if (explicit != null && !explicit.isNull) return explicit.stringValue;
    return pluralizeKebab(className);
  }

  /// Splits a class name into words (`HTTPRequest` → `HTTP`, `Request`).
  static List<String> classNameWords(String name) => RegExp(
        r'[A-Z]+(?![a-z])|[A-Z]?[a-z]+|\d+',
      ).allMatches(name).map((m) => m[0]!).toList();

  /// Kebab-case plural of a class name. The last word is pluralised:
  /// consonant + `y` → `ies`; ending in `s`, `x`, `z`, `ch` or `sh` → `es`;
  /// otherwise `s` is appended.
  static String pluralizeKebab(String className) {
    final words = classNameWords(className).map((w) => w.toLowerCase()).toList();
    if (words.isEmpty) return className.toLowerCase();
    final last = words.removeLast();
    final String plural;
    if (RegExp(r'[^aeiou]y$').hasMatch(last)) {
      plural = '${last.substring(0, last.length - 1)}ies';
    } else if (RegExp(r'(s|x|z|ch|sh)$').hasMatch(last)) {
      plural = '${last}es';
    } else {
      plural = '${last}s';
    }
    return [...words, plural].join('-');
  }

  static String _capitalize(String w) =>
      w.isEmpty ? w : w[0].toUpperCase() + w.substring(1);

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
