import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:prefab_flutter/prefab_flutter.dart';
import 'package:source_gen/source_gen.dart';

import '../manifest/entity_manifest.dart';
import '../manifest/field_manifest.dart';

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
    buffer.writeln("import 'package:flutter/material.dart';");
    buffer.writeln("import 'package:flutter_riverpod/flutter_riverpod.dart';");
    buffer.writeln("import 'package:go_router/go_router.dart';");
    buffer.writeln("import '$sourceFileName';");
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
    required StringBuffer buffer,
  }) {
    final fields = manifest.formFields;

    buffer.writeln(
        'class $stateClassName extends ConsumerState<$widgetClassName> {');
    buffer.writeln('  final _formKey = GlobalKey<FormState>();');

    for (final field in fields) {
      buffer.writeln(
          '  final _${field.name}Controller = TextEditingController();');
    }

    buffer.writeln();
    buffer.writeln('  @override');
    buffer.writeln('  void dispose() {');
    for (final field in fields) {
      buffer.writeln('    _${field.name}Controller.dispose();');
    }
    buffer.writeln('    super.dispose();');
    buffer.writeln('  }');
    buffer.writeln();
    buffer.writeln('  @override');
    buffer.writeln('  Widget build(BuildContext context) {');
    buffer.writeln('    return Scaffold(');
    buffer.writeln('      appBar: AppBar(');
    buffer.writeln("        title: const Text('${manifest.title}'),");
    buffer.writeln('      ),');
    buffer.writeln('      body: Form(');
    buffer.writeln('        key: _formKey,');
    buffer.writeln('        child: ListView(');
    buffer.writeln('          padding: const EdgeInsets.all(16),');
    buffer.writeln('          children: [');

    for (final field in fields) {
      _writeFormField(field, buffer);
    }

    buffer.writeln('            ElevatedButton(');
    buffer.writeln('              onPressed: () {');
    buffer.writeln('                if (_formKey.currentState!.validate()) {');
    buffer.writeln('                  context.pop();');
    buffer.writeln('                }');
    buffer.writeln('              },');
    buffer.writeln("              child: const Text('$saveButtonLabel'),");
    buffer.writeln('            ),');
    buffer.writeln('          ],');
    buffer.writeln('        ),');
    buffer.writeln('      ),');
    buffer.writeln('    );');
    buffer.writeln('  }');
    buffer.writeln('}');
  }

  // ---------------------------------------------------------------------------
  // Individual form field
  // ---------------------------------------------------------------------------

  void _writeFormField(FieldManifest field, StringBuffer buffer) {
    buffer.writeln('            TextFormField(');
    buffer.writeln(
        '              controller: _${field.name}Controller,');
    buffer.writeln(
        "              decoration: const InputDecoration(labelText: '${field.label}'),");

    if (field.validators.isNotEmpty) {
      buffer.writeln('              validator: (value) {');
      for (final validator in field.validators) {
        _writeValidatorCheck(validator, buffer);
      }
      buffer.writeln('                return null;');
      buffer.writeln('              },');
    }

    buffer.writeln('            ),');
  }

  // ---------------------------------------------------------------------------
  // Validator check lines
  // ---------------------------------------------------------------------------

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
            "                if (double.tryParse(value ?? '') == null || double.parse(value!) <= 0) return 'Must be a positive number';");
      case Validator.url:
        buffer.writeln(
            "                final uri = Uri.tryParse(value ?? '');");
        buffer.writeln(
            "                if (uri == null || !uri.isAbsolute) return 'Invalid URL';");
    }
  }
}
