import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Logo jejak kaki kucing neo-brutalist: paw print di atas kartu kuning
/// berborder hitam. Ukuran disesuaikan [size].
class NeoPawLogo extends StatelessWidget {
  final double size;

  const NeoPawLogo({super.key, this.size = 52});

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final borderW = size >= 80 ? 3.0 : 2.5;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: c.primaryContainer,
        borderRadius: BorderRadius.circular(size * 0.3),
        border: Border.all(color: c.borderBlack, width: borderW),
        boxShadow: [
          BoxShadow(
            color: c.borderBlack,
            offset: Offset(size * 0.055, size * 0.055),
            blurRadius: 0,
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.pets,
          size: size * 0.62,
          color: c.borderBlack,
        ),
      ),
    );
  }
}