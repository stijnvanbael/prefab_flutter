import 'package:source_gen/source_gen.dart';

import '../core/artifact.dart';
import '../core/artifact_generator.dart';
import '../core/code.dart';
import '../core/entity_context.dart';
import '../features/features.dart';
import '../features/field_widgets/field_widgets_feature.dart';
import '../manifest/entity_manifest.dart';
import '../features/validators/validator_emitters.dart' show dartStringLiteral;
import '../manifest/field_manifest.dart';

/// The `{Entity}CreateScreen` and `{Entity}EditScreen` widgets come from the
/// create and update features (`lib/src/features/create/` and `update/`);
/// this library holds the template they share: the form state class with the
/// fields, validation and the save method.
class FormScreenGenerator extends ArtifactGenerator {
  FormScreenGenerator()
      : super('FormScreenGenerator', const [],
            features: registeredFeatures,
            kinds: {ArtifactKind.createScreen, ArtifactKind.editScreen});
}

/// The templates shared by the create and the edit screen of one entity.
abstract class FormScreenArtifact extends Artifact {
  FormScreenArtifact(this.entity);

  final EntityContext entity;

  EntityManifest get manifest => entity.manifest;

  /// The libraries the fragments written so far need.
  final _imports = <String>{
    Libs.materialUi,
    Libs.riverpod,
    Libs.goRouter,
    Libs.widgets,
  };

  /// `required this.orderId, required this.orderLineId`.
  static String requiredThis(EntityManifest manifest) => manifest.ancestors
      .map((a) => 'required this.${a.paramName}')
      .join(', ');

  Code code(StringBuffer buffer) => Code(
        buffer.toString().trim(),
        imports: {..._imports, entity.sourceFileName},
      );

  /// The fields of the edit form, or of the create form.
  List<FieldManifest> _fieldsOf(bool isEdit) =>
      isEdit ? manifest.updateFormFields : manifest.createFormFields;

  FormFieldEmitter _emitter(FieldManifest field) =>
      formFieldEmitters.resolve(field);

  // ---------------------------------------------------------------------------
  // Shared state class
  // ---------------------------------------------------------------------------

  void writeScreenState({
    required EntityManifest manifest,
    required String stateClassName,
    required String widgetClassName,
    required String saveButtonLabel,
    required bool isEdit,
    required StringBuffer buffer,
  }) {
    final fields = _fieldsOf(isEdit);

    buffer.writeln(
      'class $stateClassName extends ConsumerState<$widgetClassName> {',
    );
    buffer.writeln('  final _formKey = GlobalKey<FormState>();');

    buffer.writeln('  bool _saving = false;');
    buffer.writeln('  final _formErrors = PrefabFormErrors();');
    if (isEdit) {
      buffer.writeln('  bool _prefilled = false;');
      buffer.writeln('  // ignore: unused_field');
      buffer.writeln('  ${manifest.entityName}? _item;');
    }

    for (final field in fields) {
      _write(_emitter(field).stateDeclaration(field), buffer);
    }

    buffer.writeln();
    buffer.writeln('  @override');
    buffer.writeln('  void dispose() {');
    buffer.writeln('    _formErrors.dispose();');
    for (final field in fields) {
      if (_emitter(field).usesController) {
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
    buffer.writeln('    final prefabTheme = PrefabTheme.of(context);');
    buffer.writeln('    return Scaffold(');
    buffer.writeln('      appBar: AppBar(');
    buffer.writeln("        title: const Text('${manifest.title}'),");
    buffer.writeln('      ),');
    buffer.writeln('      body: Form(');
    buffer.writeln('        key: _formKey,');
    buffer.writeln('        onChanged: _formErrors.clearEdited,');
    buffer.writeln('        child: ListView(');
    buffer.writeln('          padding: prefabTheme.formPadding,');
    buffer.writeln('          children: [');
    buffer.writeln('            PrefabFormErrorBanner(errors: _formErrors),');
    for (final field in manifest.createFormFields) {
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
        ? '(${manifest.detailKeyExpr('widget.id', (a) => 'widget.${a.paramName}')})'
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
    buffer.writeln('    final prefabTheme = PrefabTheme.of(context);');
    buffer.writeln('    return Scaffold(');
    buffer.writeln('      appBar: AppBar(');
    buffer.writeln("        title: const Text('${manifest.title}'),");
    buffer.writeln('      ),');
    buffer.writeln('      body: asyncItem.when(');
    buffer.writeln(
      '        loading: () => prefabTheme.loadingBuilder(context),',
    );
    buffer.writeln('        error: (e, st) =>');
    buffer.writeln(
      '            ref.read(prefabBackendProvider).parseError(e).isNotFound',
    );
    final listPath = entity.paths
        .collectionPath(manifest)
        .replaceAllMapped(
            RegExp(r'\$(\w+)'), (m) => '\${widget.${m[1]}}');
    buffer.writeln(
      "                ? prefabTheme.notFoundBuilder(context, () => context.go('$listPath'))",
    );
    buffer.writeln(
      '                : prefabTheme.errorBuilder(context, e, st),',
    );
    buffer.writeln('        data: (_) => Form(');
    buffer.writeln('          key: _formKey,');
    buffer.writeln('          onChanged: _formErrors.clearEdited,');
    buffer.writeln('          child: ListView(');
    buffer.writeln('            padding: prefabTheme.formPadding,');
    buffer.writeln('            children: [');
    buffer.writeln('              PrefabFormErrorBanner(errors: _formErrors),');
    for (final field in manifest.updateFormFields) {
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
    buffer.writeln('            prefabTheme.saveButtonBuilder(');
    buffer.writeln('              context,');
    buffer.writeln("              '$saveButtonLabel',");
    buffer.writeln('              _saving ? null : _save,');
    buffer.writeln('              _saving,');
    buffer.writeln('            ),');
  }

  // ---------------------------------------------------------------------------
  // _save method generation
  // ---------------------------------------------------------------------------

  void _writeSaveMethod(
      EntityManifest manifest, bool isEdit, StringBuffer buffer) {
    final entity = manifest.entityName;
    final providerArgs = manifest.hasParent
        ? '(${manifest.parentKeyExpr((a) => 'widget.${a.paramName}')})'
        : '';
    final provider = '${manifest.entityNameLower}sProvider$providerArgs';
    final mutation = isEdit ? 'updateEntity' : 'create';

    final arguments = _buildConstructorArguments(manifest, isEdit);

    buffer.writeln('  Future<void> _save() async {');
    buffer.writeln('    if (!_formKey.currentState!.validate()) return;');
    buffer.writeln('    _formErrors.clear();');
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
    final known = manifest.formFields
        .map((f) => dartStringLiteral(f.jsonName))
        .join(', ');
    buffer.writeln('      _formErrors.setError(');
    buffer.writeln('        ref.read(prefabBackendProvider).parseError(e),');
    buffer.writeln('        const {$known},');
    buffer.writeln('      );');
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
    final formFields = {for (final f in _fieldsOf(isEdit)) f.name: f};
    final arguments = <String>[];
    for (final param in params) {
      final String? expression;
      if (param.name == manifest.idFieldName) {
        expression = isEdit ? 'widget.id' : null;
      } else if (param.name == manifest.parentParamName) {
        expression = 'widget.${param.name}';
      } else if (formFields.containsKey(param.name)) {
        expression = _emitter(formFields[param.name]!)
            .valueExpression(formFields[param.name]!);
      } else {
        expression = isEdit ? '_item!.${param.name}' : null;
      }

      if (expression == null) {
        // No source. On create, a required value the server sets gets a
        // placeholder the create request never carries; otherwise the
        // parameter must be optional (or nullable) so it can be omitted.
        if (!isEdit && param.isRequired && !param.isNullable) {
          final placeholder = _placeholder(param);
          if (placeholder != null) {
            arguments.add(
                param.isNamed ? '${param.name}: $placeholder' : placeholder);
            continue;
          }
        }
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

  /// A stand-in for a value the server sets, so that the create form can
  /// build the entity. The create request never sends it (PF-53).
  static String? _placeholder(ConstructorParam param) {
    if (param.isEnum) return '${param.typeName}.values.first';
    switch (param.typeName) {
      case 'String':
        return "''";
      case 'int':
      case 'num':
        return '0';
      case 'double':
        return '0.0';
      case 'bool':
        return 'false';
      case 'DateTime':
        return 'DateTime.fromMillisecondsSinceEpoch(0)';
      case 'Duration':
        return 'Duration.zero';
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // _prefillControllers method generation
  // ---------------------------------------------------------------------------

  void _writePrefillControllers(EntityManifest manifest, StringBuffer buffer) {
    final entity = manifest.entityName;
    final fields = manifest.updateFormFields;

    buffer.writeln('  void _prefillControllers($entity item) {');
    buffer.writeln('    _item = item;');
    for (final field in fields) {
      _write(_emitter(field).initialValue(field, 'item'), buffer);
    }
    buffer.writeln('  }');
  }

  // ---------------------------------------------------------------------------
  // Individual form field — dispatches to the correct widget writer
  // ---------------------------------------------------------------------------

  /// A field is wrapped in `PrefabFieldError`, which shows the server error
  /// of the field (by JSON name) below it.
  void _writeFormField(FieldManifest field, StringBuffer buffer) {
    final code = _emitter(field).formField(field);
    buffer.writeln('            PrefabFieldError(');
    buffer.writeln('              errors: _formErrors,');
    buffer.writeln('              field: ${dartStringLiteral(field.jsonName)},');
    buffer.writeln('              children: [');
    _write(code, buffer);
    buffer.writeln('              ],');
    buffer.writeln('            ),');
  }

  /// Writes [code] and remembers the libraries it needs.
  void _write(Code? code, StringBuffer buffer) {
    if (code == null) return;
    buffer.write(code.text);
    _imports.addAll(code.imports);
  }
}
