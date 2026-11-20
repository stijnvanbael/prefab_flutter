import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:prefab_flutter_generator/builder.dart';
import 'package:prefab_flutter_generator/src/core/declarations.dart';
import 'package:test/test.dart';

const _source = '''
@Promoted()
class AlphaDetailScreen {}

@EntityAction(Alpha, label: 'Go')
void go(BuildContext c, WidgetRef r, Alpha a) {}

@EntityScreen(Alpha, path: 'live')
class AlphaLive {
  const AlphaLive({required this.id});
  final int id;
}
''';

void main() {
  test('PF-71 one summary file holds every declaration type of a file',
      () async {
    await testBuilder(
      prefabDeclarationsBuilder(BuilderOptions.empty),
      {'a|lib/x.dart': _source},
      outputs: {
        'a|lib/x.prefab_declarations.json': decodedMatches(allOf(
          contains('"promoted":[{"name":"AlphaDetailScreen"'),
          contains('"actions":[{"name":"go"'),
          contains('"screens":[{"entity":"Alpha"'),
        )),
      },
    );
  });

  test('PF-71 a file without declarations gets no summary', () async {
    await testBuilder(
      prefabDeclarationsBuilder(BuilderOptions.empty),
      {'a|lib/x.dart': 'class X {}'},
      outputs: {},
    );
  });

  test('PF-71 the scanners are registered by the feature modules', () {
    expect(registeredScanners.map((s) => s.key),
        containsAll(['actions', 'promoted', 'screens']));
    final keys = registeredScanners.map((s) => s.key).toList();
    expect(keys.toSet(), hasLength(keys.length));
  });
}
