import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme/app_colors.dart';

/// Bar skeleton dengan efek shimmer (warna adaptif terang/gelap).
class NeoShimmerBar extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;

  const NeoShimmerBar({
    super.key,
    this.width,
    this.height = 14,
    this.radius = 8,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return Shimmer.fromColors(
      baseColor: c.outline.withAlpha(45),
      highlightColor: c.outline.withAlpha(170),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: c.outline,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

/// Kartu skeleton neo-brutalist (border hitam + shadow) meniru kartu konten:
/// kotak ikon kiri + beberapa bar teks + bar trailing kanan.
class NeoShimmerCard extends StatelessWidget {
  final double? width;
  final double height;
  final double boxSize;
  final int lines;
  final bool trailing;
  final double radius;

  const NeoShimmerCard({
    super.key,
    this.width,
    this.height = 76,
    this.boxSize = 36,
    this.lines = 2,
    this.trailing = false,
    this.radius = 14,
  });

  static const _barWidths = [0.52, 0.85, 0.66, 0.9, 0.4, 0.75];

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: c.borderBlack,
          width: AppColors.borderWidth,
        ),
        boxShadow: [
          BoxShadow(
            color: c.borderBlack,
            offset: const Offset(2.5, 2.5),
            blurRadius: 0,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NeoShimmerBar(width: boxSize, height: boxSize, radius: radius * 0.55),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(lines, (i) {
                return Padding(
                  padding: EdgeInsets.only(bottom: i < lines - 1 ? 8 : 0),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: _barWidths[i % _barWidths.length],
                    child: const NeoShimmerBar(height: 13),
                  ),
                );
              }),
            ),
          ),
          if (trailing) ...[
            const SizedBox(width: 14),
            const NeoShimmerBar(width: 54, height: 16),
          ],
        ],
      ),
    );
  }
}
