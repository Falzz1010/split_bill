import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_l10n.dart';
import '../../../shared/widgets/neo_button.dart';

/// Satu langkah tutorial: elemen yang disorot (via GlobalKey) + teks penjelasan.
class FeatureTutorialStep {
  final GlobalKey key;
  final String titleKey;
  final String descKey;

  const FeatureTutorialStep({
    required this.key,
    required this.titleKey,
    required this.descKey,
  });
}

/// Tutorial pengenalan yang berjalan LANGSUNG di dalam app: area di sekitar
/// elemen yang dijelaskan di-highlight (lubang tembus), sisanya digelapkan,
/// dengan kartu penjelasan + tombol Selanjutnya / Kembali / Lewati.
class FeatureTutorialOverlay extends StatefulWidget {
  final List<FeatureTutorialStep> steps;
  final VoidCallback onFinish;

  const FeatureTutorialOverlay({
    super.key,
    required this.steps,
    required this.onFinish,
  });

  @override
  State<FeatureTutorialOverlay> createState() => _FeatureTutorialOverlayState();
}

class _FeatureTutorialOverlayState extends State<FeatureTutorialOverlay>
    with SingleTickerProviderStateMixin {
  int _current = 0;
  Rect? _target;

  bool get _isLast => _current == widget.steps.length - 1;

  /// Animasi masuk halus saat overlay pertama kali muncul (dari splash).
  late final AnimationController _enterController;
  late final Animation<double> _enter;

  @override
  void initState() {
    super.initState();
    _enterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _enter = CurvedAnimation(
      parent: _enterController,
      curve: Curves.easeOutCubic,
    );
    // Mulai sedikit terlambat supaya animasi terlihat pas saat transisi
    // splash → app selesai (overlay tidak "muncul tiba-tiba").
    Future.delayed(const Duration(milliseconds: 450), () {
      if (mounted) _enterController.forward();
    });
    _scheduleMeasure();
  }

  @override
  void dispose() {
    _enterController.dispose();
    super.dispose();
  }

  void _next() {
    if (_isLast) {
      widget.onFinish();
      return;
    }
    setState(() => _current++);
    _scheduleMeasure();
  }

  void _back() {
    setState(() => _current--);
    _scheduleMeasure();
  }

  /// Hitung posisi elemen target SETELAH frame selesai di-layout, supaya
  /// aman dipakai di build berikutnya (render box target sudah punya ukuran).
  void _scheduleMeasure() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ctx = widget.steps[_current].key.currentContext;
      if (ctx == null) return;
      final box = ctx.findRenderObject();
      if (box is! RenderBox) return;
      final rect = box.localToGlobal(Offset.zero) & box.size;
      if (rect != _target) setState(() => _target = rect);
    });
  }

  @override
  Widget build(BuildContext context) {
    final step = widget.steps[_current];
    final target = _target;
    final screenSize = MediaQuery.of(context).size;
    final bubbleAbove = target != null && target.center.dy > screenSize.height * 0.55;
    final hole = target?.inflate(16);

    return Positioned.fill(
      // Fade + scale halus saat overlay masuk.
      child: FadeTransition(
        opacity: _enter,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.96, end: 1.0).animate(_enter),
          child: Stack(
            children: [
              // Backdrop gelap dengan lubang tembus di area elemen yang dijelaskan.
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {},
                child: CustomPaint(
                  painter: _HolePainter(hole: hole, borderColor: AppColors.primaryContainer),
                  size: Size.infinite,
                ),
              ),

              // Kartu penjelasan — di atas target bila target di bawah layar, dst.
              if (target != null)
                Positioned(
                  left: 16,
                  right: 16,
                  top: bubbleAbove ? null : (target.bottom + 16),
                  bottom: bubbleAbove ? (screenSize.height - target.top + 16) : null,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.06),
                      end: Offset.zero,
                    ).animate(_enter),
                    child: _buildCard(step),
                  ),
                ),

              // Tombol Lewati (kanan atas) — di bawah status bar saat edge-to-edge
              Positioned(
                top: MediaQuery.of(context).padding.top + 12,
                right: 16,
                child: GestureDetector(
                  onTap: widget.onFinish,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.borderBlack, width: 1.5),
                    ),
                    child: Text(
                      tr('tut_skip'),
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard(FeatureTutorialStep step) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderBlack, width: AppColors.borderWidth),
        boxShadow: [
          BoxShadow(
            color: AppColors.borderBlack,
            offset: AppColors.shadowOffset,
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr(step.titleKey),
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            tr(step.descKey),
            style: TextStyle(fontSize: 13.5, height: 1.5, color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              // Indikator langkah
              ...List.generate(widget.steps.length, (i) {
                final isActive = i == _current;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.only(right: 5),
                  width: isActive ? 22 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.primaryContainer : Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.borderBlack, width: 1.2),
                  ),
                );
              }),
              const Spacer(),
              if (_current > 0) ...[
                NeoButton(
                  onTap: _back,
                  backgroundColor: AppColors.surfaceContainerLow,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Icon(Icons.arrow_back_rounded, size: 18, color: AppColors.onSurface),
                ),
                const SizedBox(width: 8),
              ],
              NeoButton(
                onTap: _next,
                backgroundColor: AppColors.primaryContainer,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isLast ? Icons.check_rounded : Icons.arrow_forward_rounded,
                      size: 18,
                      color: AppColors.onPrimaryContainer,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _isLast ? tr('tut_done') : tr('tut_next'),
                      style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.onPrimaryContainer, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Menggelapkan layar kecuali area lubang (elemen yang di-highlight).
class _HolePainter extends CustomPainter {
  final Rect? hole;
  final Color borderColor;

  _HolePainter({required this.hole, required this.borderColor});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()..addRect(Offset.zero & size);
    if (hole != null && hole!.width > 0 && hole!.height > 0) {
      path.addRRect(RRect.fromRectAndRadius(hole!, const Radius.circular(22)));
      path.fillType = PathFillType.evenOdd;
      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.black.withAlpha(190)
          ..style = PaintingStyle.fill,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(hole!, const Radius.circular(22)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = borderColor,
      );
    } else {
      canvas.drawRect(Offset.zero & size, Paint()..color = Colors.black.withAlpha(190));
    }
  }

  @override
  bool shouldRepaint(_HolePainter oldDelegate) =>
      oldDelegate.hole != hole || oldDelegate.borderColor != borderColor;
}
