import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Dekorasi TextField gaya neo-brutalist yang dipakai semua form.
/// Sebelumnya blok ini di-copy 11× dengan `fillColor: Colors.white` hardcoded,
/// sehingga teks jadi tidak terbaca saat dark mode. Sekarang ikut palette.
///
/// [context] dibutuhkan untuk resolve palette via [PaletteScope].
InputDecoration neoInputDecoration(
  BuildContext context, {
  String? hintText,
  String? labelText,
  String? prefixText,
  Widget? prefixIcon,
  Widget? suffixIcon,
  EdgeInsetsGeometry contentPadding =
      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  double radius = 16,
}) {
  final c = context.palette;
  OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: BorderSide(color: color, width: width),
      );
  return InputDecoration(
    hintText: hintText,
    labelText: labelText,
    prefixText: prefixText,
    prefixIcon: prefixIcon,
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: c.surfaceContainerLowest,
    contentPadding: contentPadding,
    enabledBorder: border(c.borderBlack, 2),
    focusedBorder: border(c.secondary, AppColors.borderWidth),
    errorBorder: border(c.error, 2),
    focusedErrorBorder: border(c.error, AppColors.borderWidth),
  );
}
