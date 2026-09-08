import 'package:flutter_test/flutter_test.dart';
import 'package:fairsplit/core/models/transaksi_umkm.dart';
import 'package:fairsplit/core/services/sales_analytics_service.dart';

TransaksiUmkm _tx(DateTime date, double total) => TransaksiUmkm(
      id: 't${date.millisecond}',
      merchantName: 'Demo',
      date: date,
      items: [
        TransaksiItem(id: 'i1', name: 'Kopi', price: total, quantity: 1),
      ],
      subtotal: total,
      ppn: 0,
      serviceCharge: 0,
      totalAmount: total,
      paymentMethod: PaymentMethod.cash,
      amountPaid: total,
    );

List<TransaksiUmkm> _dailySeries(int count, double Function(int) amountFn) {
  final now = DateTime(2026, 8, 1);
  return List.generate(count, (i) => _tx(now.add(Duration(days: i)), amountFn(i)));
}

void main() {
  group('sma', () {
    test('returns raw data when fewer than period', () {
      final data = _dailySeries(3, (i) => 100 + i * 10);
      final result = SalesAnalyticsService.sma(data, period: 7);
      expect(result.length, 3);
    });

    test('computes rolling average over period', () {
      final data = _dailySeries(10, (i) => 100.0);
      final result = SalesAnalyticsService.sma(data, period: 3);
      expect(result.length, 8);
      expect(result.first.value, 100.0);
    });

    test('handles single day', () {
      final data = _dailySeries(1, (i) => 50.0);
      final result = SalesAnalyticsService.sma(data);
      expect(result.length, 1);
    });

    test('handles empty data', () {
      final result = SalesAnalyticsService.sma([]);
      expect(result, isEmpty);
    });
  });

  group('ema', () {
    test('returns empty for empty data', () {
      expect(SalesAnalyticsService.ema([]), isEmpty);
    });

    test('returns raw data when fewer than period', () {
      final data = _dailySeries(3, (i) => 100.0);
      final result = SalesAnalyticsService.ema(data, period: 7);
      expect(result.length, 3);
    });

    test('first EMA value equals SMA of first period', () {
      final data = _dailySeries(10, (i) => 100.0);
      final result = SalesAnalyticsService.ema(data, period: 5);
      expect(result.first.value, 100.0);
    });

    test('EMA reacts to changing values', () {
      final data = _dailySeries(8, (i) => i < 4 ? 100.0 : 200.0);
      final result = SalesAnalyticsService.ema(data, period: 4);
      expect(result.length, 5);
      expect(result.last.value, greaterThan(result.first.value));
    });
  });

  group('dailyGrowthRate', () {
    test('returns 0 for fewer than 2 days', () {
      final data = _dailySeries(1, (i) => 100.0);
      expect(SalesAnalyticsService.dailyGrowthRate(data), 0);
    });

    test('positive growth', () {
      final data = _dailySeries(2, (i) => i == 0 ? 100.0 : 150.0);
      expect(SalesAnalyticsService.dailyGrowthRate(data), 50.0);
    });

    test('negative growth', () {
      final data = _dailySeries(2, (i) => i == 0 ? 200.0 : 100.0);
      expect(SalesAnalyticsService.dailyGrowthRate(data), -50.0);
    });

    test('yesterday zero returns 100 if today positive', () {
      final data = [
        _tx(DateTime(2026, 8, 1), 0),
        _tx(DateTime(2026, 8, 2), 50),
      ];
      expect(SalesAnalyticsService.dailyGrowthRate(data), 100);
    });

    test('both zero returns 0', () {
      final data = [
        _tx(DateTime(2026, 8, 1), 0),
        _tx(DateTime(2026, 8, 2), 0),
      ];
      expect(SalesAnalyticsService.dailyGrowthRate(data), 0);
    });
  });

  group('trendAnalysis', () {
    test('returns Data kurang for fewer than 3 days', () {
      final data = _dailySeries(2, (i) => 100.0);
      final result = SalesAnalyticsService.trendAnalysis(data);
      expect(result.direction, 'Data kurang');
    });

    test('detects upward trend', () {
      final data = _dailySeries(10, (i) => 100.0 + i * 50);
      final result = SalesAnalyticsService.trendAnalysis(data);
      expect(result.direction, 'Naik');
      expect(result.slope, greaterThan(0));
    });

    test('detects downward trend', () {
      final data = _dailySeries(10, (i) => 500.0 - i * 50);
      final result = SalesAnalyticsService.trendAnalysis(data);
      expect(result.direction, 'Turun');
      expect(result.slope, lessThan(0));
    });

    test('detects stable trend', () {
      final data = _dailySeries(10, (i) => 100.0);
      final result = SalesAnalyticsService.trendAnalysis(data);
      expect(result.direction, 'Stabil');
    });

    test('confidence is between 0 and 1', () {
      final data = _dailySeries(10, (i) => 100.0 + i * 20);
      final result = SalesAnalyticsService.trendAnalysis(data);
      expect(result.confidence, inInclusiveRange(0, 1));
    });
  });

  group('revenueStdDev', () {
    test('returns 0 for fewer than 2 days', () {
      final data = _dailySeries(1, (i) => 100.0);
      expect(SalesAnalyticsService.revenueStdDev(data), 0);
    });

    test('constant data has 0 std dev', () {
      final data = _dailySeries(5, (i) => 100.0);
      expect(SalesAnalyticsService.revenueStdDev(data), 0);
    });

    test('variable data has positive std dev', () {
      final data = _dailySeries(5, (i) => (i % 2 == 0 ? 100.0 : 200.0));
      expect(SalesAnalyticsService.revenueStdDev(data), greaterThan(0));
    });
  });

  group('revenueCV', () {
    test('empty data returns dash level', () {
      final result = SalesAnalyticsService.revenueCV([]);
      expect(result.level, '-');
    });

    test('constant data is Konsisten', () {
      final data = _dailySeries(5, (i) => 100.0);
      final result = SalesAnalyticsService.revenueCV(data);
      expect(result.level, 'Konsisten');
    });
  });

  group('detectAnomalies', () {
    test('returns empty for fewer than 5 days', () {
      final data = _dailySeries(4, (i) => 100.0);
      expect(SalesAnalyticsService.detectAnomalies(data), isEmpty);
    });

    test('detects spike anomaly', () {
      final data = _dailySeries(10, (i) => i == 9 ? 10000.0 : 100.0);
      final anomalies = SalesAnalyticsService.detectAnomalies(data);
      expect(anomalies.isNotEmpty, true);
      expect(anomalies.last.type, 'Spike');
    });

    test('no anomalies for uniform data', () {
      final data = _dailySeries(10, (i) => 100.0);
      expect(SalesAnalyticsService.detectAnomalies(data), isEmpty);
    });
  });

  group('weeklyPattern', () {
    test('returns 7 entries', () {
      final data = _dailySeries(21, (i) => 100.0 + i * 10);
      final result = SalesAnalyticsService.weeklyPattern(data);
      expect(result.length, 7);
    });

    test('all day labels present', () {
      final result = SalesAnalyticsService.weeklyPattern([]);
      expect(result.map((r) => r.label), containsAll(['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min']));
    });
  });

  group('abcAnalysis', () {
    test('returns empty for no data', () {
      expect(SalesAnalyticsService.abcAnalysis([]), isEmpty);
    });

    test('single item always gets class C (100% cumulatively)', () {
      final data = _dailySeries(5, (i) => 100.0);
      final result = SalesAnalyticsService.abcAnalysis(data);
      expect(result.length, 1);
      expect(result.first.class_, 'C');
    });

    test('multiple items classified by cumulative revenue', () {
      final now = DateTime(2026, 8, 1);
      final data = [
        TransaksiUmkm(
          id: 't1', merchantName: 'Demo', date: now,
          items: [
            TransaksiItem(id: 'i1', name: 'Kopi', price: 500, quantity: 1),
            TransaksiItem(id: 'i2', name: 'Teh', price: 100, quantity: 1),
            TransaksiItem(id: 'i3', name: 'Roti', price: 50, quantity: 1),
          ],
          subtotal: 650, ppn: 0, serviceCharge: 0, totalAmount: 650,
          paymentMethod: PaymentMethod.cash, amountPaid: 650,
        ),
      ];
      final result = SalesAnalyticsService.abcAnalysis(data);
      expect(result.length, 3);
      expect(result[0].name, 'Kopi');
      expect(result[0].class_, 'A');
      expect(result[1].name, 'Teh');
      expect(result[1].class_, 'B');
      expect(result[2].name, 'Roti');
      expect(result[2].class_, 'C');
    });
  });
}
