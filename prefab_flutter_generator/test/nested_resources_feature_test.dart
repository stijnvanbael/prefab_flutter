import 'package:prefab_flutter_generator/src/core/family_key.dart';
import 'package:test/test.dart';

void main() {
  group('PF-62 FamilyKey', () {
    const order = FamilyId(name: 'orderId', type: 'int', path: 'orders');
    const line = FamilyId(name: 'orderLineId', type: 'String', path: 'lines');

    test('an empty key is the plain id', () {
      const key = FamilyKey([]);
      expect(key.isEmpty, isTrue);
      expect(key.detailExpr('id', (i) => i.name), 'id');
    });

    test('one id keys the list provider on the id itself', () {
      const key = FamilyKey([order]);
      expect(key.listType, 'int');
      expect(key.listExpr((i) => i.name), 'orderId');
      expect(key.detailType('int'), '(int, int)');
      expect(key.detailExpr('id', (i) => i.name), '(id, orderId)');
      expect(key.requiredParams, 'required int orderId');
      expect(key.requiredThis, 'required this.orderId');
      expect(key.urlPrefix, r'/orders/$orderId');
    });

    test('several ids use records, outermost first', () {
      const key = FamilyKey([order, line]);
      expect(key.listType, '(int, String)');
      expect(key.listExpr((i) => i.name), '(orderId, orderLineId)');
      expect(key.namedArgs('widget.'),
          'orderId: widget.orderId, orderLineId: widget.orderLineId');
      expect(key.urlPrefix, r'/orders/$orderId/lines/$orderLineId');
    });
  });
}
