import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class NeoSearchBar extends StatelessWidget {
  final String hintText;
  final ValueChanged<String>? onChanged;
  final TextEditingController? controller;

  const NeoSearchBar({
    super.key,
    this.hintText = 'Cari struk atau riwayat...',
    this.onChanged,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: c.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: c.borderBlack, width: AppColors.borderWidth),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: c.onSurface,
              fontWeight: FontWeight.w600,
            ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: c.outline,
              ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: c.onSurface,
            size: 20,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }
}
