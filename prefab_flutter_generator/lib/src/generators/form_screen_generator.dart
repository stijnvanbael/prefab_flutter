import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:prefab_flutter/prefab_flutter.dart';
import 'package:source_gen/source_gen.dart';

import '../manifest/entity_manifest.dart';
import '../manifest/field_manifest.dart';

const _viewChecker = TypeChecker.fromRuntime(View);

/// Resolved widget kind after applying [FieldWidget.auto] type inference.
enum _WidgetKind { text, multilineText, password, datePicker, dropdown, toggle }

/// Generates `{Entity}CreateScreen` and `{Entity}EditScreen` [ConsumerWidget]s
/// for every class annotated with [@View] that also carries [@Update].
class FormScreenGenerator extends Generator {
  @override
  String generate(LibraryReader library, BuildStep buildStep) {
    final manifests = <EntityManifest>[];
    final all = <EntityManifest>[];
    for (final a in library.annotatedWith(_viewChecker)) {
      final element = a.element;
      if (element is! ClassElement) {
        throw InvalidGenerationSourceError(
          '@View can only be applied to classes.',
          element: element,
        );
      }
      final manifest = EntityManifest.from(element, a.annotation);
      all.add(manifest);
      // Only generate form screens when @Update is present.
      if (manifest.hasUpdate) manifests.add(manifest);
    }
    if (manifests.isEmpty) return '';

    final sourceFileName = buildStep.inputId.path.split('/').last;
    final buffer = StringBuffer();
    _writeHeader(buffer);
    _writeImports(sourceFileName, buffer);
    for (final manifest in manifests) {
      buffer.writeln();
      _writeCreateScreen(manifest, buffer);
      buffer.writeln();
      _writeEditScreen(manifest, buffer);
    }
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
    buffer.writeln("import 'package:material_ui/material_ui.dart';");
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
    if (manifest.hasParent) {
      buffer.writeln(
          '  final ${manifest.parentField!.dartType} ${manifest.parentParamName};');
      buffer.writeln();
      buffer.writeln(
          '  const ${entity}CreateScreen({super.key, required this.${manifest.parentParamName}});');
    } else {
      buffer.writeln('  const ${entity}CreateScreen({super.key});');
    }
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

    buffer
        .writeln('class ${entity}EditScreen extends ConsumerStatefulWidget {');
    buffer.writeln('  final ${manifest.idType} id;');
    buffer.writeln();
    if (manifest.hasParent) {
      buffer.writeln(
          '  final ${manifest.parentField!.dartType} ${manifest.parentParamName};');
      buffer.writeln();
      buffer.writeln(
          '  const ${entity}EditScreen({super.key, required this.id, required this.${manifest.parentParamName}});');
    } else {
      buffer.writeln(
          '  const ${entity}EditScreen({super.key, required this.id});');
    }
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
          buffer.writeln(field.isNullable
              ? '  bool? _${field.name}Value;'
              : '  bool _${field.name}Value = false;');
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
    _writeSaveButton(saveButtonLabel, buffer);
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

    final detailArg = manifest.hasParent
        ? '((widget.id, widget.${manifest.parentParamName}))'
        : '(widget.id)';
    buffer.writeln(
        '    final asyncItem = ref.watch(${entityLower}DetailProvider$detailArg);');
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
    buffer
        .writeln('        error: (e, _) => Center(child: Text(e.toString())),');
    buffer.writeln('        data: (_) => Form(');
    buffer.writeln('          key: _formKey,');
    buffer.writeln('          child: ListView(');
    buffer.writeln('            padding: const EdgeInsets.all(16),');
    buffer.writeln('            children: [');
    for (final field in manifest.formFields) {
      _writeFormField(field, buffer);
    }
    _writeSaveButton(saveButtonLabel, buffer);
    buffer.writeln('            ],');
    buffer.writeln('          ),');
    buffer.writeln('        ),');
    buffer.writeln('      ),');
    buffer.writeln('    );');
  }

  void _writeSaveButton(String saveButtonLabel, StringBuffer buffer) {
    buffer.writeln('            ElevatedButton(');
    buffer.writeln('              onPressed: () {');
    buffer.writeln('                if (_formKey.currentState!.validate()) {');
    buffer.writeln('                  context.pop();');
    buffer.writeln('                }');
    buffer.writeln('              },');
    buffer.writeln("              child: const Text('$saveButtonLabel'),");
    buffer.writeln('            ),');
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
          final iso = field.isNullable
              ? "item.${field.name}?.toIso8601String() ?? ''"
              : 'item.${field.name}.toIso8601String()';
          buffer.writeln('    _${field.name}Controller.text = $iso;');
        case _WidgetKind.dropdown:
          buffer.writeln('    _${field.name}Value = item.${field.name};');
        default:
          // text, multilineText, password
          final String expr;
          if (field.dartType == 'String') {
            expr = field.isNullable
                ? "item.${field.name} ?? ''"
                : 'item.${field.name}';
          } else {
            expr = field.isNullable
                ? "item.${field.name}?.toString() ?? ''"
                : 'item.${field.name}.toString()';
          }
          buffer.writeln('    _${field.name}Controller.text = $expr;');
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
    buffer.writeln('              items: [');
    if (field.isNullable) {
      buffer.writeln(
          "                const DropdownMenuItem<$type>(value: null, child: Text('')),");
    }
    buffer.writeln(
        '                ...$type.values.map((v) => DropdownMenuItem<$type>(');
    buffer.writeln('                  value: v,');
    buffer.writeln('                  child: Text(v.name),');
    buffer.writeln('                )),');
    buffer.writeln('              ],');
    buffer.writeln(
        '              onChanged: (v) => setState(() => _${field.name}Value = v),');
    if (field.isRequired) {
      buffer.writeln(
          "              validator: (value) => value == null ? 'Required' : null,");
    }
    buffer.writeln('            ),');
  }

  void _writeSwitchField(FieldManifest field, StringBuffer buffer) {
    if (field.isNullable) {
      // Nullable bool: dropdown with an empty (null) option.
      buffer.writeln('            DropdownButtonFormField<bool>(');
      buffer.writeln('              value: _${field.name}Value,');
      buffer.writeln(
          "              decoration: const InputDecoration(labelText: '${field.label}'),");
      buffer.writeln('              items: const [');
      buffer.writeln(
          "                DropdownMenuItem<bool>(value: null, child: Text('')),");
      buffer.writeln(
          "                DropdownMenuItem<bool>(value: true, child: Text('Yes')),");
      buffer.writeln(
          "                DropdownMenuItem<bool>(value: false, child: Text('No')),");
      buffer.writeln('              ],');
      buffer.writeln(
          '              onChanged: (v) => setState(() => _${field.name}Value = v),');
      if (field.validators.contains(Validator.required)) {
        buffer.writeln(
            "              validator: (value) => value == null ? 'Required' : null,");
      }
      buffer.writeln('            ),');
      return;
    }
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
    final validators = [
      if (field.isRequired && !field.validators.contains(Validator.required))
        Validator.required,
      ...field.validators,
    ];
    if (validators.isEmpty) return;
    buffer.writeln('              validator: (value) {');
    if (!field.isRequired) {
      // Optional field: an empty value is valid, skip the other checks.
      buffer.writeln(
          "                if (value == null || value.isEmpty) return null;");
    }
    for (final validator in validators) {
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
        buffer
            .writeln("                final n = double.tryParse(value ?? '');");
        buffer.writeln(
            "                if (n == null || n <= 0) return 'Must be a positive number';");
      case Validator.url:
        buffer
            .writeln("                final uri = Uri.tryParse(value ?? '');");
        buffer.writeln(
            "                if (uri == null || !uri.isAbsolute) return 'Invalid URL';");
    }
  }
}
