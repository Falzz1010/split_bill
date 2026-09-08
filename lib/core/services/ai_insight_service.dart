import '../models/transaksi_umkm.dart';
import '../utils/app_l10n.dart';
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
      return [(icon: '📊', title: tr('ai_belum_data'), body: tr('ai_belum_data_desc'), priority: 'info')];
    }

    // 1. Growth analysis
    final weeklyGrowth = SalesAnalyticsService.weeklyGrowthRate(transactions);
    if (weeklyGrowth > 10) {
      insights.add((
        icon: '🚀',
        title: tr('ai_penjualan_naik'),
        body: tr('ai_penjualan_naik_desc').replaceAll('{growth}', weeklyGrowth.toStringAsFixed(1)),
        priority: 'positive',
      ));
    } else if (weeklyGrowth < -10) {
      insights.add((
        icon: '⚠️',
        title: tr('ai_penjualan_turun'),
        body: tr('ai_penjualan_turun_desc').replaceAll('{growth}', weeklyGrowth.abs().toStringAsFixed(1)),
        priority: 'warning',
      ));
    }

    // 2. Trend analysis
    final trend = SalesAnalyticsService.trendAnalysis(transactions);
    if (trend.direction == 'Naik' && trend.confidence > 0.6) {
      insights.add((
        icon: '📈',
        title: tr('ai_tren_positif'),
        body: tr('ai_tren_positif_desc').replaceAll('{confidence}', (trend.confidence * 100).toStringAsFixed(0)),
        priority: 'positive',
      ));
    } else if (trend.direction == 'Turun' && trend.confidence > 0.6) {
      insights.add((
        icon: '📉',
        title: tr('ai_tren_menurun'),
        body: tr('ai_tren_menurun_desc').replaceAll('{confidence}', (trend.confidence * 100).toStringAsFixed(0)),
        priority: 'warning',
      ));
    }

    // 3. Revenue consistency
    final cv = SalesAnalyticsService.revenueCV(transactions);
    if (cv.level == 'Konsisten') {
      insights.add((
        icon: '✅',
        title: tr('ai_pendapatan_stabil'),
        body: tr('ai_pendapatan_stabil_desc').replaceAll('{cv}', cv.value.toStringAsFixed(1)),
        priority: 'positive',
      ));
    } else if (cv.level == 'Fluktuatif') {
      insights.add((
        icon: '🔄',
        title: tr('ai_omzet_tidak_stabil'),
        body: tr('ai_omzet_tidak_stabil_desc').replaceAll('{cv}', cv.value.toStringAsFixed(1)),
        priority: 'warning',
      ));
    }

    // 4. Anomaly detection
    final anomalies = SalesAnalyticsService.detectAnomalies(transactions);
    if (anomalies.isNotEmpty) {
      final last = anomalies.last;
      insights.add((
        icon: last.type == 'Spike' ? '🔥' : '❄️',
        title: tr('ai_anomali'),
        body: tr('ai_anomali_desc').replaceAll('{type}', last.type).replaceAll('{label}', last.label).replaceAll('{value}', (last.value / 1000).toStringAsFixed(0)),
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
          title: tr('ai_pola_mingguan'),
          body: tr('ai_pola_mingguan_desc').replaceAll('{best_day}', best.label).replaceAll('{best_avg}', (best.avg / 1000).toStringAsFixed(0)).replaceAll('{worst_day}', worst.label),
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
        title: tr('ai_item_terlaris'),
        body: tr('ai_item_terlaris_desc').replaceAll('{name}', top.name).replaceAll('{percent}', top.cumPercent.toStringAsFixed(1)),
        priority: 'positive',
      ));
    }

    // 7. Inventory alerts
    final lowStock = InventoryService.instance.lowStockItems;
    final criticalStock = InventoryService.instance.criticalItems;
    if (criticalStock.isNotEmpty) {
      insights.add((
        icon: '🚨',
        title: tr('ai_stok_kritis'),
        body: tr('ai_stok_kritis_desc').replaceAll('{count}', '${criticalStock.length}').replaceAll('{items}', criticalStock.map((i) => i.name).join(', ')),
        priority: 'critical',
      ));
    } else if (lowStock.isNotEmpty) {
      insights.add((
        icon: '📦',
        title: tr('ai_stok_rendah'),
        body: tr('ai_stok_rendah_desc').replaceAll('{count}', '${lowStock.length}').replaceAll('{items}', lowStock.map((i) => i.name).join(', ')),
        priority: 'warning',
      ));
    }

    // 8. Waste detection
    final waste = InventoryService.instance.wasteEstimate(transactions);
    if (waste.isNotEmpty) {
      final totalLoss = waste.fold<double>(0, (s, w) => s + w.loss);
      insights.add((
        icon: '💰',
        title: tr('ai_potensi_waste'),
        body: tr('ai_potensi_waste_desc').replaceAll('{items}', waste.map((w) => w.name).join(', ')).replaceAll('{loss}', (totalLoss / 1000).toStringAsFixed(0)),
        priority: 'warning',
      ));
    }

    // 9. Cash flow projection
    final projection = SalesAnalyticsService.projectCashFlow(transactions);
    if (projection.isNotEmpty) {
      final nextDay = projection.first;
      insights.add((
        icon: '🔮',
        title: tr('ai_prediksi_besok'),
        body: tr('ai_prediksi_besok_desc').replaceAll('{estimation}', nextDay.confidence == 'Tinggi' ? '' : '(estimasi) ').replaceAll('{revenue}', (nextDay.projected / 1000).toStringAsFixed(0)),
        priority: 'info',
      ));
    }

    return insights;
  }
}
