import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/app_l10n.dart';

/// Dialog konfirmasi hapus struk. Mengembalikan true bila user menekan "Hapus".
Future<bool> showDeleteConfirmDialog(BuildContext context, String title) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: AppColors.borderBlack, width: 2.5),
      ),
      title: Text(
        tr('del_confirm_title'),
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      content: Text(
        tr('del_confirm_desc').replaceAll('{title}', title),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(tr('del_cancel')),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.errorContainer,
            foregroundColor: AppColors.error,
          ),
          onPressed: () => Navigator.pop(context, true),
          child: Text(tr('del_hapus')),
        ),
      ],
    ),
  );
  return result ?? false;
}