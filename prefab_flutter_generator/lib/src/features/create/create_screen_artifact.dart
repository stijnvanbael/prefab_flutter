import '../../core/artifact.dart';
import '../../core/code.dart';
import '../../core/entity_context.dart';
import '../../generators/form_screen_generator.dart';
import '../../manifest/entity_manifest.dart';

/// The `{Entity}CreateScreen` widget of one entity with `@Create`.
class CreateScreenArtifact extends FormScreenArtifact {
  CreateScreenArtifact(super.entity);

  /// The artifact factory of the create feature: one screen with `@Create`.
  static Iterable<Artifact> create(EntityContext entity) =>
      entity.manifest.hasCreate ? [CreateScreenArtifact(entity)] : const [];

  @override
  ArtifactId get id =>
      ArtifactId(ArtifactKind.createScreen, manifest.entityName);

  @override
  String get primaryName => '${manifest.entityName}CreateScreen';

  @override
  List<String> get declaredNames =>
      [primaryName, '_${manifest.entityName}CreateScreenState'];

  @override
  Code emit() {
    final buffer = StringBuffer();
    _writeCreateScreen(manifest, buffer);
    return code(buffer);
  }

  void _writeCreateScreen(EntityManifest manifest, StringBuffer buffer) {
    final entity = manifest.entityName;

    buffer.writeln(
      'class ${entity}CreateScreen extends ConsumerStatefulWidget {',
    );
    if (manifest.hasParent) {
      for (final a in manifest.ancestors) {
        buffer.writeln('  final ${a.idType} ${a.paramName};');
      }
      buffer.writeln();
      buffer.writeln(
        '  const ${entity}CreateScreen({super.key, ${FormScreenArtifact.requiredThis(manifest)}});',
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

    writeScreenState(
      manifest: manifest,
      stateClassName: '_${entity}CreateScreenState',
      widgetClassName: '${entity}CreateScreen',
      saveButtonLabel: 'Create',
      isEdit: false,
      buffer: buffer,
    );
  }
}
