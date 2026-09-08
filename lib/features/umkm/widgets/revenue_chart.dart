import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/utils/app_l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/transaksi_umkm.dart';

class RevenueChart extends StatelessWidget {
  final List<TransaksiUmkm> transactions;
  final int days;

  const RevenueChart({
    super.key,
    required this.transactions,
    this.days = 7,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final daily = _dailyRevenue(transactions, days);
    
    if (daily.isEmpty) {
      return SizedBox(
        height: 160,
        child: Center(
          child: Text(
            tr('inv_belum_data'),
            style: TextStyle(color: c.outline, fontSize: 12),
          ),
        ),
      );
    }

    final maxY = daily.map((d) => d.value).fold<double>(0, (a, b) => a > b ? a : b);

    return SizedBox(
      height: 160,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY > 0 ? maxY / 4 : 1,
            getDrawingHorizontalLine: (value) => FlLine(
              color: c.outlineVariant.withValues(alpha: 0.3),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  if (value >= 1000000) return Text('${(value / 1000000).toStringAsFixed(0)}M', style: TextStyle(fontSize: 9, color: c.onSurfaceVariant));
                  if (value >= 1000) return Text('${(value / 1000).toStringAsFixed(0)}K', style: TextStyle(fontSize: 9, color: c.onSurfaceVariant));
                  return Text('${value.toInt()}', style: TextStyle(fontSize: 9, color: c.onSurfaceVariant));
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx >= 0 && idx < daily.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        daily[idx].label,
                        style: TextStyle(fontSize: 9, color: c.onSurfaceVariant),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final val = spot.y;
                  final formatted = val >= 1000 ? '${(val / 1000).toStringAsFixed(0)}K' : val.toInt().toString();
                  return LineTooltipItem(
                    'Rp$formatted',
                    TextStyle(color: c.background, fontWeight: FontWeight.w700, fontSize: 11),
                  );
                }).toList();
              },
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(daily.length, (i) => FlSpot(i.toDouble(), daily[i].value)),
              isCurved: true,
              curveSmoothness: 0.3,
              color: c.primary,
              barWidth: 2.5,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                  radius: 3,
                  color: c.primary,
                  strokeWidth: 1.5,
                  strokeColor: c.background,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    c.primary.withValues(alpha: 0.3),
                    c.primary.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<({String label, double value})> _dailyRevenue(List<TransaksiUmkm> data, int days) {
    final now = DateTime.now();
    final result = <({String label, double value})>[];
    
    for (var i = days - 1; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dayTotal = data
          .where((t) =>
              t.date.year == date.year &&
              t.date.month == date.month &&
              t.date.day == date.day)
          .fold<double>(0, (sum, t) => sum + t.totalAmount);
      
      final label = '${date.day}/${date.month}';
      result.add((label: label, value: dayTotal));
    }
    
    return result;
  }
}
