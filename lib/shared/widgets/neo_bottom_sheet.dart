import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Chrome bottom sheet neo-brutalist (border 3px di 3 sisi + sudut atas bulat).
///
/// Tinggi sheet dibatasi ke area di atas keyboard + navbar sistem, jadi header
/// dan tombol aksi tetap terlihat dan hanya [child] yang di-scroll oleh
/// pemanggil. Sebelumnya perhitungan ini di-copy di 4 sheet berbeda.
class NeoBottomSheet extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const NeoBottomSheet({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(20, 20, 20, 20),
  });

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final bottomPad = mq.viewInsets.bottom + mq.padding.bottom;
    final maxHeight = (mq.size.height - mq.padding.top - bottomPad)
        .clamp(80.0, double.infinity)
        .toDouble();
    final c = context.palette;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomPad),
      child: Container(
        constraints: BoxConstraints(maxHeight: maxHeight),
        padding: padding,
        decoration: BoxDecoration(
          color: c.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(
            top: BorderSide(color: c.borderBlack, width: 3),
            left: BorderSide(color: c.borderBlack, width: 3),
            right: BorderSide(color: c.borderBlack, width: 3),
          ),
        ),
        child: child,
      ),
    );
  }
}

/// Judul sheet + tombol tutup. Dipakai bersama [NeoBottomSheet].
class NeoSheetHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onClose;

  const NeoSheetHeader({super.key, required this.title, this.onClose});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: context.palette.onSurface),
            onPressed: onClose ?? () => Navigator.pop(context),
          ),
        ],
      );
}
