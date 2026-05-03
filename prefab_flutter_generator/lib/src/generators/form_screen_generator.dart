import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:prefab_flutter/prefab_flutter.dart';
import 'package:source_gen/source_gen.dart';

import '../manifest/entity_manifest.dart';
import '../manifest/field_manifest.dart';

/// Resolved widget kind after applying [FieldWidget.auto] type inference.
enum _WidgetKind { text, multilineText, password, datePicker, dropdown, toggle }

/// Generates `{Entity}CreateScreen` and `{Entity}EditScreen` [ConsumerWidget]s
/// for every class annotated with [@View] that also carries [@Update].
class FormScreenGenerator extends GeneratorForAnnotation<View> {
  @override
  String generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    if (element is! ClassElement) {
      throw InvalidGenerationSourceError(
        '@View can only be applied to classes.',
        element: element,
      );
    }

    final manifest = EntityManifest.from(element, annotation);

    // Only generate form screens when @Update is present.
    if (!manifest.hasUpdate) return '';

    final inputPath = buildStep.inputId.path;
    final sourceFileName = inputPath.split('/').last;

    return _generate(manifest, sourceFileName);
  }

  String _generate(EntityManifest manifest, String sourceFileName) {
    final buffer = StringBuffer();
    _writeHeader(buffer);
    _writeImports(sourceFileName, buffer);
    buffer.writeln();
    _writeCreateScreen(manifest, buffer);
    buffer.writeln();
    _writeEditScreen(manifest, buffer);
    return buffer.toString();
  }

  // ---------------------------------------------------------------------------
  // Widget kind resolution
  // ---------------------------------------------------------------------------

  _WidgetKind _resolveWidgetKind(FieldManifest field) {
    return switch (field.fieldWidget) {
      FieldWidget.multilineText => _WidgetKind.multilineText,
      FieldWidget.password => _WidgetKind.password,
      FieldWidget.datePicker => _WidgetKind.datePicker,
      FieldWidget.dropdown => _WidgetKind.dropdown,
      FieldWidget.toggle => _WidgetKind.toggle,
      FieldWidget.auto => switch (field.dartType) {
          'bool' => _WidgetKind.toggle,
          'DateTime' => _WidgetKind.datePicker,
          _ => field.isEnum ? _WidgetKind.dropdown : _WidgetKind.text,
        },
    };
  }

  // ---------------------------------------------------------------------------
  // Header
  // ---------------------------------------------------------------------------

  void _writeHeader(StringBuffer buffer) {
    const separator =
        '// **************************************************************************';
    buffer.writeln('// GENERATED CODE - DO NOT MODIFY BY HAND');
    buffer.writeln('//');
    buffer.writeln(separator);
    buffer.writeln('// FormScreenGenerator');
    buffer.writeln(separator);
    buffer.writeln();
  }

  // ---------------------------------------------------------------------------
  // Imports
  // ---------------------------------------------------------------------------

  void _writeImports(String sourceFileName, StringBuffer buffer) {
    final base = sourceFileName.replaceFirst(RegExp(r'\.dart$'), '');
    buffer.writeln("import 'package:flutter/material.dart';");
    buffer.writeln("import 'package:flutter_riverpod/flutter_riverpod.dart';");
    buffer.writeln("import 'package:go_router/go_router.dart';");
    buffer.writeln("import '$sourceFileName';");
    buffer.writeln("import '$base.provider.dart';");
  }

  // ---------------------------------------------------------------------------
  // Create screen
  // ---------------------------------------------------------------------------

  void _writeCreateScreen(EntityManifest manifest, StringBuffer buffer) {
    final entity = manifest.entityName;

    buffer.writeln(
        'class ${entity}CreateScreen extends ConsumerStatefulWidget {');
    buffer.writeln('  const ${entity}CreateScreen({super.key});');
    buffer.writeln();
    buffer.writeln('  @override');
    buffer.writeln(
        '  ConsumerState<${entity}CreateScreen> createState() => _${entity}CreateScreenState();');
    buffer.writeln('}');
    buffer.writeln();

    _writeScreenState(
      manifest: manifest,
      stateClassName: '_${entity}CreateScreenState',
      widgetClassName: '${entity}CreateScreen',
      saveButtonLabel: 'Create',
      isEdit: false,
      buffer: buffer,
    );
  }

  // ---------------------------------------------------------------------------
  // Edit screen
  // ---------------------------------------------------------------------------

  void _writeEditScreen(EntityManifest manifest, StringBuffer buffer) {
    final entity = manifest.entityName;

    buffer.writeln('class ${entity}EditScreen extends ConsumerStatefulWidget {');
    buffer.writeln('  final Object id;');
    buffer.writeln();
    buffer
        .writeln('  const ${entity}EditScreen({super.key, required this.id});');
    buffer.writeln();
    buffer.writeln('  @override');
    buffer.writeln(
        '  ConsumerState<${entity}EditScreen> createState() => _${entity}EditScreenState();');
    buffer.writeln('}');
    buffer.writeln();

    _writeScreenState(
      manifest: manifest,
      stateClassName: '_${entity}EditScreenState',
      widgetClassName: '${entity}EditScreen',
      saveButtonLabel: 'Save',
      isEdit: true,
      buffer: buffer,
    );
  }

  // ---------------------------------------------------------------------------
  // Shared state class
  // ---------------------------------------------------------------------------

  void _writeScreenState({
    required EntityManifest manifest,
    required String stateClassName,
    required String widgetClassName,
    required String saveButtonLabel,
    required bool isEdit,
    required StringBuffer buffer,
  }) {
    final fields = manifest.formFields;

    buffer.writeln(
        'class $stateClassName extends ConsumerState<$widgetClassName> {');
    buffer.writeln('  final _formKey = GlobalKey<FormState>();');

    if (isEdit) {
      buffer.writeln('  bool _prefilled = false;');
    }

    for (final field in fields) {
      final kind = _resolveWidgetKind(field);
      switch (kind) {
        case _WidgetKind.toggle:
          buffer.writeln('  bool _${field.name}Value = false;');
        case _WidgetKind.datePicker:
          buffer.writeln(
              '  final _${field.name}Controller = TextEditingController();');
          buffer.writeln('  DateTime? _${field.name}Value;');
        case _WidgetKind.dropdown:
          buffer.writeln('  ${field.dartType}? _${field.name}Value;');
        default:
          buffer.writeln(
              '  final _${field.name}Controller = TextEditingController();');
      }
    }

    buffer.writeln();
    buffer.writeln('  @override');
    buffer.writeln('  void dispose() {');
    for (final field in fields) {
      final kind = _resolveWidgetKind(field);
      if (kind != _WidgetKind.toggle && kind != _WidgetKind.dropdown) {
        buffer.writeln('    _${field.name}Controller.dispose();');
      }
    }
    buffer.writeln('    super.dispose();');
    buffer.writeln('  }');

    if (isEdit) {
      buffer.writeln();
      _writePrefillControllers(manifest, buffer);
    }

    buffer.writeln();
    buffer.writeln('  @override');
    buffer.writeln('  Widget build(BuildContext context) {');

    if (isEdit) {
      _writeEditBuildBody(manifest, saveButtonLabel, buffer);
    } else {
      _writeCreateBuildBody(manifest, saveButtonLabel, buffer);
    }

    buffer.writeln('  }');
    buffer.writeln('}');
  }

  // ---------------------------------------------------------------------------
  // Build body helpers
  // ---------------------------------------------------------------------------

  /// Emits the body of [build] for the Create screen (no provider prefill).
  void _writeCreateBuildBody(
      EntityManifest manifest, String saveButtonLabel, StringBuffer buffer) {
    buffer.writeln('    return Scaffold(');
    buffer.writeln('      appBar: AppBar(');
    buffer.writeln("        title: const Text('${manifest.title}'),");
    buffer.writeln('      ),');
    buffer.writeln('      body: Form(');
    buffer.writeln('        key: _formKey,');
    buffer.writeln('        child: ListView(');
    buffer.writeln('          padding: const EdgeInsets.all(16),');
    buffer.writeln('          children: [');
    for (final field in manifest.formFields) {
      _writeFormField(field, buffer);
    }
    _writeSaveButton(saveButtonLabel, manifest, isEdit: false, buffer: buffer);
    buffer.writeln('          ],');
    buffer.writeln('        ),');
    buffer.writeln('      ),');
    buffer.writeln('    );');
  }

  /// Emits the body of [build] for the Edit screen: watches the detail
  /// provider, prefills controllers once, and wraps the form in
  /// [AsyncValue.when].
  void _writeEditBuildBody(
      EntityManifest manifest, String saveButtonLabel, StringBuffer buffer) {
    final entityLower = manifest.entityNameLower;

    buffer.writeln(
        '    final asyncItem = ref.watch(${entityLower}DetailProvider(widget.id));');
    buffer.writeln('    asyncItem.whenData((item) {');
    buffer.writeln('      if (!_prefilled) {');
    buffer.writeln('        _prefilled = true;');
    buffer.writeln('        _prefillControllers(item);');
    buffer.writeln('      }');
    buffer.writeln('    });');
    buffer.writeln('    return Scaffold(');
    buffer.writeln('      appBar: AppBar(');
    buffer.writeln("        title: const Text('${manifest.title}'),");
    buffer.writeln('      ),');
    buffer.writeln('      body: asyncItem.when(');
    buffer.writeln(
        '        loading: () => const Center(child: CircularProgressIndicator()),');
    buffer.writeln(
        '        error: (e, _) => Center(child: Text(e.toString())),');
    buffer.writeln('        data: (item) => Form(');
    buffer.writeln('          key: _formKey,');
    buffer.writeln('          child: ListView(');
    buffer.writeln('            padding: const EdgeInsets.all(16),');
    buffer.writeln('            children: [');
    for (final field in manifest.formFields) {
      _writeFormField(field, buffer);
    }
    _writeSaveButton(saveButtonLabel, manifest, isEdit: true, buffer: buffer);
    buffer.writeln('            ],');
    buffer.writeln('          ),');
    buffer.writeln('        ),');
    buffer.writeln('      ),');
    buffer.writeln('    );');
  }

  void _writeSaveButton(
    String saveButtonLabel,
    EntityManifest manifest,
    {required bool isEdit, required StringBuffer buffer}
  ) {
    final entityLower = manifest.entityNameLower;
    final entityName = manifest.entityName;
    final notifier = manifest.hasParent
        ? '${entityLower}sProvider(widget.${manifest.parentParamName}).notifier'
        : '${entityLower}sProvider.notifier';
    final action = isEdit ? 'update' : 'create';

    buffer.writeln('            ElevatedButton(');
    buffer.writeln('              onPressed: () async {');
    buffer.writeln(
        '                if (_formKey.currentState!.validate()) {');

    // Build the entity constructor call.
    if (isEdit) {
      buffer.writeln('                  final entity = $entityName(');
      final idField = manifest.idField;
      if (idField != null) {
        buffer.writeln('                    ${idField.name}: item.${idField.name},');
      }
      for (final field in manifest.formFields) {
        buffer.writeln(
            '                    ${field.name}: ${_fieldValueExpression(field)},');
      }
      buffer.writeln('                  );');
    } else {
      buffer.writeln('                  final entity = $entityName(');
      final idField = manifest.idField;
      if (idField != null) {
        buffer.writeln(
            '                    ${idField.name}: ${_zeroValue(idField)},');
      }
      for (final field in manifest.formFields) {
        buffer.writeln(
            '                    ${field.name}: ${_fieldValueExpression(field)},');
      }
      buffer.writeln('                  );');
    }

    buffer.writeln(
        '                  await ref.read($notifier).$action(entity);');
    buffer.writeln(
        '                  if (context.mounted) context.pop();');
    buffer.writeln('                }');
    buffer.writeln('              },');
    buffer.writeln("              child: const Text('$saveButtonLabel'),");
    buffer.writeln('            ),');
  }

  // ---------------------------------------------------------------------------
  // Field value / zero-value helpers
  // ---------------------------------------------------------------------------

  /// Returns the Dart expression that reads the current form-field value for
  /// [field] from the generated state variable or controller.
  String _fieldValueExpression(FieldManifest field) {
    final kind = _resolveWidgetKind(field);
    return switch (kind) {
      _WidgetKind.toggle => '_${field.name}Value',
      _WidgetKind.datePicker => '_${field.name}Value ?? DateTime.now()',
      _WidgetKind.dropdown =>
        '_${field.name}Value ?? ${field.dartType}.values.first',
      _ => switch (field.dartType) {
          'int' => 'int.parse(_${field.name}Controller.text)',
          'double' => 'double.parse(_${field.name}Controller.text)',
          'num' => 'num.parse(_${field.name}Controller.text)',
          _ => '_${field.name}Controller.text',
        },
    };
  }

  /// Returns a Dart literal that is a valid "empty" value for [field]'s type.
  String _zeroValue(FieldManifest field) {
    return switch (field.dartType) {
      'int' => '0',
      'double' => '0.0',
      'num' => '0',
      'bool' => 'false',
      'String' => "''",
      'DateTime' => 'DateTime.now()',
      _ => field.isEnum ? '${field.dartType}.values.first' : 'null',
    };
  }

  // ---------------------------------------------------------------------------
  // _prefillControllers method generation
  // ---------------------------------------------------------------------------

  void _writePrefillControllers(EntityManifest manifest, StringBuffer buffer) {
    final entity = manifest.entityName;
    final fields = manifest.formFields;

    buffer.writeln('  void _prefillControllers($entity item) {');
    for (final field in fields) {
      final kind = _resolveWidgetKind(field);
      switch (kind) {
        case _WidgetKind.toggle:
          buffer.writeln('    _${field.name}Value = item.${field.name};');
        case _WidgetKind.datePicker:
          buffer.writeln('    _${field.name}Value = item.${field.name};');
          buffer.writeln(
              '    _${field.name}Controller.text = item.${field.name}.toIso8601String();');
        case _WidgetKind.dropdown:
          buffer.writeln('    _${field.name}Value = item.${field.name};');
        default:
          // text, multilineText, password
          if (field.dartType == 'String') {
            buffer
                .writeln('    _${field.name}Controller.text = item.${field.name};');
          } else {
            buffer.writeln(
                '    _${field.name}Controller.text = item.${field.name}.toString();');
          }
      }
    }
    buffer.writeln('  }');
  }

  // ---------------------------------------------------------------------------
  // Individual form field — dispatches to the correct widget writer
  // ---------------------------------------------------------------------------

  void _writeFormField(FieldManifest field, StringBuffer buffer) {
    switch (_resolveWidgetKind(field)) {
      case _WidgetKind.toggle:
        _writeSwitchField(field, buffer);
      case _WidgetKind.datePicker:
        _writeDatePickerField(field, buffer);
      case _WidgetKind.dropdown:
        _writeDropdownField(field, buffer);
      case _WidgetKind.multilineText:
        _writeMultilineTextField(field, buffer);
      case _WidgetKind.password:
        _writePasswordField(field, buffer);
      case _WidgetKind.text:
        _writeTextField(field, buffer);
    }
  }

  void _writeTextField(FieldManifest field, StringBuffer buffer) {
    buffer.writeln('            TextFormField(');
    buffer.writeln('              controller: _${field.name}Controller,');
    buffer.writeln(
        "              decoration: const InputDecoration(labelText: '${field.label}'),");
    _writeValidators(field, buffer);
    buffer.writeln('            ),');
  }

  void _writeMultilineTextField(FieldManifest field, StringBuffer buffer) {
    buffer.writeln('            TextFormField(');
    buffer.writeln('              controller: _${field.name}Controller,');
    buffer.writeln('              maxLines: null,');
    buffer.writeln('              keyboardType: TextInputType.multiline,');
    buffer.writeln(
        "              decoration: const InputDecoration(labelText: '${field.label}'),");
    _writeValidators(field, buffer);
    buffer.writeln('            ),');
  }

  void _writePasswordField(FieldManifest field, StringBuffer buffer) {
    buffer.writeln('            TextFormField(');
    buffer.writeln('              controller: _${field.name}Controller,');
    buffer.writeln('              obscureText: true,');
    buffer.writeln(
        "              decoration: const InputDecoration(labelText: '${field.label}'),");
    _writeValidators(field, buffer);
    buffer.writeln('            ),');
  }

  void _writeDatePickerField(FieldManifest field, StringBuffer buffer) {
    buffer.writeln('            TextFormField(');
    buffer.writeln('              controller: _${field.name}Controller,');
    buffer.writeln('              readOnly: true,');
    buffer.writeln(
        "              decoration: const InputDecoration(labelText: '${field.label}'),");
    buffer.writeln('              onTap: () async {');
    buffer.writeln('                final picked = await showDatePicker(');
    buffer.writeln('                  context: context,');
    buffer.writeln(
        '                  initialDate: _${field.name}Value ?? DateTime.now(),');
    buffer.writeln('                  firstDate: DateTime(2000),');
    buffer.writeln('                  lastDate: DateTime(2100),');
    buffer.writeln('                );');
    buffer.writeln('                if (picked != null) {');
    buffer.writeln('                  setState(() {');
    buffer.writeln('                    _${field.name}Value = picked;');
    buffer.writeln(
        '                    _${field.name}Controller.text = picked.toIso8601String();');
    buffer.writeln('                  });');
    buffer.writeln('                }');
    buffer.writeln('              },');
    _writeValidators(field, buffer);
    buffer.writeln('            ),');
  }

  void _writeDropdownField(FieldManifest field, StringBuffer buffer) {
    final type = field.dartType;
    buffer.writeln('            DropdownButtonFormField<$type>(');
    buffer.writeln('              value: _${field.name}Value,');
    buffer.writeln(
        "              decoration: const InputDecoration(labelText: '${field.label}'),");
    buffer.writeln(
        '              items: $type.values.map((v) => DropdownMenuItem<$type>(');
    buffer.writeln('                value: v,');
    buffer.writeln('                child: Text(v.name),');
    buffer.writeln('              )).toList(),');
    buffer.writeln(
        '              onChanged: (v) => setState(() => _${field.name}Value = v),');
    _writeValidators(field, buffer);
    buffer.writeln('            ),');
  }

  void _writeSwitchField(FieldManifest field, StringBuffer buffer) {
    buffer.writeln('            SwitchListTile(');
    buffer.writeln("              title: const Text('${field.label}'),");
    buffer.writeln('              value: _${field.name}Value,');
    buffer.writeln(
        '              onChanged: (v) => setState(() => _${field.name}Value = v),');
    buffer.writeln('            ),');
  }

  // ---------------------------------------------------------------------------
  // Validator check lines
  // ---------------------------------------------------------------------------

  void _writeValidators(FieldManifest field, StringBuffer buffer) {
    if (field.validators.isEmpty) return;
    buffer.writeln('              validator: (value) {');
    for (final validator in field.validators) {
      _writeValidatorCheck(validator, buffer);
    }
    buffer.writeln('                return null;');
    buffer.writeln('              },');
  }

  void _writeValidatorCheck(Validator validator, StringBuffer buffer) {
    switch (validator) {
      case Validator.required:
        buffer.writeln(
            "                if (value == null || value.isEmpty) return 'Required';");
      case Validator.email:
        buffer.writeln(
            r"                if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value ?? '')) return 'Invalid email address';");
      case Validator.positiveNumber:
        buffer.writeln(
            "                final n = double.tryParse(value ?? '');");
        buffer.writeln(
            "                if (n == null || n <= 0) return 'Must be a positive number';");
      case Validator.url:
        buffer.writeln(
            "                final uri = Uri.tryParse(value ?? '');");
        buffer.writeln(
            "                if (uri == null || !uri.isAbsolute) return 'Invalid URL';");
    }
  }
}
