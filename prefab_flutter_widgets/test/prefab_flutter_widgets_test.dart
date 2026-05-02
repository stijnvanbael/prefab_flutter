import 'package:flutter_test/flutter_test.dart';
import 'package:prefab_flutter_widgets/prefab_flutter_widgets.dart';

void main() {
  group('PrefabPage', () {
    test('totalPages rounds up', () {
      const page = PrefabPage<int>(
        items: [1, 2, 3],
        totalItems: 25,
        page: 0,
        pageSize: 10,
      );
      expect(page.totalPages, 3);
    });

    test('totalPages is 0 when pageSize is 0', () {
      const page = PrefabPage<int>(
        items: [],
        totalItems: 0,
        page: 0,
        pageSize: 0,
      );
      expect(page.totalPages, 0);
    });

    test('hasPreviousPage is false on first page', () {
      const page = PrefabPage<int>(
        items: [],
        totalItems: 10,
        page: 0,
        pageSize: 5,
      );
      expect(page.hasPreviousPage, isFalse);
    });

    test('hasNextPage is false on last page', () {
      const page = PrefabPage<int>(
        items: [],
        totalItems: 10,
        page: 1,
        pageSize: 5,
      );
      expect(page.hasNextPage, isFalse);
    });
  });

  group('PrefabPageNotifier', () {
    test('goToPage updates page and notifies', () {
      final notifier = PrefabPageNotifier();
      var notified = false;
      notifier.addListener(() => notified = true);
      notifier.goToPage(2);
      expect(notifier.page, 2);
      expect(notified, isTrue);
    });

    test('goToPage to same page does not notify', () {
      final notifier = PrefabPageNotifier();
      var notified = false;
      notifier.addListener(() => notified = true);
      notifier.goToPage(0);
      expect(notified, isFalse);
    });

    test('previousPage does nothing on first page', () {
      final notifier = PrefabPageNotifier();
      var notified = false;
      notifier.addListener(() => notified = true);
      notifier.previousPage();
      expect(notifier.page, 0);
      expect(notified, isFalse);
    });

    test('nextPage increments page', () {
      final notifier = PrefabPageNotifier();
      notifier.nextPage();
      expect(notifier.page, 1);
    });

    test('setPageSize resets page to 0', () {
      final notifier = PrefabPageNotifier(page: 3);
      notifier.setPageSize(50);
      expect(notifier.page, 0);
      expect(notifier.pageSize, 50);
    });
  });

  group('PrefabSortOption', () {
    test('holds id and label', () {
      const option = PrefabSortOption<String>(id: 'name_asc', label: 'Name A-Z');
      expect(option.id, 'name_asc');
      expect(option.label, 'Name A-Z');
    });
  });
}
