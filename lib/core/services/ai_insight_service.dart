import '../models/transaksi_umkm.dart';
import 'sales_analytics_service.dart';
import 'inventory_service.dart';

/// AI Insight — rekomendasi otomatis dari data analytics lokal.
class AIInsightService {
  AIInsightService._();

  /// Generate semua insight dari data transaksi dan inventory.
  static List<({String icon, String title, String body, String priority})> generate(
    List<TransaksiUmkm> transactions,
  ) {
    final insights = <({String icon, String title, String body, String priority})>[];

    if (transactions.isEmpty) {
      return [(icon: '📊', title: 'Belum ada data', body: 'Mulai catat transaksi untuk mendapat insight.', priority: 'info')];
    }

    // 1. Growth analysis
    final weeklyGrowth = SalesAnalyticsService.weeklyGrowthRate(transactions);
    if (weeklyGrowth > 10) {
      insights.add((
        icon: '🚀',
        title: 'Penjualan Naik!',
        body: 'Omzet minggu ini naik ${weeklyGrowth.toStringAsFixed(1)}% dari minggu lalu. Pertahankan strategi saat ini.',
        priority: 'positive',
      ));
    } else if (weeklyGrowth < -10) {
      insights.add((
        icon: '⚠️',
        title: 'Penjualan Turun',
        body: 'Omzet minggu ini turun ${weeklyGrowth.abs().toStringAsFixed(1)}%. Perlu evaluasi promosi atau menu.',
        priority: 'warning',
      ));
    }

    // 2. Trend analysis
    final trend = SalesAnalyticsService.trendAnalysis(transactions);
    if (trend.direction == 'Naik' && trend.confidence > 0.6) {
      insights.add((
        icon: '📈',
        title: 'Tren Positif',
        body: 'Penjualan menunjukkan tren naik dengan keyakinan ${(trend.confidence * 100).toStringAsFixed(0)}%. Revenue terus meningkat.',
        priority: 'positive',
      ));
    } else if (trend.direction == 'Turun' && trend.confidence > 0.6) {
      insights.add((
        icon: '📉',
        title: 'Tren Menurun',
        body: 'Penjualan tren turun dengan keyakinan ${(trend.confidence * 100).toStringAsFixed(0)}%. Segeraambil langkah.',
        priority: 'warning',
      ));
    }

    // 3. Revenue consistency
    final cv = SalesAnalyticsService.revenueCV(transactions);
    if (cv.level == 'Konsisten') {
      insights.add((
        icon: '✅',
        title: 'Pendapatan Stabil',
        body: 'CV ${cv.value.toStringAsFixed(1)}% — omzet konsisten. Bagus untuk perencanaan stok dan budget.',
        priority: 'positive',
      ));
    } else if (cv.level == 'Fluktuatif') {
      insights.add((
        icon: '🔄',
        title: 'Omzet Tidak Stabil',
        body: 'CV ${cv.value.toStringAsFixed(1)}% — fluktuasi tinggi. Identifikasi penyebab: weekend rush? event?',
        priority: 'warning',
      ));
    }

    // 4. Anomaly detection
    final anomalies = SalesAnalyticsService.detectAnomalies(transactions);
    if (anomalies.isNotEmpty) {
      final last = anomalies.last;
      insights.add((
        icon: last.type == 'Spike' ? '🔥' : '❄️',
        title: 'Anomali Terdeteksi',
        body: '${last.type} pada ${last.label}: Rp${(last.value / 1000).toStringAsFixed(0)}K. Periksa penyebabnya.',
        priority: 'info',
      ));
    }

    // 5. Best day
    final weekly = SalesAnalyticsService.weeklyPattern(transactions);
    if (weekly.isNotEmpty) {
      final best = weekly.reduce((a, b) => a.avg > b.avg ? a : b);
      final worst = weekly.reduce((a, b) => a.avg < b.avg ? a : b);
      if (best.dayOfWeek != worst.dayOfWeek) {
        insights.add((
          icon: '📅',
          title: 'Pola Mingguan',
          body: 'Hari terbaik: ${best.label} (Rp${(best.avg / 1000).toStringAsFixed(0)}K). Hari terlemah: ${worst.label}.',
          priority: 'info',
        ));
      }
    }

    // 6. Top item
    final abc = SalesAnalyticsService.abcAnalysis(transactions);
    if (abc.isNotEmpty) {
      final top = abc.first;
      insights.add((
        icon: '⭐',
        title: 'Item Terlaris',
        body: '${top.name} menyumbang ${top.cumPercent.toStringAsFixed(1)}% dari total omzet. Pertahankan ketersediaannya.',
        priority: 'positive',
      ));
    }

    // 7. Inventory alerts
    final lowStock = InventoryService.instance.lowStockItems;
    final criticalStock = InventoryService.instance.criticalItems;
    if (criticalStock.isNotEmpty) {
      insights.add((
        icon: '🚨',
        title: 'Stok Kritis!',
        body: '${criticalStock.length} item hampir habis: ${criticalStock.map((i) => i.name).join(', ')}. Segera restock!',
        priority: 'critical',
      ));
    } else if (lowStock.isNotEmpty) {
      insights.add((
        icon: '📦',
        title: 'Stok Rendah',
        body: '${lowStock.length} item perlu restock: ${lowStock.map((i) => i.name).join(', ')}.',
        priority: 'warning',
      ));
    }

    // 8. Waste detection
    final waste = InventoryService.instance.wasteEstimate(transactions);
    if (waste.isNotEmpty) {
      final totalLoss = waste.fold<double>(0, (s, w) => s + w.loss);
      insights.add((
        icon: '💰',
        title: 'Potensi Waste',
        body: 'Item dijual di bawah modal: ${waste.map((w) => w.name).join(', ')}. Total kerugian: Rp${(totalLoss / 1000).toStringAsFixed(0)}K.',
        priority: 'warning',
      ));
    }

    // 9. Cash flow projection
    final projection = SalesAnalyticsService.projectCashFlow(transactions);
    if (projection.isNotEmpty) {
      final nextDay = projection.first;
      insights.add((
        icon: '🔮',
        title: 'Prediksi Besok',
        body: 'Revenue diprediksi ${nextDay.confidence == 'Tinggi' ? '' : '(estimasi) '}Rp${(nextDay.projected / 1000).toStringAsFixed(0)}K.',
        priority: 'info',
      ));
    }

    return insights;
  }
}
