import 'dart:convert';

import 'package:build/build.dart';
import 'package:glob/glob.dart';

import '../features/features.dart';

/// One kind of hand-written declaration (`@Promoted`, `@EntityAction`, ...)
/// that is read from the unresolved syntax tree of every library, so the scan
/// does not depend on generated code. A feature module registers its scanners
/// in `Feature.declarationScanners`; the `prefab_declarations` builder runs
/// all of them over each file once and writes one summary per file.
abstract class DeclarationScanner<T> {
  const DeclarationScanner();

  /// Key of this kind in the summary file; unique and stable.
  String get key;

  /// A cheap check on the source text: the scanner runs only for files that
  /// contain it (usually the name of the annotation).
  String get marker;

  /// The declarations of [source] (the library at [uri]). May throw for a
  /// declaration that is not usable; the build fails with the message.
  List<T> scan(String source, String uri);

  Map<String, Object?> toJson(T declaration);

  T fromJson(Map<String, dynamic> json);
}

const declarationsExtension = '.prefab_declarations.json';

/// The scanners of every registered feature.
List<DeclarationScanner<Object>> get registeredScanners => [
      for (final f in registeredFeatures) ...f.declarationScanners,
    ];

/// Writes `<file>.prefab_declarations.json`, a JSON object with the
/// declarations of each scanner under its key, for every file that has at
/// least one declaration. Files without any get no output, so editing them
/// changes no summary.
class DeclarationsBuilder implements Builder {
  DeclarationsBuilder([List<DeclarationScanner<Object>>? scanners])
      : scanners = scanners ?? registeredScanners;

  final List<DeclarationScanner<Object>> scanners;

  @override
  Map<String, List<String>> get buildExtensions => const {
        '.dart': [declarationsExtension],
      };

  @override
  Future<void> build(BuildStep buildStep) async {
    final id = buildStep.inputId;
    if (id.path.endsWith('.prefab.dart') || id.path.endsWith('.g.dart')) {
      return;
    }
    final source = await buildStep.readAsString(id);
    final uri = id.uri.toString();
    final summary = <String, Object?>{};
    for (final scanner in scanners) {
      if (!source.contains(scanner.marker)) continue;
      final found = scanner.scan(source, uri);
      if (found.isEmpty) continue;
      summary[scanner.key] = [for (final d in found) _toJson(scanner, d)];
    }
    if (summary.isEmpty) return;
    await buildStep.writeAsString(
        id.changeExtension(declarationsExtension), jsonEncode(summary));
  }

  static Map<String, Object?> _toJson<T>(
          DeclarationScanner<T> scanner, Object declaration) =>
      scanner.toJson(declaration as T);
}

/// The declarations of every file of the package, read from the summaries.
class Declarations {
  const Declarations._(this._byKey);

  /// No declarations.
  const Declarations.empty() : _byKey = const {};

  final Map<String, List<Map<String, dynamic>>> _byKey;

  /// The declarations [scanner] found in the package, ordered by file path,
  /// then declaration order.
  List<T> of<T>(DeclarationScanner<T> scanner) => [
        for (final json
            in _byKey[scanner.key] ?? const <Map<String, dynamic>>[])
          scanner.fromJson(json),
      ];

  static Future<Declarations> read(BuildStep buildStep) async {
    final byKey = <String, List<Map<String, dynamic>>>{};
    final ids = await buildStep
        .findAssets(Glob('lib/**$declarationsExtension'))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));
    for (final id in ids) {
      final json =
          jsonDecode(await buildStep.readAsString(id)) as Map<String, dynamic>;
      json.forEach((key, entries) {
        (byKey[key] ??= []).addAll(
            [for (final e in entries as List) e as Map<String, dynamic>]);
      });
    }
    return Declarations._(byKey);
  }
}
