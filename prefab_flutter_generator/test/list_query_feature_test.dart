import 'package:prefab_flutter_generator/src/core/extension_point.dart';
import 'package:test/test.dart';

void main() {
  group('PF-39 ValuePoint', () {
    test('orders values by order, then feature, then insertion', () {
      final point = ValuePoint<String>('x.y')
        ..add('b', 'b30', order: 30)
        ..add('z', 'z10', order: 10)
        ..add('a', 'a10', order: 10)
        ..add('a', 'a10-second', order: 10);
      expect(point.values, ['a10', 'a10-second', 'z10', 'b30']);
    });

    test('NamedArgument and QueryParameter render', () {
      expect(const NamedArgument('page', '_page').toString(), 'page: _page');
      expect(
          const QueryParameter('page', 'int', defaultValue: '0').declaration,
          'int page = 0');
      expect(const QueryParameter('sort', 'String?').declaration,
          'String? sort');
    });
  });
}
