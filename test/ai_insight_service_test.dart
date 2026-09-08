import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fairsplit/core/models/transaksi_umkm.dart';
import 'package:fairsplit/core/services/ai_insight_service.dart';
import 'package:fairsplit/core/services/inventory_service.dart';

TransaksiUmkm _tx(DateTime date, double total, {double costPrice = 0}) => TransaksiUmkm(
      id: 't${date.millisecond}',
      merchantName: 'Demo',
      date: date,
      items: [
        TransaksiItem(
          id: 'i1',
          name: 'Kopi',
          price: total,
          costPrice: costPrice,
          quantity: 1,
        ),
      ],
      subtotal: total,
      ppn: 0,
      serviceCharge: 0,
      totalAmount: total,
      paymentMethod: PaymentMethod.cash,
      amountPaid: total,
    );

List<TransaksiUmkm> _series(int count, double Function(int) amountFn) {
  final now = DateTime(2026, 8, 1);
  return List.generate(count, (i) => _tx(now.add(Duration(days: i)), amountFn(i)));
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await InventoryService.instance.load();
  });

  group('generate', () {
    test('empty transactions returns info insight', () {
      final result = AIInsightService.generate([]);
      expect(result.length, 1);
      expect(result.first.priority, 'info');
    });

    test('growing sales produces positive insight', () {
      final data = _series(20, (i) => 100.0 + i * 50);
      final result = AIInsightService.generate(data);
      final icons = result.map((r) => r.icon).toList();
      expect(icons, contains('🚀'));
    });

    test('declining sales produces warning insight', () {
      final data = _series(20, (i) => 2000.0 - i * 100);
      final result = AIInsightService.generate(data);
      final priorities = result.map((r) => r.priority).toList();
      expect(priorities, contains('warning'));
    });

    test('stable data produces consistent insight', () {
      final data = _series(10, (i) => 100.0);
      final result = AIInsightService.generate(data);
      final icons = result.map((r) => r.icon).toList();
      expect(icons, contains('✅'));
    });

    test('anomaly detected in spike data', () {
      final data = _series(10, (i) => i == 9 ? 50000.0 : 100.0);
      final result = AIInsightService.generate(data);
      final icons = result.map((r) => r.icon).toList();
      expect(icons, contains('🔥'));
    });

    test('all insights have required fields', () {
      final data = _series(20, (i) => 100.0 + i * 10);
      final result = AIInsightService.generate(data);
      for (final insight in result) {
        expect(insight.icon.isNotEmpty, true);
        expect(insight.title.isNotEmpty, true);
        expect(insight.body.isNotEmpty, true);
        expect(insight.priority.isNotEmpty, true);
      }
    });
  });
}
