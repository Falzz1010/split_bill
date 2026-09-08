import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fairsplit/core/models/transaksi_umkm.dart';
import 'package:fairsplit/core/state/transaksi_umkm_store.dart';

TransaksiUmkm _tx(String id, {DateTime? date, double total = 100, String category = ''}) =>
    TransaksiUmkm(
      id: id,
      merchantName: 'Demo',
      date: date ?? DateTime(2026, 8, 15),
      items: [
        TransaksiItem(id: 'i$id', name: 'Kopi', price: total, quantity: 1),
      ],
      subtotal: total,
      ppn: 0,
      serviceCharge: 0,
      totalAmount: total,
      paymentMethod: PaymentMethod.cash,
      amountPaid: total,
      category: category,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await TransaksiUmkmStore.instance.clearAll();
  });

  group('CRUD', () {
    test('add', () async {
      final store = TransaksiUmkmStore.instance;
      await store.add(_tx('a'));
      expect(store.transaksi.length, 1);
      expect(store.transaksi.first.id, 'a');
    });

    test('add inserts at beginning', () async {
      final store = TransaksiUmkmStore.instance;
      await store.add(_tx('old', date: DateTime(2026, 8, 1)));
      await store.add(_tx('new', date: DateTime(2026, 8, 2)));
      expect(store.transaksi.first.id, 'new');
    });

    test('update', () async {
      final store = TransaksiUmkmStore.instance;
      await store.add(_tx('a', total: 100));
      await store.update(_tx('a', total: 200));
      expect(store.transaksi.first.totalAmount, 200);
    });

    test('update non-existent does nothing', () async {
      final store = TransaksiUmkmStore.instance;
      await store.update(_tx('ghost'));
      expect(store.transaksi, isEmpty);
    });

    test('delete', () async {
      final store = TransaksiUmkmStore.instance;
      await store.add(_tx('a'));
      await store.delete('a');
      expect(store.transaksi, isEmpty);
    });

    test('clearAll', () async {
      final store = TransaksiUmkmStore.instance;
      await store.add(_tx('a'));
      await store.add(_tx('b'));
      await store.clearAll();
      expect(store.transaksi, isEmpty);
    });
  });

  group('filtering', () {
    test('transactionsInRange', () async {
      final store = TransaksiUmkmStore.instance;
      await store.add(_tx('a', date: DateTime(2026, 8, 10)));
      await store.add(_tx('b', date: DateTime(2026, 8, 15)));
      await store.add(_tx('c', date: DateTime(2026, 8, 20)));
      final result = store.transactionsInRange(
        DateTime(2026, 8, 12),
        DateTime(2026, 8, 18),
      );
      expect(result.length, 1);
      expect(result.first.id, 'b');
    });

    test('existingCategories', () async {
      final store = TransaksiUmkmStore.instance;
      await store.add(_tx('a', category: 'Makanan'));
      await store.add(_tx('b', category: 'Minuman'));
      await store.add(_tx('c', category: 'Makanan'));
      expect(store.existingCategories, ['Makanan', 'Minuman']);
    });
  });

  group('analytics', () {
    test('todayRevenue', () async {
      final store = TransaksiUmkmStore.instance;
      await store.add(_tx('a', date: DateTime.now(), total: 150));
      await store.add(_tx('b', date: DateTime(2020, 1, 1), total: 999));
      expect(store.todayRevenue, 150);
    });

    test('todayCount', () async {
      final store = TransaksiUmkmStore.instance;
      await store.add(_tx('a', date: DateTime.now()));
      await store.add(_tx('b', date: DateTime.now()));
      await store.add(_tx('c', date: DateTime(2020, 1, 1)));
      expect(store.todayCount, 2);
    });

    test('topItems', () async {
      final store = TransaksiUmkmStore.instance;
      await store.add(_tx('a', total: 10));
      final tops = store.topItems(limit: 5);
      expect(tops.length, 1);
      expect(tops.first.name, 'Kopi');
    });

    test('categoryBreakdown', () async {
      final store = TransaksiUmkmStore.instance;
      await store.add(_tx('a', total: 100, category: 'Makanan'));
      await store.add(_tx('b', total: 200, category: 'Minuman'));
      final cats = store.categoryBreakdown();
      expect(cats.length, 2);
      expect(cats.first.category, 'Minuman');
    });
  });

  group('persistence', () {
    test('survives load()', () async {
      final store = TransaksiUmkmStore.instance;
      await store.add(_tx('persist'));
      await store.load();
      expect(store.transaksi.length, 1);
      expect(store.transaksi.first.id, 'persist');
    });
  });
}
