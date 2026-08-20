import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class NeoButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final double? width;
  final double? height;

  const NeoButton({
    super.key,
    required this.child,
    required this.onTap,
    this.backgroundColor,
    this.borderColor,
    this.borderRadius = 30.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    this.width,
    this.height,
  });

  @override
  State<NeoButton> createState() => _NeoButtonState();
}

class _NeoButtonState extends State<NeoButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final Color bg = widget.backgroundColor ?? c.primaryContainer;
    final Color border = widget.borderColor ?? c.borderBlack;
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        width: widget.width,
        height: widget.height,
        padding: widget.padding,
        transform: Matrix4.translationValues(
          _isPressed ? 3.0 : 0.0,
          _isPressed ? 3.0 : 0.0,
          0.0,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: Border.all(color: border, width: AppColors.borderWidth),
          boxShadow: _isPressed
              ? []
              : [
                  BoxShadow(
                    color: border,
                    offset: AppColors.shadowOffset,
                    blurRadius: 0,
                  ),
                ],
        ),
        child: Center(
          widthFactor: widget.width == null ? 1.0 : null,
          heightFactor: widget.height == null ? 1.0 : null,
          child: widget.child,
        ),
      ),
    );
  }
}

/// Tombol ikon bulat ber-border tebal yang dipakai di app bar semua layar.
/// [onTap] null → tampil non-aktif (dulu di-copy sebagai Container polos).
class NeoCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? iconColor;
  final double size;
  final double? iconSize;
  final String? tooltip;

  const NeoCircleButton({
    super.key,
    required this.icon,
    this.onTap,
    this.backgroundColor,
    this.iconColor,
    this.size = 40,
    this.iconSize = 20,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final Widget circle = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? c.surfaceContainerLowest,
        shape: BoxShape.circle,
        border: Border.all(color: c.borderBlack, width: 2),
      ),
      child: Icon(icon, size: iconSize, color: iconColor ?? c.onSurface),
    );
    if (onTap == null) {
      return tooltip == null ? circle : Tooltip(message: tooltip!, child: circle);
    }
    // Semantics & target sentuh dari IconButton tetap dipakai agar tombol
    // terbaca screen reader (dulu GestureDetector polos tanpa semantics).
    return IconButton(
      onPressed: onTap,
      padding: EdgeInsets.zero,
      constraints: BoxConstraints.tightFor(width: size, height: size),
      tooltip: tooltip,
      icon: circle,
    );
  }
}
