import 'package:flutter/material.dart';
import '../../../core/utils/app_l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/state/transaksi_umkm_store.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/widgets/neo_card.dart';
import '../../../shared/widgets/neo_pie_chart.dart';
import '../../../shared/widgets/neo_line_chart.dart';

class UmkmLaporanScreen extends StatelessWidget {
  const UmkmLaporanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.palette;

    return ListenableBuilder(
      listenable: TransaksiUmkmStore.instance,
      builder: (context, _) {
        final store = TransaksiUmkmStore.instance;

        if (store.isLoading) {
          return Scaffold(
            backgroundColor: c.background,
            body: Center(child: CircularProgressIndicator(color: c.primary)),
          );
        }

        return Scaffold(
          backgroundColor: c.background,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Icon(Icons.assessment_rounded, size: 28, color: c.primary),
                      const SizedBox(width: 10),
                      Text(
                        tr('nav_shift'),
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontSize: 22, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Grafik & Laporan Transaksi UMKM',
                    style: TextStyle(fontSize: 13, color: c.onSurfaceVariant),
                  ),
                  const SizedBox(height: 20),

                  // PPN Summary
                  _buildPpnSummary(context, store),
                  const SizedBox(height: 16),

                  // Line Chart: Tren Omzet 6 Bulan
                  NeoLineChart(
                    title: 'Tren Omzet 6 Bulan',
                    subtitle: 'Total omzet per bulan (Ribu Rp)',
                    emptyText: 'Belum ada data omzet',
                    data: _buildLineData(store),
                  ),
                  const SizedBox(height: 16),

                  // Pie Chart: Kategori Transaksi
                  NeoPieChart(
                    title: 'Kategori Transaksi',
                    sections: _buildPieSections(context, store),
                  ),
                  const SizedBox(height: 16),

                  // Top Menu
                  _buildTopMenu(context, store),
                  const SizedBox(height: 16),

                  // Tabel Rekap Bulanan
                  _buildMonthlyRecap(context, store),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPpnSummary(BuildContext context, TransaksiUmkmStore store) {
    final c = context.palette;
    final now = DateTime.now();
    final monthPpn = store.transaksi
        .where((t) => t.date.year == now.year && t.date.month == now.month)
        .fold(0.0, (sum, t) => sum + t.ppn);
    final monthTotal = store.monthRevenue;
    final monthCount = store.transaksi
        .where((t) => t.date.year == now.year && t.date.month == now.month)
        .length;

    return NeoCard(
      backgroundColor: c.primaryContainer,
      child: Row(
        children: [
          Icon(Icons.account_balance_rounded, size: 32, color: c.onPrimaryContainer),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rekap PPN Bulan Ini',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: c.onPrimaryContainer.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formatCurrency(monthPpn),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: c.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$monthCount transaksi · Total ${formatCurrency(monthTotal)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: c.onPrimaryContainer.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<LinePoint> _buildLineData(TransaksiUmkmStore store) {
    final monthly = store.monthlyRevenue(months: 6);
    return monthly.map((m) => LinePoint(m.label, m.total / 1000)).toList();
  }

  List<PieChartDataSection> _buildPieSections(BuildContext context, TransaksiUmkmStore store) {
    final c = context.palette;
    final breakdown = store.categoryBreakdown();

    if (breakdown.isEmpty) {
      return [
        PieChartDataSection(
          label: 'Belum Ada Data',
          value: 100,
          color: c.surfaceContainerHigh,
        ),
      ];
    }

    final colors = [
      c.primaryContainer,
      c.secondaryContainer,
      c.errorContainer,
      c.surfaceContainerHigh,
      c.primaryFixed,
    ];

    int i = 0;
    return breakdown.map((e) {
      final color = colors[i % colors.length];
      i++;
      return PieChartDataSection(
        label: e.category,
        value: e.total,
        color: color,
      );
    }).toList();
  }

  Widget _buildTopMenu(BuildContext context, TransaksiUmkmStore store) {
    final c = context.palette;
    final top5 = store.topItems(limit: 5);

    if (top5.isEmpty) {
      return const SizedBox.shrink();
    }

    final maxQty = top5.first.qty.toDouble();

    return NeoCard(
      backgroundColor: c.surfaceContainerLowest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.leaderboard_rounded, size: 18, color: c.primary),
              const SizedBox(width: 6),
              const Text(
                'Top 5 Menu Terlaris',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...top5.asMap().entries.map((entry) {
            final idx = entry.key;
            final item = entry.value;
            final pct = maxQty > 0 ? item.qty / maxQty : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '${idx + 1}.',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          color: c.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          item.name,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${item.qty}x',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: c.primary),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        formatCurrency(item.revenue),
                        style: TextStyle(fontSize: 11, color: c.onSurfaceVariant),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 6,
                      backgroundColor: c.surfaceContainerLow,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        idx == 0 ? c.primary : idx == 1 ? c.secondary : c.outline,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMonthlyRecap(BuildContext context, TransaksiUmkmStore store) {
    final c = context.palette;
    final now = DateTime.now();

    final Map<int, ({double total, double ppn, int count})> monthly = {};
    for (final t in store.transaksi) {
      if (t.date.year == now.year) {
        final m = t.date.month;
        final existing = monthly[m];
        monthly[m] = (
          total: (existing?.total ?? 0) + t.totalAmount,
          ppn: (existing?.ppn ?? 0) + t.ppn,
          count: (existing?.count ?? 0) + 1,
        );
      }
    }

    if (monthly.isEmpty) return const SizedBox.shrink();

    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];

    return NeoCard(
      backgroundColor: c.surfaceContainerLowest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.table_chart_rounded, size: 18, color: c.primary),
              const SizedBox(width: 6),
              Text(
                'Rekap Bulanan ${now.year}',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: c.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text('Bulan',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: c.onPrimaryContainer)),
                ),
                Expanded(
                  flex: 2,
                  child: Text('Total',
                      textAlign: TextAlign.right,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: c.onPrimaryContainer)),
                ),
                Expanded(
                  flex: 2,
                  child: Text('PPN',
                      textAlign: TextAlign.right,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: c.onPrimaryContainer)),
                ),
                Expanded(
                  flex: 1,
                  child: Text('#',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: c.onPrimaryContainer)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          ...monthly.entries.toList().reversed.map((entry) {
            final m = months[entry.key - 1];
            final data = entry.value;
            final isCurrentMonth = entry.key == now.month;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: isCurrentMonth ? c.secondaryContainer.withOpacity(0.3) : null,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(m,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isCurrentMonth ? FontWeight.w800 : FontWeight.w600,
                        )),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(formatCurrency(data.total),
                        textAlign: TextAlign.right,
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: c.primary)),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(formatCurrency(data.ppn),
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontSize: 11)),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text('${data.count}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 11)),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
