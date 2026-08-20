import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Snackbar seragam. Dulu 14 pemanggil menulis ulang SnackBar + warna teks,
/// dan beberapa lupa `AppColors.background` sehingga teks nyaris tak terbaca.
void showNeoSnack(
  BuildContext context,
  String message, {
  bool isError = false,
  Duration duration = const Duration(seconds: 2),
}) {
  final c = context.palette;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message, style: TextStyle(color: c.background)),
      backgroundColor: isError ? c.error : c.onSurface,
      duration: duration,
    ),
  );
}
