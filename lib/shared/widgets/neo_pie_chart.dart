import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/app_l10n.dart';
import 'neo_card.dart';

class PieChartDataSection {
  final String label;
  final double value;
  final Color color;

  PieChartDataSection({
    required this.label,
    required this.value,
    required this.color,
  });
}

class NeoPieChart extends StatelessWidget {
  final String title;
  final List<PieChartDataSection> sections;

  const NeoPieChart({
    super.key,
    this.title = 'Kategori Pengeluaran',
    required this.sections,
  });

  @override
  Widget build(BuildContext context) {
    final total = sections.fold(0.0, (sum, item) => sum + item.value);

    return NeoCard(
      borderRadius: 24,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.headlineMedium?.copyWith(fontSize: 16),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.borderBlack, width: 1.5),
                ),
                child: Text(
                  tr('dash_bulan_ini'),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              // Custom Painted Pie Chart
              SizedBox(
                width: 110,
                height: 110,
                child: CustomPaint(
                  painter: _NeoPieChartPainter(
                    sections: sections,
                    total: total,
                  ),
                ),
              ),
              const SizedBox(width: 18),

              // Legend Column
              Expanded(
                child: Column(
                  children: sections.map((section) {
                    final percentage = total > 0
                        ? ((section.value / total) * 100).toStringAsFixed(0)
                        : '0';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        children: [
                          Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: section.color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.borderBlack,
                                width: 1.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              section.label,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: AppColors.borderBlack,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              '$percentage%',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NeoPieChartPainter extends CustomPainter {
  final List<PieChartDataSection> sections;
  final double total;

  _NeoPieChartPainter({required this.sections, required this.total});

  @override
  void paint(Canvas canvas, Size size) {
    if (total <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2) - 4;
    double startAngle = -pi / 2;

    final paintStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..color = AppColors.borderBlack;

    for (var section in sections) {
      final sweepAngle = (section.value / total) * 2 * pi;
      final paintFill = Paint()
        ..style = PaintingStyle.fill
        ..color = section.color;

      // Draw Slice
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paintFill,
      );

      // Draw Slice Border
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paintStroke,
      );

      startAngle += sweepAngle;
    }

    // Inner Donut Hole (Optional for donut style)
    final innerRadius = radius * 0.45;
    final holePaint = Paint()
      ..style = PaintingStyle.fill
      ..color = AppColors.surfaceContainerLowest;
    canvas.drawCircle(center, innerRadius, holePaint);
    canvas.drawCircle(center, innerRadius, paintStroke);
  }

  @override
  bool shouldRepaint(covariant _NeoPieChartPainter oldDelegate) => true;
}
