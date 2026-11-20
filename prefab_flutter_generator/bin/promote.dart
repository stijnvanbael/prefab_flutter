import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:path/path.dart' as p;
import 'package:prefab_flutter_generator/src/promoted/promote.dart';

const _usage = '''
Writes the generated code of one artifact to a file you own and marks it
@Promoted(), so build_runner stops generating it.

Usage: dart run prefab_flutter_generator:promote <Name> [--to lib/path/file.dart]

Run it in the root of your package. <Name> is the artifact's primary name,
e.g. ProductDetailScreen, productsProvider, ProductApiClient or \$productRoutes.
Then run: dart run build_runner build''';

Future<void> main(List<String> args) async {
  String? name;
  String? to;
  for (var i = 0; i < args.length; i++) {
    final a = args[i];
    if (a == '--help' || a == '-h') {
      stdout.writeln(_usage);
      return;
    } else if (a == '--to' && i + 1 < args.length) {
      to = args[++i];
    } else if (a.startsWith('--to=')) {
      to = a.substring(5);
    } else if (!a.startsWith('-') && name == null) {
      name = a;
    } else {
      stderr.writeln('Unknown argument: $a\n\n$_usage');
      exitCode = 64;
      return;
    }
  }
  if (name == null) {
    stderr.writeln(_usage);
    exitCode = 64;
    return;
  }
  try {
    final root = Directory.current.path;
    final sources = await _readSources(root);
    final packageName = _packageName(root);
    final found = scanPackageContributions(packageName, _readLib(root));
    final file = promoteArtifact(
      name,
      sources,
      to: to,
      actions: found.actions,
      childScreens: found.childScreens,
      packageName: packageName,
    );
    final out = File(p.join(root, file.path));
    if (out.existsSync()) {
      throw PromoteException(
        '${file.path} already exists; not overwriting it. '
        'Choose another file with --to.',
      );
    }
    out.parent.createSync(recursive: true);
    out.writeAsStringSync(file.content);
    stdout.writeln(
      'Wrote ${file.path}. Run `dart run build_runner build` '
      'to stop generating $name.',
    );
  } on PromoteException catch (e) {
    stderr.writeln(e.message);
    exitCode = 1;
  }
}

/// Resolves the libraries under `lib/` that declare `@Entity` classes.
Future<List<PromoteSource>> _readSources(String root) async {
  final collection = AnalysisContextCollection(
    includedPaths: [p.join(root, 'lib')],
  );
  final files =
      Directory(p.join(root, 'lib'))
          .listSync(recursive: true)
          .whereType<File>()
          .where(
            (f) =>
                f.path.endsWith('.dart') &&
                !f.path.endsWith('.prefab.dart') &&
                !f.path.endsWith('.g.dart') &&
                f.readAsStringSync().contains('@Entity'),
          )
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));
  final sources = <PromoteSource>[];
  for (final f in files) {
    final session = collection.contextFor(f.path).currentSession;
    final result = await session.getResolvedLibrary(f.path);
    if (result is ResolvedLibraryResult) {
      sources.add(
        PromoteSource(
          result.element,
          p.posix.joinAll(p.split(p.relative(f.path, from: root))),
        ),
      );
    }
  }
  return sources;
}

/// The `name:` of the package's `pubspec.yaml`.
String _packageName(String root) {
  final pubspec = File(p.join(root, 'pubspec.yaml'));
  final match = pubspec.existsSync()
      ? RegExp(
          r'^name:\s*(\S+)',
          multiLine: true,
        ).firstMatch(pubspec.readAsStringSync())
      : null;
  if (match == null) {
    throw const PromoteException(
      'pubspec.yaml with a name not found; run the '
      'command in the root of your package.',
    );
  }
  return match.group(1)!;
}

/// The Dart files under `lib/` by path relative to the package root.
Map<String, String> _readLib(String root) => {
  for (final f
      in Directory(p.join(root, 'lib'))
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart')))
    p.posix.joinAll(p.split(p.relative(f.path, from: root))): f
        .readAsStringSync(),
};
