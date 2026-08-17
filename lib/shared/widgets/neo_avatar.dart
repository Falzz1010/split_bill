import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/models/split_model.dart';

/// Avatar bulat anggota: warna aksen dari hex + inisial nama.
/// Hex rusak/kosong ditangani [AppColors.fromHex], nama kosong tidak lagi
/// membuat `name[0]` melempar RangeError.
class NeoAvatar extends StatelessWidget {
  final Member member;
  final double size;
  final double fontSize;
  final bool bordered;

  const NeoAvatar({
    super.key,
    required this.member,
    this.size = 36,
    this.fontSize = 14,
    this.bordered = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppColors.fromHex(member.accentColorHex);
    final initial = member.name.trim().isEmpty ? '?' : member.name.trim()[0].toUpperCase();
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: bordered ? Border.all(color: AppColors.borderBlack, width: 2) : null,
      ),
      child: Text(
        initial,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: fontSize,
          color: AppColors.onAccent(color),
        ),
      ),
    );
  }
}
