import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/app_l10n.dart';

/// Dialog konfirmasi hapus struk. Mengembalikan true bila user menekan "Hapus".
Future<bool> showDeleteConfirmDialog(BuildContext context, String title) =>
    showConfirmDialog(
      context,
      title: tr('del_confirm_title'),
      message: tr('del_confirm_desc').replaceAll('{title}', title),
      confirmLabel: tr('del_hapus'),
    );

/// Dialog konfirmasi generik untuk aksi destruktif. Mengembalikan true bila
/// user menekan tombol konfirmasi.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
}) async {
  final c = context.palette;
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: c.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: c.borderBlack, width: 2.5),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(tr('del_cancel')),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: c.errorContainer,
            foregroundColor: c.error,
          ),
          onPressed: () => Navigator.pop(context, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}