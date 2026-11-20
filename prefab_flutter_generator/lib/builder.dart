import 'package:build/build.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:source_gen/source_gen.dart';

import 'src/generators/api_client_generator.dart';
import 'src/generators/detail_screen_generator.dart';
import 'src/generators/form_screen_generator.dart';
import 'src/generators/list_screen_generator.dart';
import 'src/generators/prefab_generator.dart';
import 'src/generators/provider_generator.dart';
import 'src/generators/routes_generator.dart';
import 'src/features/actions/action_scanner.dart';
import 'src/features/entity_screens/child_screen.dart';
import 'src/promoted/promoted_scanner.dart';

/// The generators format their own output (`ArtifactGenerator`, with a pinned
/// `dart_style`), so the builder must not format it a second time.
String _alreadyFormatted(String code, Version languageVersion) => code;

/// Generates a read-only `{Entity}DetailScreen` [ConsumerWidget].
Builder detailScreenBuilder(BuilderOptions options) => LibraryBuilder(
      DetailScreenGenerator(),
      generatedExtension: '.detail_screen.dart',
      formatOutput: _alreadyFormatted,
    );

/// Generates a `{Entity}ListScreen` [ConsumerWidget] with search, sort and
/// pagination.
Builder listScreenBuilder(BuilderOptions options) => LibraryBuilder(
      ListScreenGenerator(),
      generatedExtension: '.list_screen.dart',
      formatOutput: _alreadyFormatted,
    );

/// Generates `{Entity}CreateScreen` and `{Entity}EditScreen` [ConsumerWidget]s.
Builder formScreenBuilder(BuilderOptions options) => LibraryBuilder(
      FormScreenGenerator(),
      generatedExtension: '.form_screen.dart',
      formatOutput: _alreadyFormatted,
    );

/// Generates Riverpod providers (detail + list notifier) for an entity.
Builder providerBuilder(BuilderOptions options) => LibraryBuilder(
      ProviderGenerator(),
      generatedExtension: '.provider.dart',
      formatOutput: _alreadyFormatted,
    );

/// Generates a Dio-backed API client for an entity.
Builder apiClientBuilder(BuilderOptions options) => LibraryBuilder(
      ApiClientGenerator(),
      generatedExtension: '.api_client.dart',
      formatOutput: _alreadyFormatted,
    );

/// Generates GoRouter `TypedGoRoute` declarations and the per-file `$<file>Routes` list.
Builder routesBuilder(BuilderOptions options) => LibraryBuilder(
      RoutesGenerator(),
      generatedExtension: '.routes.dart',
      formatOutput: _alreadyFormatted,
    );

/// Generates all code for an annotated source file into one `.prefab.dart`
/// library: detail, list and form screens, providers, API client and routes.
///
/// This is the only builder registered in `build.yaml`; the builders above
/// are kept for testing the individual generators.
Builder prefabBuilder(BuilderOptions options) => LibraryBuilder(
      PrefabGenerator(),
      generatedExtension: '.prefab.dart',
      formatOutput: _alreadyFormatted,
    );

/// Summarises the `@Promoted` declarations of a file for [prefabBuilder].
Builder prefabPromotedBuilder(BuilderOptions options) => PromotedBuilder();

/// Summarises the `@EntityAction` functions of a file for [prefabBuilder].
Builder prefabActionsBuilder(BuilderOptions options) => ActionsBuilder();

/// Summarises the `@EntityScreen` declarations of a file for [prefabBuilder].
Builder prefabScreensBuilder(BuilderOptions options) => ChildScreensBuilder();
