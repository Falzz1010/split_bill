import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'neo_card.dart';

class LinePoint {
  final String label;
  final double value;

  LinePoint(this.label, this.value);
}

class NeoLineChart extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<LinePoint> data;

  const NeoLineChart({
    super.key,
    this.title = 'Tren Split Bill',
    this.subtitle = 'Total pengeluaran 6 bulan terakhir',
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final maxValue = data.fold(1.0, (maxVal, item) => item.value > maxVal ? item.value : maxVal);

    return NeoCard(
      borderRadius: 24,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 16),
                    ),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.secondaryContainer,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.borderBlack, width: 1.5),
                ),
                child: Icon(Icons.trending_up_rounded, color: AppColors.secondary, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Custom Painted Line Chart
          SizedBox(
            height: 140,
            width: double.infinity,
            child: CustomPaint(
              painter: _NeoLineChartPainter(data: data, maxValue: maxValue),
            ),
          ),
          const SizedBox(height: 12),

          // X-Axis Month Labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: data.map((item) {
              return Expanded(
                child: Center(
                  child: Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _NeoLineChartPainter extends CustomPainter {
  final List<LinePoint> data;
  final double maxValue;

  _NeoLineChartPainter({required this.data, required this.maxValue});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;

    final widthStep = size.width / (data.length - 1);
    final points = <Offset>[];

    for (int i = 0; i < data.length; i++) {
      final x = i * widthStep;
      final y = size.height - ((data[i].value / maxValue) * (size.height - 20)) - 10;
      points.add(Offset(x, y));
    }

    // Grid Background Lines
    final gridPaint = Paint()
      ..color = AppColors.outlineVariant.withAlpha(120)
      ..strokeWidth = 1.0;

    for (int i = 1; i <= 3; i++) {
      final y = size.height * (i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Path Fill Area
    final fillPath = Path()..moveTo(points.first.dx, size.height);
    for (var point in points) {
      fillPath.lineTo(point.dx, point.dy);
    }
    fillPath.lineTo(points.last.dx, size.height);
    fillPath.close();

    final fillPaint = Paint()
      ..color = AppColors.primaryContainer.withAlpha(140)
      ..style = PaintingStyle.fill;
    canvas.drawPath(fillPath, fillPaint);

    // Thick Neo-Brutalist Line Stroke
    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      linePath.lineTo(points[i].dx, points[i].dy);
    }

    final linePaint = Paint()
      ..color = AppColors.borderBlack
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(linePath, linePaint);

    // Data Point Nodes (Circles)
    final nodeFillPaint = Paint()
      ..color = AppColors.secondaryContainer
      ..style = PaintingStyle.fill;

    final nodeBorderPaint = Paint()
      ..color = AppColors.borderBlack
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    for (var point in points) {
      canvas.drawCircle(point, 6, nodeFillPaint);
      canvas.drawCircle(point, 6, nodeBorderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _NeoLineChartPainter oldDelegate) => true;
}
