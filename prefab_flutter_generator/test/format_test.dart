import 'package:prefab_flutter_generator/src/core/format.dart';
import 'package:test/test.dart';

void main() {
  test('formats badly indented code', () {
    final out = formatGenerated(
        'class A{\nfinal int x;\n      const A(this.x);}', 'a.dart');
    expect(out, 'class A {\n  final int x;\n  const A(this.x);\n}\n');
  });

  test('leaves an empty library empty', () {
    expect(formatGenerated('', 'a.dart'), '');
  });

  test('names the source file and shows the unformatted output on failure', () {
    expect(
      () => formatGenerated('class A {', 'product.dart'),
      throwsA(isA<FormatException>().having((e) => e.message, 'message',
          allOf(contains('product.dart'), contains('class A {')))),
    );
  });
}
