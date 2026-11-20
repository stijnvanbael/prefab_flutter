import '../../core/artifact.dart';
import '../../core/code.dart';
import '../../core/entity_context.dart';
import '../../core/family_key.dart';
import '../../manifest/entity_manifest.dart';
import '../../manifest/field_manifest.dart';
import '../field_widgets/field_widgets_feature.dart';
import '../validators/validator_emitters.dart' show dartStringLiteral;
import 'operation_manifest.dart';

/// The `{Entity}{Operation}Screen` form of one named operation with
/// parameters (`@Update(path: ..., parameters: ...)`).
///
/// It is a route below the detail route (`/products/1/start`) and takes `id`
/// and the ids of the owning resources like the edit screen. Saving calls the
/// notifier method of the operation and goes back.
class OperationScreenArtifact extends Artifact {
  OperationScreenArtifact(this.entity, this.operation);

  final EntityContext entity;
  final OperationManifest operation;

  EntityManifest get manifest => entity.manifest;

  String get className =>
      '${manifest.entityName}${operation.pascalName}Screen';

  /// The ids of the owning resources, outermost first.
  FamilyKey get key => FamilyKey([
        for (final a in manifest.ancestors)
          FamilyId(name: a.paramName, type: a.idType, path: a.path),
      ]);

  @override
  ArtifactId get id =>
      ArtifactId(ArtifactKind.operationScreen,
          '${manifest.entityName}.${operation.path}');

  @override
  String get primaryName => className;

  @override
  List<String> get declaredNames => [primaryName, '_${className}State'];

  FormFieldEmitter _emitter(FieldManifest field) => formFieldEmitters.resolve(field);

  @override
  Code emit() {
    final parameters = operation.parameters!;
    final imports = <String>{
      Libs.materialUi,
      Libs.riverpod,
      Libs.goRouter,
      Libs.widgets,
      entity.sourceFileName,
      if (parameters.libraryUri != null) parameters.libraryUri!,
    };
    final out = StringBuffer();
    void write(Code? code) {
      if (code == null) return;
      out.write(code.text);
      out.writeln();
      imports.addAll(code.imports);
    }

    final key = this.key;
    final lower = manifest.entityNameLower;
    final listProviderArg =
        key.isEmpty ? '' : '(${key.listExpr((a) => 'widget.${a.name}')})';
    final provider = '${lower}sProvider$listProviderArg';
    final fields = parameters.fields;

    out.writeln('class $className extends ConsumerStatefulWidget {');
    out.writeln('  final ${manifest.idType} id;');
    for (final a in key.ids) {
      out.writeln('  final ${a.type} ${a.name};');
    }
    out.writeln();
    out.writeln(key.isEmpty
        ? '  const $className({super.key, required this.id});'
        : '  const $className({super.key, required this.id, ${key.requiredThis}});');
    out.writeln();
    out.writeln('  @override');
    out.writeln(
        '  ConsumerState<$className> createState() => _${className}State();');
    out.writeln('}');
    out.writeln();
    out.writeln(
        'class _${className}State extends ConsumerState<$className> {');
    out.writeln('  final _formKey = GlobalKey<FormState>();');
    out.writeln('  bool _saving = false;');
    out.writeln('  final _formErrors = PrefabFormErrors();');
    for (final f in fields) {
      write(_emitter(f).stateDeclaration(f));
    }
    out.writeln();
    out.writeln('  @override');
    out.writeln('  void dispose() {');
    out.writeln('    _formErrors.dispose();');
    for (final f in fields) {
      if (_emitter(f).usesController) {
        out.writeln('    _${f.name}Controller.dispose();');
      }
    }
    out.writeln('    super.dispose();');
    out.writeln('  }');
    out.writeln();
    out.writeln('  Future<void> _save() async {');
    out.writeln('    if (!_formKey.currentState!.validate()) return;');
    out.writeln('    _formErrors.clear();');
    out.writeln('    setState(() => _saving = true);');
    out.writeln('    final subscription = ref.listenManual($provider, (_, __) {});');
    out.writeln('    try {');
    out.writeln('      final parameters = ${parameters.className}(');
    for (final a in parameters.arguments((f) => _emitter(f).valueExpression(f))) {
      out.writeln('        $a,');
    }
    out.writeln('      );');
    out.writeln('      await ref.read($provider.notifier)'
        '.${operation.methodName}(widget.id, parameters);');
    out.writeln('      if (!mounted) return;');
    out.writeln('      context.pop();');
    out.writeln('    } catch (e) {');
    out.writeln('      if (!mounted) return;');
    out.writeln('      setState(() => _saving = false);');
    final known = fields.map((f) => dartStringLiteral(f.jsonName)).join(', ');
    out.writeln('      _formErrors.setError(');
    out.writeln('        ref.read(prefabBackendProvider).parseError(e),');
    out.writeln('        const {$known},');
    out.writeln('      );');
    out.writeln('    } finally {');
    out.writeln('      subscription.close();');
    out.writeln('    }');
    out.writeln('  }');
    out.writeln();
    out.writeln('  @override');
    out.writeln('  Widget build(BuildContext context) {');
    out.writeln('    final prefabTheme = PrefabTheme.of(context);');
    out.writeln('    return Scaffold(');
    out.writeln('      appBar: AppBar(');
    out.writeln('        title: const Text(${dartStringLiteral(operation.label)}),');
    out.writeln('      ),');
    out.writeln('      body: Form(');
    out.writeln('        key: _formKey,');
    out.writeln('        onChanged: _formErrors.clearEdited,');
    out.writeln('        child: ListView(');
    out.writeln('          padding: prefabTheme.formPadding,');
    out.writeln('          children: [');
    out.writeln('            PrefabFormErrorBanner(errors: _formErrors),');
    for (final f in fields) {
      out.writeln('            PrefabFieldError(');
      out.writeln('              errors: _formErrors,');
      out.writeln('              field: ${dartStringLiteral(f.jsonName)},');
      out.writeln('              children: [');
      write(_emitter(f).formField(f));
      out.writeln('              ],');
      out.writeln('            ),');
    }
    out.writeln('            prefabTheme.saveButtonBuilder(');
    out.writeln('              context,');
    out.writeln('              ${dartStringLiteral(operation.label)},');
    out.writeln('              _saving ? null : _save,');
    out.writeln('              _saving,');
    out.writeln('            ),');
    out.writeln('          ],');
    out.writeln('        ),');
    out.writeln('      ),');
    out.writeln('    );');
    out.writeln('  }');
    out.writeln('}');
    return Code(out.toString().trim(), imports: imports);
  }
}
