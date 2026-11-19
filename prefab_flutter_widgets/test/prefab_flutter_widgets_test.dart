import 'package:material_ui/material_ui.dart';
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

  group('PrefabListAdapter', () {
    const adapter = PrefabListAdapter();
    Map<String, dynamic> fromJson(Map<String, dynamic> j) => j;

    test('uses q, sort, page and size by default', () {
      expect(
        adapter.queryParameters(
          search: 'tea',
          sort: 'name',
          descending: true,
          page: 2,
          pageSize: 10,
        ),
        {'q': 'tea', 'sort': '-name', 'page': 2, 'size': 10},
      );
    });

    test('leaves out empty search, absent sort and unpaged page', () {
      expect(adapter.queryParameters(search: ''), isEmpty);
      expect(adapter.queryParameters(sort: 'name'), {'sort': 'name'});
      expect(adapter.queryParameters(page: 0), {'page': 0, 'size': 20});
    });

    test('parameter names are configurable', () {
      const custom = PrefabListAdapter(searchParam: 'query', sizeParam: 'limit');
      expect(
        custom.queryParameters(search: 'x', page: 1, pageSize: 5),
        {'query': 'x', 'page': 1, 'limit': 5},
      );
    });

    test('parses { items, total }', () {
      final page = adapter.parsePage(
        {
          'items': [
            {'id': 1},
            {'id': 2},
          ],
          'total': 25,
        },
        fromJson,
        page: 1,
        pageSize: 2,
      );
      expect(page.items.length, 2);
      expect(page.totalItems, 25);
      expect(page.page, 1);
      expect(page.totalPages, 13);
    });

    test('parses a bare array as a single page', () {
      final page = adapter.parsePage([
        {'id': 1},
        {'id': 2},
      ], fromJson);
      expect(page.totalItems, 2);
      expect(page.totalPages, 1);
    });

    test('rejects an unexpected response', () {
      expect(() => adapter.parsePage('oops', fromJson), throwsFormatException);
    });
  });

  group('PrefabPaginationBar.controlled', () {
    testWidgets('reports navigation through onPageChanged', (tester) async {
      int? target;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrefabPaginationBar.controlled(
              page: 1,
              totalPages: 3,
              onPageChanged: (p) => target = p,
            ),
          ),
        ),
      );
      expect(find.text('2 / 3'), findsOneWidget);
      await tester.tap(find.byTooltip('Next page'));
      expect(target, 2);
      await tester.tap(find.byTooltip('Previous page'));
      expect(target, 0);
    });
  });
}
