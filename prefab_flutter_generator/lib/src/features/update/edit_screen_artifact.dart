import '../../core/artifact.dart';
import '../../core/code.dart';
import '../../core/entity_context.dart';
import '../../generators/form_screen_generator.dart';
import '../../manifest/entity_manifest.dart';

/// The `{Entity}EditScreen` widget of one entity with `@Update`.
class EditScreenArtifact extends FormScreenArtifact {
  EditScreenArtifact(super.entity);

  /// The artifact factory of the update feature: one screen with `@Update`.
  static Iterable<Artifact> create(EntityContext entity) =>
      entity.manifest.hasUpdate ? [EditScreenArtifact(entity)] : const [];

  @override
  ArtifactId get id => ArtifactId(ArtifactKind.editScreen, manifest.entityName);

  @override
  String get primaryName => '${manifest.entityName}EditScreen';

  @override
  List<String> get declaredNames =>
      [primaryName, '_${manifest.entityName}EditScreenState'];

  @override
  Code emit() {
    final buffer = StringBuffer();
    _writeEditScreen(manifest, buffer);
    return code(buffer);
  }

  void _writeEditScreen(EntityManifest manifest, StringBuffer buffer) {
    final entity = manifest.entityName;

    buffer.writeln(
      'class ${entity}EditScreen extends ConsumerStatefulWidget {',
    );
    buffer.writeln('  final ${manifest.idType} id;');
    buffer.writeln();
    if (manifest.hasParent) {
      for (final a in manifest.ancestors) {
        buffer.writeln('  final ${a.idType} ${a.paramName};');
      }
      buffer.writeln();
      buffer.writeln(
        '  const ${entity}EditScreen({super.key, required this.id, ${FormScreenArtifact.requiredThis(manifest)}});',
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

    writeScreenState(
      manifest: manifest,
      stateClassName: '_${entity}EditScreenState',
      widgetClassName: '${entity}EditScreen',
      saveButtonLabel: 'Save',
      isEdit: true,
      buffer: buffer,
    );
  }
}
