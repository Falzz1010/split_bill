import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/transaksi_umkm.dart';

/// Dynamic QR Code widget — generates QR-style pattern based on transaction data.
class DynamicQRWidget extends StatelessWidget {
  final TransaksiUmkm transaksi;
  final double size;

  const DynamicQRWidget({
    super.key,
    required this.transaksi,
    this.size = 200,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final seed = transaksi.id.hashCode;
    final random = Random(seed);

    // Generate deterministic pattern based on transaction ID
    final modules = _generatePattern(random, 21);

    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.borderBlack, width: 2),
        boxShadow: [
          BoxShadow(
            color: c.borderBlack.withValues(alpha: 0.2),
            offset: const Offset(3, 3),
            blurRadius: 0,
          ),
        ],
      ),
      child: CustomPaint(
        painter: _QRPainter(
          modules: modules,
          moduleSize: (size - 16) / 21,
        ),
      ),
    );
  }

  List<List<bool>> _generatePattern(Random random, int size) {
    final modules = List.generate(size, (_) => List.filled(size, false));

    // Position detection patterns (3 corners)
    _drawFinderPattern(modules, 0, 0);
    _drawFinderPattern(modules, size - 7, 0);
    _drawFinderPattern(modules, 0, size - 7);

    // Timing patterns
    for (var i = 8; i < size - 8; i++) {
      modules[6][i] = i.isEven;
      modules[i][6] = i.isEven;
    }

    // Data modules (pseudo-random based on seed)
    for (var y = 0; y < size; y++) {
      for (var x = 0; x < size; x++) {
        if (modules[y][x]) continue; // Skip reserved areas
        if (x < 9 && y < 9) continue; // Top-left finder
        if (x >= size - 8 && y < 9) continue; // Top-right finder
        if (x < 9 && y >= size - 8) continue; // Bottom-left finder
        if (x == 6 || y == 6) continue; // Timing

        // Generate data pattern
        modules[y][x] = random.nextBool();
      }
    }

    return modules;
  }

  void _drawFinderPattern(List<List<bool>> modules, int startX, int startY) {
    for (var y = 0; y < 7; y++) {
      for (var x = 0; x < 7; x++) {
        if (y == 0 || y == 6 || x == 0 || x == 6) {
          modules[startY + y][startX + x] = true;
        } else if (y >= 2 && y <= 4 && x >= 2 && x <= 4) {
          modules[startY + y][startX + x] = true;
        } else {
          modules[startY + y][startX + x] = false;
        }
      }
    }
  }
}

class _QRPainter extends CustomPainter {
  final List<List<bool>> modules;
  final double moduleSize;

  _QRPainter({required this.modules, required this.moduleSize});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (var y = 0; y < modules.length; y++) {
      for (var x = 0; x < modules[y].length; x++) {
        if (modules[y][x]) {
          paint.color = Colors.black;
          canvas.drawRect(
            Rect.fromLTWH(
              x * moduleSize,
              y * moduleSize,
              moduleSize,
              moduleSize,
            ),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
