import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:prefab_flutter_generator/builder.dart';
import 'package:prefab_flutter_generator/src/promoted/promote.dart';
import 'package:test/test.dart';

import 'support/prefab_sources.dart';

const _entity = '''
import 'package:prefab_flutter/prefab_flutter.dart';

@View(title: 'Alpha', path: 'alphas')
class Alpha {
  final int? id;
  @Field()
  final String name;
  Alpha({this.id, required this.name});
  factory Alpha.fromJson(Map<String, dynamic> json) => throw 0;
  Map<String, dynamic> toJson() => {};
}
''';

Future<List<PromoteSource>> _sources() async {
  final library = await resolveSources(
    {...prefabSources, 'a|lib/models/alpha.dart': _entity},
    (r) => r.libraryFor(AssetId('a', 'lib/models/alpha.dart')),
  );
  return [PromoteSource(library, 'lib/models/alpha.dart')];
}

void main() {
  test('writes the artifact next to the entity with imports and @Promoted',
      () async {
    final file = promoteArtifact('AlphaDetailScreen', await _sources());
    expect(file.path, 'lib/models/alpha_detail_screen.dart');
    final c = file.content;
    expect(c, contains("import 'alpha.dart';"));
    expect(c, contains("import 'alpha.prefab.dart';"));
    expect(c, contains("import 'package:prefab_flutter/prefab_flutter.dart';"));
    expect(c, contains('@Promoted()\nclass AlphaDetailScreen'));
    expect(c, isNot(contains('GENERATED CODE')));
    expect(c, isNot(contains('class AlphaListScreen')));
  });

  test('--to rewrites relative imports for the new folder', () async {
    final file = promoteArtifact('alphasProvider', await _sources(),
        to: 'lib/screens/my_provider.dart');
    expect(file.path, 'lib/screens/my_provider.dart');
    expect(file.content, contains("import '../models/alpha.dart';"));
    expect(file.content, contains("import '../models/alpha.prefab.dart';"));
    expect(file.content, contains('@Promoted()\nfinal alphasProvider'));
    expect(file.content, contains('class AlphasNotifier'));
  });

  test('an unknown name suggests the closest artifact', () async {
    final sources = await _sources();
    expect(
      () => promoteArtifact('AlphaDetailScren', sources),
      throwsA(isA<PromoteException>().having(
          (e) => e.message, 'message', contains('did you mean AlphaDetailScreen?'))),
    );
  });

  test('the app builds with the promoted file and behaves the same', () async {
    final sources = await _sources();
    final promoted = promoteArtifact('AlphaDetailScreen', sources);
    final reference = await _build({});
    final out = await _build({
      'a|${promoted.path}': promoted.content,
      'a|lib/models/alpha_detail_screen.prefab_promoted.json':
          '[{"name":"AlphaDetailScreen","uri":"package:a/models/alpha_detail_screen.dart"}]',
    });
    expect(out, isNot(contains('class AlphaDetailScreen')));
    expect(out, contains("export 'package:a/models/alpha_detail_screen.dart' "
        'show AlphaDetailScreen;'));
    // The promoted file holds exactly the code the generator emitted before.
    final body = reference.substring(reference.indexOf('class AlphaDetailScreen'));
    final end = body.indexOf('\nclass ', 1);
    final screen = end < 0 ? body : body.substring(0, end);
    expect(promoted.content, contains(screen.trim()));
  });
}


Future<String> _build(Map<String, String> extra) async {
  String? out;
  await testBuilder(
    prefabBuilder(BuilderOptions.empty),
    {...prefabSources, 'a|lib/models/alpha.dart': _entity, ...extra},
    generateFor: {'a|lib/models/alpha.dart'},
    outputs: {
      'a|lib/models/alpha.prefab.dart':
          decodedMatches(predicate<String>((s) {
        out = s;
        return true;
      }, 'captured')),
    },
  );
  return out!;
}
