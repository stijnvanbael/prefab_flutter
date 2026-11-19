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
      'class ${entity}CreateScreen extends ConsumerStatefulWidget {',
    );
    if (manifest.hasParent) {
      buffer.writeln(
        '  final ${manifest.parentField!.dartType} ${manifest.parentParamName};',
      );
      buffer.writeln();
      buffer.writeln(
        '  const ${entity}CreateScreen({super.key, required this.${manifest.parentParamName}});',
      );
    } else {
      buffer.writeln('  const ${entity}CreateScreen({super.key});');
    }
    buffer.writeln();
    buffer.writeln('  @override');
    buffer.writeln(
      '  ConsumerState<${entity}CreateScreen> createState() => _${entity}CreateScreenState();',
    );
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

    buffer.writeln(
      'class ${entity}EditScreen extends ConsumerStatefulWidget {',
    );
    buffer.writeln('  final ${manifest.idType} id;');
    buffer.writeln();
    if (manifest.hasParent) {
      buffer.writeln(
        '  final ${manifest.parentField!.dartType} ${manifest.parentParamName};',
      );
      buffer.writeln();
      buffer.writeln(
        '  const ${entity}EditScreen({super.key, required this.id, required this.${manifest.parentParamName}});',
      );
    } else {
      buffer.writeln(
        '  const ${entity}EditScreen({super.key, required this.id});',
      );
    }
    buffer.writeln();
    buffer.writeln('  @override');
    buffer.writeln(
      '  ConsumerState<${entity}EditScreen> createState() => _${entity}EditScreenState();',
    );
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
      'class $stateClassName extends ConsumerState<$widgetClassName> {',
    );
    buffer.writeln('  final _formKey = GlobalKey<FormState>();');

    buffer.writeln('  bool _saving = false;');
    if (isEdit) {
      buffer.writeln('  bool _prefilled = false;');
      buffer.writeln('  // ignore: unused_field');
      buffer.writeln('  ${manifest.entityName}? _item;');
    }

    for (final field in fields) {
      final kind = _resolveWidgetKind(field);
      switch (kind) {
        case _WidgetKind.toggle:
          buffer.writeln(
            field.isNullable
                ? '  bool? _${field.name}Value;'
                : '  bool _${field.name}Value = false;',
          );
        case _WidgetKind.datePicker:
          buffer.writeln(
            '  final _${field.name}Controller = TextEditingController();',
          );
          buffer.writeln('  DateTime? _${field.name}Value;');
        case _WidgetKind.dropdown:
          buffer.writeln('  ${field.dartType}? _${field.name}Value;');
        default:
          buffer.writeln(
            '  final _${field.name}Controller = TextEditingController();',
          );
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
    _writeSaveMethod(manifest, isEdit, buffer);

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
    EntityManifest manifest,
    String saveButtonLabel,
    StringBuffer buffer,
  ) {
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
    EntityManifest manifest,
    String saveButtonLabel,
    StringBuffer buffer,
  ) {
    final entityLower = manifest.entityNameLower;

    final detailArg = manifest.hasParent
        ? '((widget.id, widget.${manifest.parentParamName}))'
        : '(widget.id)';
    buffer.writeln(
      '    final asyncItem = ref.watch(${entityLower}DetailProvider$detailArg);',
    );
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
      '        loading: () => const Center(child: CircularProgressIndicator()),',
    );
    buffer.writeln(
      '        error: (e, _) => Center(child: Text(e.toString())),',
    );
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
    buffer.writeln('              onPressed: _saving ? null : _save,');
    buffer.writeln('              child: _saving');
    buffer.writeln('                  ? const SizedBox(');
    buffer.writeln('                      width: 20,');
    buffer.writeln('                      height: 20,');
    buffer.writeln(
        '                      child: CircularProgressIndicator(strokeWidth: 2),');
    buffer.writeln('                    )');
    buffer.writeln("                  : const Text('$saveButtonLabel'),");
    buffer.writeln('            ),');
  }

  // ---------------------------------------------------------------------------
  // _save method generation
  // ---------------------------------------------------------------------------

  void _writeSaveMethod(
      EntityManifest manifest, bool isEdit, StringBuffer buffer) {
    final entity = manifest.entityName;
    final providerArgs =
        manifest.hasParent ? '(widget.${manifest.parentParamName})' : '';
    final provider = '${manifest.entityNameLower}sProvider$providerArgs';
    final mutation = isEdit ? 'updateEntity' : 'create';

    final arguments = _buildConstructorArguments(manifest, isEdit);

    buffer.writeln('  Future<void> _save() async {');
    buffer.writeln('    if (!_formKey.currentState!.validate()) return;');
    buffer.writeln('    setState(() => _saving = true);');
    buffer.writeln(
        '    // Keep the (auto-dispose) provider alive while the request runs.');
    buffer.writeln(
        '    final subscription = ref.listenManual($provider, (_, __) {});');
    buffer.writeln('    try {');
    buffer.writeln('      final entity = $entity(');
    for (final argument in arguments) {
      buffer.writeln('        $argument,');
    }
    buffer.writeln('      );');
    buffer
        .writeln('      await ref.read($provider.notifier).$mutation(entity);');
    buffer.writeln('      if (!mounted) return;');
    buffer.writeln('      context.pop();');
    buffer.writeln('    } catch (e) {');
    buffer.writeln('      if (!mounted) return;');
    buffer.writeln('      setState(() => _saving = false);');
    buffer.writeln(
        '      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));');
    buffer.writeln('    } finally {');
    buffer.writeln('      subscription.close();');
    buffer.writeln('    }');
    buffer.writeln('  }');
  }

  /// Maps every parameter of the entity's unnamed constructor to a source
  /// expression and returns the call arguments in declaration order.
  ///
  /// Sources: the id (`widget.id` on edit, omitted on create), the parent id
  /// (`widget.<parent>`), a form field (typed form state), or — for hidden and
  /// un-annotated fields — the loaded item on edit. A required parameter with
  /// no source is a build-time error.
  List<String> _buildConstructorArguments(
      EntityManifest manifest, bool isEdit) {
    final params = manifest.constructorParams;
    if (params == null) {
      throw InvalidGenerationSourceError(
        '${manifest.entityName} needs an unnamed constructor so the generated '
        'form can create instances.',
      );
    }
    final formFields = {for (final f in manifest.formFields) f.name: f};
    final arguments = <String>[];
    for (final param in params) {
      final String? expression;
      if (param.name == manifest.idFieldName) {
        expression = isEdit ? 'widget.id' : null;
      } else if (param.name == manifest.parentParamName) {
        expression = 'widget.${param.name}';
      } else if (formFields.containsKey(param.name)) {
        expression = _formValueExpression(formFields[param.name]!);
      } else {
        expression = isEdit ? '_item!.${param.name}' : null;
      }

      if (expression == null) {
        // No source: the parameter must be optional (or nullable) so it can
        // be omitted / passed as null.
        if (param.isRequired && !param.isNullable) {
          throw InvalidGenerationSourceError(
            'Cannot build ${manifest.entityName} in the create form: the '
            'constructor parameter "${param.name}" is required but has no '
            'value source. Make it nullable or give it a default value, or '
            'expose it with @Field.',
          );
        }
        if (!param.isNamed) {
          if (param.hasDefault && !param.isNullable) {
            throw InvalidGenerationSourceError(
              'Cannot build ${manifest.entityName} in the create form: the '
              'optional positional parameter "${param.name}" has no value '
              'source. Make it a named parameter.',
            );
          }
          arguments.add('null');
        }
        continue;
      }
      arguments.add(param.isNamed ? '${param.name}: $expression' : expression);
    }
    return arguments;
  }

  /// Dart expression that turns the form state of [field] into a typed value.
  String _formValueExpression(FieldManifest field) {
    final name = field.name;
    switch (_resolveWidgetKind(field)) {
      case _WidgetKind.toggle:
        return '_${name}Value';
      case _WidgetKind.datePicker:
        return field.isNullable ? '_${name}Value' : '_${name}Value!';
      case _WidgetKind.dropdown:
        return field.isNullable ? '_${name}Value' : '_${name}Value!';
      default:
        final text = '_${name}Controller.text';
        final String parsed;
        switch (field.dartType) {
          case 'String':
            parsed = text;
          case 'int':
          case 'double':
          case 'num':
            parsed = '${field.dartType}.parse($text)';
          default:
            throw InvalidGenerationSourceError(
              'Field "${field.name}" has type ${field.dartType}, which the '
              'generated form cannot convert from text. Supported types are '
              'String, int, double, num, bool, DateTime and enums.',
            );
        }
        return field.isNullable ? '$text.isEmpty ? null : $parsed' : parsed;
    }
  }

  // ---------------------------------------------------------------------------
  // _prefillControllers method generation
  // ---------------------------------------------------------------------------

  void _writePrefillControllers(EntityManifest manifest, StringBuffer buffer) {
    final entity = manifest.entityName;
    final fields = manifest.formFields;

    buffer.writeln('  void _prefillControllers($entity item) {');
    buffer.writeln('    _item = item;');
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
      "              decoration: const InputDecoration(labelText: '${field.label}'),",
    );
    _writeValidators(field, buffer);
    buffer.writeln('            ),');
  }

  void _writeMultilineTextField(FieldManifest field, StringBuffer buffer) {
    buffer.writeln('            TextFormField(');
    buffer.writeln('              controller: _${field.name}Controller,');
    buffer.writeln('              maxLines: null,');
    buffer.writeln('              keyboardType: TextInputType.multiline,');
    buffer.writeln(
      "              decoration: const InputDecoration(labelText: '${field.label}'),",
    );
    _writeValidators(field, buffer);
    buffer.writeln('            ),');
  }

  void _writePasswordField(FieldManifest field, StringBuffer buffer) {
    buffer.writeln('            TextFormField(');
    buffer.writeln('              controller: _${field.name}Controller,');
    buffer.writeln('              obscureText: true,');
    buffer.writeln(
      "              decoration: const InputDecoration(labelText: '${field.label}'),",
    );
    _writeValidators(field, buffer);
    buffer.writeln('            ),');
  }

  void _writeDatePickerField(FieldManifest field, StringBuffer buffer) {
    buffer.writeln('            TextFormField(');
    buffer.writeln('              controller: _${field.name}Controller,');
    buffer.writeln('              readOnly: true,');
    buffer.writeln(
      "              decoration: const InputDecoration(labelText: '${field.label}'),",
    );
    buffer.writeln('              onTap: () async {');
    buffer.writeln('                final picked = await showDatePicker(');
    buffer.writeln('                  context: context,');
    buffer.writeln(
      '                  initialDate: _${field.name}Value ?? DateTime.now(),',
    );
    buffer.writeln('                  firstDate: DateTime(2000),');
    buffer.writeln('                  lastDate: DateTime(2100),');
    buffer.writeln('                );');
    buffer.writeln('                if (picked != null) {');
    buffer.writeln('                  setState(() {');
    buffer.writeln('                    _${field.name}Value = picked;');
    buffer.writeln(
      '                    _${field.name}Controller.text = picked.toIso8601String();',
    );
    buffer.writeln('                  });');
    buffer.writeln('                }');
    buffer.writeln('              },');
    _writeValidators(field, buffer);
    buffer.writeln('            ),');
  }

  void _writeDropdownField(FieldManifest field, StringBuffer buffer) {
    _checkValidatorsFor(field);
    final type = field.dartType;
    buffer.writeln('            DropdownButtonFormField<$type>(');
    buffer.writeln('              value: _${field.name}Value,');
    buffer.writeln(
      "              decoration: const InputDecoration(labelText: '${field.label}'),",
    );
    buffer.writeln('              items: [');
    if (field.isNullable) {
      buffer.writeln(
        "                const DropdownMenuItem<$type>(value: null, child: Text('')),",
      );
    }
    buffer.writeln(
      '                ...$type.values.map((v) => DropdownMenuItem<$type>(',
    );
    buffer.writeln('                  value: v,');
    buffer.writeln('                  child: Text(v.name),');
    buffer.writeln('                )),');
    buffer.writeln('              ],');
    buffer.writeln(
      '              onChanged: (v) => setState(() => _${field.name}Value = v),',
    );
    if (field.isRequired) {
      buffer.writeln(
        "              validator: (value) => value == null ? ${_requiredMessage(field)} : null,",
      );
    }
    buffer.writeln('            ),');
  }

  void _writeSwitchField(FieldManifest field, StringBuffer buffer) {
    _checkValidatorsFor(field);
    if (field.isNullable) {
      // Nullable bool: dropdown with an empty (null) option.
      buffer.writeln('            DropdownButtonFormField<bool>(');
      buffer.writeln('              value: _${field.name}Value,');
      buffer.writeln(
        "              decoration: const InputDecoration(labelText: '${field.label}'),",
      );
      buffer.writeln('              items: const [');
      buffer.writeln(
        "                DropdownMenuItem<bool>(value: null, child: Text('')),",
      );
      buffer.writeln(
        "                DropdownMenuItem<bool>(value: true, child: Text('Yes')),",
      );
      buffer.writeln(
        "                DropdownMenuItem<bool>(value: false, child: Text('No')),",
      );
      buffer.writeln('              ],');
      buffer.writeln(
        '              onChanged: (v) => setState(() => _${field.name}Value = v),',
      );
      if (field.validators.any((v) => v is RequiredValidator)) {
        buffer.writeln(
          "              validator: (value) => value == null ? ${_requiredMessage(field)} : null,",
        );
      }
      buffer.writeln('            ),');
      return;
    }
    buffer.writeln('            SwitchListTile(');
    buffer.writeln("              title: const Text('${field.label}'),");
    buffer.writeln('              value: _${field.name}Value,');
    buffer.writeln(
      '              onChanged: (v) => setState(() => _${field.name}Value = v),',
    );
    buffer.writeln('            ),');
  }

  // ---------------------------------------------------------------------------
  // Validator check lines
  // ---------------------------------------------------------------------------

  /// Escapes [value] as a single-quoted Dart string literal.
  String _lit(String value) {
    final escaped = value
        .replaceAll(r'\', r'\\')
        .replaceAll("'", r"\'")
        .replaceAll(r'$', r'\$')
        .replaceAll('\n', r'\n')
        .replaceAll('\r', r'\r');
    return "'$escaped'";
  }

  /// Rejects text-only validators on widgets that are not text inputs.
  void _checkValidatorsFor(FieldManifest field) {
    final kind = _resolveWidgetKind(field);
    final isText = kind == _WidgetKind.text ||
        kind == _WidgetKind.multilineText ||
        kind == _WidgetKind.password;
    if (isText) return;
    for (final v in field.validators) {
      if (v is! RequiredValidator) {
        throw InvalidGenerationSourceError(
          '${v.runtimeType} cannot be used on "${field.name}" because it '
          'renders as a ${kind.name} field. Only Validator.required is '
          'supported there.',
        );
      }
    }
  }

  /// Quoted message of the `required` check (custom or `'Required'`).
  String _requiredMessage(FieldManifest field) => _lit(
        field.validators
                .whereType<RequiredValidator>()
                .map((v) => v.message)
                .firstOrNull ??
            'Required',
      );

  void _writeValidators(FieldManifest field, StringBuffer buffer) {
    _checkValidatorsFor(field);
    // `required` always runs first (or an empty-is-valid guard for optional
    // fields), so `value` is promoted to a non-null String for the others.
    final others =
        field.validators.where((v) => v is! RequiredValidator).toList();
    final numeric = _isNumericText(field);
    if (!field.isRequired && others.isEmpty && !numeric) return;
    buffer.writeln('              validator: (value) {');
    if (field.isRequired) {
      buffer.writeln(
        "                if (value == null || value.isEmpty) return ${_requiredMessage(field)};",
      );
    } else {
      // Optional field: an empty value is valid, skip the other checks.
      buffer.writeln(
        "                if (value == null || value.isEmpty) return null;",
      );
    }
    if (numeric) {
      // Parseability check so the save handler can parse safely.
      final isInt = field.dartType == 'int';
      buffer.writeln(
        "                if (${field.dartType}.tryParse(value) == null) return '${isInt ? 'Must be a whole number' : 'Must be a number'}';",
      );
    }
    for (final validator in others) {
      _writeValidatorCheck(validator, buffer);
    }
    buffer.writeln('                return null;');
    buffer.writeln('              },');
  }

  bool _isNumericText(FieldManifest field) =>
      _resolveWidgetKind(field) == _WidgetKind.text &&
      const {'int', 'double', 'num'}.contains(field.dartType);

  void _writeValidatorCheck(Validator validator, StringBuffer buffer) {
    String msg(String fallback) => _lit(validator.message ?? fallback);
    const i = '                ';
    switch (validator) {
      case RequiredValidator():
        break; // handled by _writeValidators
      case EmailValidator():
        buffer.writeln(
          "${i}if (!RegExp(r'^[^@\\s]+@[^@\\s]+\\.[^@\\s]+\$').hasMatch(value)) return ${msg('Invalid email address')};",
        );
      case UrlValidator():
        buffer.writeln('$i{');
        buffer.writeln('$i  final uri = Uri.tryParse(value);');
        buffer.writeln(
          "$i  if (uri == null || !uri.isAbsolute) return ${msg('Invalid URL')};",
        );
        buffer.writeln('$i}');
      case PositiveValidator():
        _writeNumberCheck(buffer, '<= 0', msg('Must be a positive number'));
      case NonNegativeValidator():
        _writeNumberCheck(buffer, '< 0', msg('Must not be negative'));
      case MinValidator(:final value):
        _writeNumberCheck(buffer, '< $value', msg('Must be at least $value'));
      case MaxValidator(:final value):
        _writeNumberCheck(buffer, '> $value', msg('Must be at most $value'));
      case MinLengthValidator(:final length):
        buffer.writeln(
          "${i}if (value.length < $length) return ${msg('Must be at least $length characters')};",
        );
      case MaxLengthValidator(:final length):
        buffer.writeln(
          "${i}if (value.length > $length) return ${msg('Must be at most $length characters')};",
        );
      case PatternValidator(:final regex):
        buffer.writeln(
          "${i}if (!RegExp(${_lit(regex)}).hasMatch(value)) return ${msg('Invalid format')};",
        );
    }
  }

  void _writeNumberCheck(StringBuffer buffer, String failWhen, String message) {
    const i = '                ';
    buffer.writeln('$i{');
    buffer.writeln('$i  final n = double.tryParse(value);');
    buffer.writeln('$i  if (n == null || n $failWhen) return $message;');
    buffer.writeln('$i}');
  }
}
