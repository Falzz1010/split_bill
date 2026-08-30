import 'dart:math';
import '../models/transaksi_umkm.dart';

/// Sales Analytics Engine — 100% lokal, tanpa API.
/// Algoritma: Moving Average, Growth Rate, Std Dev, Anomaly Detection,
/// Trend Analysis, Seasonality, Cash Flow Projection.
class SalesAnalyticsService {
  SalesAnalyticsService._();

  // ─── Moving Average ──────────────────────────────────────────────

  /// Simple Moving Average (SMA) dari daily revenue N hari terakhir.
  static List<({String label, double value})> sma(
    List<TransaksiUmkm> data, {
    int period = 7,
  }) {
    final daily = _dailyRevenue(data);
    if (daily.length < period) return daily;

    final result = <({String label, double value})>[];
    for (var i = period - 1; i < daily.length; i++) {
      var sum = 0.0;
      for (var j = i - period + 1; j <= i; j++) {
        sum += daily[j].value;
      }
      result.add((label: daily[i].label, value: sum / period));
    }
    return result;
  }

  /// Exponential Moving Average (EMA) — lebih responsif terhadap perubahan terbaru.
  static List<({String label, double value})> ema(
    List<TransaksiUmkm> data, {
    int period = 7,
  }) {
    final daily = _dailyRevenue(data);
    if (daily.isEmpty) return [];
    if (daily.length < period) return daily;

    final k = 2.0 / (period + 1);
    final result = <({String label, double value})>[];

    // SMA awal
    var emaVal = 0.0;
    for (var i = 0; i < period; i++) {
      emaVal += daily[i].value;
    }
    emaVal /= period;
    result.add((label: daily[period - 1].label, value: emaVal));

    for (var i = period; i < daily.length; i++) {
      emaVal = daily[i].value * k + emaVal * (1 - k);
      result.add((label: daily[i].label, value: emaVal));
    }
    return result;
  }

  // ─── Growth Rate ─────────────────────────────────────────────────

  /// Growth rate harian (%): (today - yesterday) / yesterday * 100.
  static double dailyGrowthRate(List<TransaksiUmkm> data) {
    final daily = _dailyRevenue(data);
    if (daily.length < 2) return 0;
    final today = daily.last.value;
    final yesterday = daily[daily.length - 2].value;
    if (yesterday == 0) return today > 0 ? 100 : 0;
    return ((today - yesterday) / yesterday) * 100;
  }

  /// Growth rate mingguan: rata-rata harian minggu ini vs minggu lalu.
  static double weeklyGrowthRate(List<TransaksiUmkm> data) {
    final daily = _dailyRevenue(data);
    if (daily.length < 14) return 0;
    final thisWeek = daily.sublist(daily.length - 7);
    final lastWeek = daily.sublist(daily.length - 14, daily.length - 7);
    final avgThis = thisWeek.fold(0.0, (s, d) => s + d.value) / 7;
    final avgLast = lastWeek.fold(0.0, (s, d) => s + d.value) / 7;
    if (avgLast == 0) return avgThis > 0 ? 100 : 0;
    return ((avgThis - avgLast) / avgLast) * 100;
  }

  /// Growth rate bulanan: total bulan ini vs bulan lalu.
  static double monthlyGrowthRate(List<TransaksiUmkm> data) {
    final now = DateTime.now();
    final thisMonth = _monthTotal(data, now.year, now.month);
    final lastMonth = _monthTotal(data, now.month == 1 ? now.year - 1 : now.year,
        now.month == 1 ? 12 : now.month - 1);
    if (lastMonth == 0) return thisMonth > 0 ? 100 : 0;
    return ((thisMonth - lastMonth) / lastMonth) * 100;
  }

  // ─── Standard Deviation (Volatility) ─────────────────────────────

  /// Standar deviasi daily revenue — mengukur konsistensi penjualan.
  static double revenueStdDev(List<TransaksiUmkm> data) {
    final daily = _dailyRevenue(data).map((d) => d.value).toList();
    if (daily.length < 2) return 0;
    final mean = daily.fold(0.0, (s, v) => s + v) / daily.length;
    final variance = daily.fold(0.0, (s, v) => s + pow(v - mean, 2)) / daily.length;
    return sqrt(variance);
  }

  /// Coefficient of variation (CV) — stdDev / mean * 100.
  /// CV < 20% = konsisten, 20-50% = variabel, > 50% = sangat fluktuatif.
  static ({double value, String level, String description}) revenueCV(
      List<TransaksiUmkm> data) {
    final daily = _dailyRevenue(data).map((d) => d.value).toList();
    if (daily.isEmpty) return (value: 0, level: '-', description: 'Belum ada data');
    final mean = daily.fold(0.0, (s, v) => s + v) / daily.length;
    if (mean == 0) return (value: 0, level: '-', description: 'Tidak ada penjualan');
    final std = revenueStdDev(data);
    final cv = (std / mean) * 100;

    if (cv < 20) return (value: cv, level: 'Konsisten', description: 'Penjualan stabil, mudah diprediksi');
    if (cv < 50) return (value: cv, level: 'Variabel', description: 'Ada fluktuasi, perlu monitoring');
    return (value: cv, level: 'Fluktuatif', description: 'Penjualan tidak stabil, perlu investigasi');
  }

  // ─── Anomaly Detection ───────────────────────────────────────────

  /// Deteksi anomali: revenue yang > 2 stdDev dari rata-rata.
  static List<({String label, double value, String type})> detectAnomalies(
    List<TransaksiUmkm> data,
  ) {
    final daily = _dailyRevenue(data);
    if (daily.length < 5) return [];

    final values = daily.map((d) => d.value).toList();
    final mean = values.fold(0.0, (s, v) => s + v) / values.length;
    final std = sqrt(values.fold(0.0, (s, v) => s + pow(v - mean, 2)) / values.length);
    if (std == 0) return [];

    final anomalies = <({String label, double value, String type})>[];
    for (final d in daily) {
      final zScore = (d.value - mean).abs() / std;
      if (zScore > 2) {
        final type = d.value > mean ? 'Spike' : 'Drop';
        anomalies.add((label: d.label, value: d.value, type: type));
      }
    }
    return anomalies;
  }

  // ─── Trend Analysis ──────────────────────────────────────────────

  /// Linear regression slope — positif = naik, negatif = turun.
  static ({double slope, String direction, double confidence}) trendAnalysis(
    List<TransaksiUmkm> data,
  ) {
    final daily = _dailyRevenue(data).map((d) => d.value).toList();
    if (daily.length < 3) return (slope: 0, direction: 'Data kurang', confidence: 0);

    final n = daily.length;
    final xMean = (n - 1) / 2.0;
    final yMean = daily.fold(0.0, (s, v) => s + v) / n;

    var ssxy = 0.0;
    var ssxx = 0.0;
    for (var i = 0; i < n; i++) {
      ssxy += (i - xMean) * (daily[i] - yMean);
      ssxx += pow(i - xMean, 2);
    }
    if (ssxx == 0) return (slope: 0, direction: 'Data kurang', confidence: 0);

    final slope = ssxy / ssxx;

    // R-squared
    final ssTot = daily.fold(0.0, (s, v) => s + pow(v - yMean, 2));
    final ssRes = daily.fold(0.0, (s, v) {
      final predicted = yMean + slope * (daily.indexOf(v) - xMean);
      return s + pow(v - predicted, 2);
    });
    final rSquared = ssTot > 0 ? 1 - (ssRes / ssTot) : 0.0;
    final confidence = rSquared.clamp(0.0, 1.0);

    String direction;
    if (slope > yMean * 0.01) {
      direction = 'Naik';
    } else if (slope < -yMean * 0.01) {
      direction = 'Turun';
    } else {
      direction = 'Stabil';
    }

    return (slope: slope, direction: direction, confidence: confidence);
  }

  // ─── Seasonality ─────────────────────────────────────────────────

  /// Rata-rata revenue per hari dalam seminggu (0=Senin, 6=Minggu).
  static List<({int dayOfWeek, String label, double avg})> weeklyPattern(
    List<TransaksiUmkm> data,
  ) {
    final labels = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    final dayTotals = List.filled(7, 0.0);
    final dayCounts = List.filled(7, 0);

    for (final t in data) {
      final dow = (t.date.weekday - 1) % 7;
      dayTotals[dow] += t.totalAmount;
      dayCounts[dow]++;
    }

    final result = <({int dayOfWeek, String label, double avg})>[];
    for (var i = 0; i < 7; i++) {
      final avg = dayCounts[i] > 0 ? dayTotals[i] / dayCounts[i] : 0.0;
      result.add((dayOfWeek: i, label: labels[i], avg: avg));
    }
    return result;
  }

  /// Peak hour distribution.
  static List<({int hour, String label, int count})> hourlyPattern(
    List<TransaksiUmkm> data,
  ) {
    final hours = List.filled(24, 0);
    for (final t in data) {
      hours[t.date.hour]++;
    }
    return List.generate(24, (i) => (
          hour: i,
          label: '${i.toString().padLeft(2, '0')}:00',
          count: hours[i],
        )).where((h) => h.count > 0).toList();
  }

  // ─── Item Analytics ──────────────────────────────────────────────

  /// ABC Analysis: A = top 80% revenue, B = next 15%, C = rest 5%.
  static List<({String name, double revenue, double cumPercent, String class_})> abcAnalysis(
    List<TransaksiUmkm> data,
  ) {
    final itemRevenue = <String, double>{};
    for (final t in data) {
      for (final i in t.items) {
        itemRevenue[i.name] = (itemRevenue[i.name] ?? 0) + i.lineTotal;
      }
    }

    final totalRevenue = itemRevenue.values.fold(0.0, (s, v) => s + v);
    if (totalRevenue == 0) return [];

    final sorted = itemRevenue.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    var cumRevenue = 0.0;
    final result = <({String name, double revenue, double cumPercent, String class_})>[];
    for (final e in sorted) {
      cumRevenue += e.value;
      final cumPercent = (cumRevenue / totalRevenue) * 100;
      String class_;
      if (cumPercent <= 80) {
        class_ = 'A';
      } else if (cumPercent <= 95) {
        class_ = 'B';
      } else {
        class_ = 'C';
      }
      result.add((name: e.key, revenue: e.value, cumPercent: cumPercent, class_: class_));
    }
    return result;
  }

  /// Margin analysis per item.
  static List<({String name, double price, double cost, double margin, int totalSold, String status})>
      marginAnalysis(List<TransaksiUmkm> data) {
    final items = <String, ({double price, double cost, int qty})>{};
    for (final t in data) {
      for (final i in t.items) {
        final existing = items[i.name];
        items[i.name] = (
          price: existing?.price ?? i.price,
          cost: existing?.cost ?? i.costPrice,
          qty: (existing?.qty ?? 0) + i.quantity,
        );
      }
    }

    return items.entries.map((e) {
      final margin = e.value.price > 0
          ? ((e.value.price - e.value.cost) / e.value.price * 100)
          : 0.0;

      String status;
      if (margin >= 60) status = 'Sangat Menguntungkan';
      else if (margin >= 40) status = 'Menguntungkan';
      else if (margin >= 20) status = 'Cukup';
      else status = 'Rendah';

      return (
        name: e.key,
        price: e.value.price,
        cost: e.value.cost,
        margin: margin,
        totalSold: e.value.qty,
        status: status,
      );
    }).toList()
      ..sort((a, b) => b.margin.compareTo(a.margin));
  }

  // ─── Cash Flow Projection ────────────────────────────────────────

  /// Proyeksi cash flow 7 hari ke depan menggunakan EMA.
  static List<({String label, double projected, String confidence})> projectCashFlow(
    List<TransaksiUmkm> data, {
    int days = 7,
  }) {
    final emaData = ema(data, period: 7);
    if (emaData.isEmpty) {
      return List.generate(days, (i) {
        final d = DateTime.now().add(Duration(days: i + 1));
        return (
          label: '${d.day}/${d.month}',
          projected: 0.0,
          confidence: 'Tidak ada data',
        );
      });
    }

    final lastEma = emaData.last.value;
    final trend = trendAnalysis(data);
    final dailySlope = trend.slope;

    final result = <({String label, double projected, String confidence})>[];
    for (var i = 1; i <= days; i++) {
      final projected = lastEma + (dailySlope * i);
      final conf = i <= 3 ? 'Tinggi' : (i <= 5 ? 'Sedang' : 'Rendah');
      final d = DateTime.now().add(Duration(days: i));
      result.add((
        label: '${d.day}/${d.month}',
        projected: projected < 0 ? 0 : projected,
        confidence: conf,
      ));
    }
    return result;
  }

  // ─── Helpers ─────────────────────────────────────────────────────

  static List<({String label, double value})> _dailyRevenue(
      List<TransaksiUmkm> data) {
    final map = <String, ({DateTime date, double total})>{};
    for (final t in data) {
      final key = '${t.date.year}-${t.date.month}-${t.date.day}';
      final existing = map[key];
      map[key] = (
        date: t.date,
        total: (existing?.total ?? 0) + t.totalAmount,
      );
    }

    final sorted = map.entries.toList()
      ..sort((a, b) => a.value.date.compareTo(b.value.date));

    return sorted
        .map((e) => (
              label:
                  '${e.value.date.day}/${e.value.date.month}',
              value: e.value.total,
            ))
        .toList();
  }

  static double _monthTotal(List<TransaksiUmkm> data, int year, int month) {
    return data
        .where((t) => t.date.year == year && t.date.month == month)
        .fold(0.0, (s, t) => s + t.totalAmount);
  }
}
