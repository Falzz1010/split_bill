import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../../core/settings/settings_service.dart';
import '../../../core/utils/app_l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../main_navigation.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  late final Animation<double> _logo;
  late final Animation<double> _logoRotate;
  late final Animation<double> _title;
  late final Animation<double> _tagline;
  late final Animation<double> _loading;
  late final Animation<double> _footer;
  late final Animation<double> _split;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 4200));

    _logo = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.25, curve: Curves.easeOutBack),
    );
    _logoRotate = Tween<double>(begin: -0.08, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.3, curve: Curves.easeOutCubic)),
    );
    _title = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.25, 0.5, curve: Curves.easeOutCubic),
    );
    _tagline = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.45, 0.65, curve: Curves.easeOutCubic),
    );
    _loading = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.55, 0.8, curve: Curves.easeOutCubic),
    );
    _footer = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.75, 1.0, curve: Curves.easeOutCubic),
    );
    // Barcode kotak: penanda sudut muncul dulu, modul data menyala
    // berurutan, lalu garis scan menyapu sampai splash selesai.
    _split = CurvedAnimation(parent: _controller, curve: const Interval(0.1, 1.0, curve: Curves.easeInOut));

    _controller.forward().then((_) {
      if (!mounted) return;
      _navigateToMain();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _navigateToMain() {
    final showTutorial = SettingsService.instance.tutorialNeeded;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            MainNavigation(showFeatureTutorial: showTutorial),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curvedAnimation = CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOutCubic,
          );
          return FadeTransition(
            opacity: curvedAnimation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.95, end: 1.0).animate(curvedAnimation),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 1000),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28.0),
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                // Barcode kotak: penanda sudut (0–45%), modul data (45–100%),
                // lalu garis scan menyapu turun-naik 6 siklus.
                final bars = (_split.value * 2.2).clamp(0.0, 1.0);
                final scanT = ((_split.value - 0.45) / 0.55).clamp(0.0, 1.0);
                final scanCycle = (scanT * 6) % 1.0;
                final scan = scanCycle < 0.5 ? scanCycle * 2 : (1 - scanCycle) * 2;

                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(),

                    // Logo neo-brutalist: pop + rotasi (RepaintBoundary agar
                    // transform tak memicu repaint elemen di sekitarnya).
                    RepaintBoundary(
                      child: Transform.translate(
                        offset: Offset(0, (1 - _logo.value) * 30),
                      child: Opacity(
                        opacity: _logo.value.clamp(0, 1),
                        child: Transform.rotate(
                          angle: _logoRotate.value * math.pi,
                          child: Transform.scale(
                            scale: 0.3 + _logo.value * 0.7,
                            child: Container(
                              width: 112,
                              height: 112,
                              decoration: BoxDecoration(
                                color: AppColors.primaryContainer,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.borderBlack, width: AppColors.borderWidth),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.borderBlack,
                                    offset: Offset(4, 4),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.receipt_long_rounded,
                                  size: 52,
                                  color: AppColors.borderBlack,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    ),
                    const SizedBox(height: 26),

                    // Kartu barcode kotak: penanda sudut + modul data menyala
                    // berurutan + garis scan — identitas scan struk yang jelas.
                    RepaintBoundary(
                      child: Opacity(
                        opacity: _logo.value.clamp(0, 1),
                        child: Transform.translate(
                          offset: Offset(0, (1 - _logo.value) * 24),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerLowest,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: AppColors.borderBlack, width: AppColors.borderWidth),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.borderBlack,
                                  offset: Offset(3.5, 3.5),
                                ),
                              ],
                            ),
                            child: SizedBox(
                              width: 148,
                              height: 148,
                              child: CustomPaint(
                                painter: QrPainter(bars: bars, scan: scan),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Judul app: fade + slide up.
                    Opacity(
                      opacity: _title.value.clamp(0, 1),
                      child: Transform.translate(
                        offset: Offset(0, (1 - _title.value) * 24),
                        child: Text(
                          'FairSplit',
                          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                fontSize: 34,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Tagline: fade + slide up menyusul judul.
                    Opacity(
                      opacity: _tagline.value.clamp(0, 1),
                      child: Transform.translate(
                        offset: Offset(0, (1 - _tagline.value) * 18),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.secondaryContainer,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.borderBlack, width: 2),
                          ),
                          child: Text(
                            tr('splash_tagline'),
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: AppColors.onAccent(AppColors.secondaryContainer),
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ),
                      ),
                    ),

                    const Spacer(),

                    // Progress bar neo-brutalist: mengisi mengikuti splash.
                    Opacity(
                      opacity: _loading.value.clamp(0, 1),
                      child: Column(
                        children: [
                          Container(
                            width: 230,
                            height: 18,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerLowest,
                              border: Border.all(color: AppColors.borderBlack, width: 2.5),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.borderBlack,
                                  offset: Offset(3, 3),
                                ),
                              ],
                            ),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: FractionallySizedBox(
                                widthFactor: ((_controller.value - 0.55) / 0.45).clamp(0.0, 1.0),
                                heightFactor: 1,
                                child: Container(color: AppColors.primaryContainer),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            tr('splash_loading'),
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Footer versi.
                    Opacity(
                      opacity: _footer.value.clamp(0, 1),
                      child: Text(
                        'Versi 1.0.0 • Neo-Brutalist Edition',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Barcode kotak (QR-style): tiga penanda sudut, modul data menyala
/// berurutan, lalu garis scan menyapu — senada dengan fitur scan struk.
class QrPainter extends CustomPainter {
  final double bars;
  final double scan;

  const QrPainter({required this.bars, required this.scan});

  static const int grid = 11;

  bool _isFinder(int r, int c) {
    if (r < 3 && c < 3) return true;
    if (r < 3 && c >= grid - 3) return true;
    if (r >= grid - 3 && c < 3) return true;
    return false;
  }

  /// Pola modul data pseudo-random tapi deterministik.
  bool _isDataCell(int r, int c) => (r * 7 + c * 5) % 3 != 0;

  @override
  void paint(Canvas canvas, Size size) {
    final black = Paint()..color = AppColors.borderBlack;
    final card = Paint()..color = AppColors.surfaceContainerLowest;
    final m = size.width / grid;
    final ox = (size.width - m * grid) / 2;
    final oy = (size.height - m * grid) / 2;

    void module(int r, int c, {bool fill = true}) {
      final rect = Rect.fromLTWH(ox + c * m + 0.5, oy + r * m + 0.5, m - 1, m - 1);
      canvas.drawRect(rect, fill ? black : card);
    }

    // Penanda sudut muncul satu per satu (0–50% dari bars).
    final finderProgress = (bars / 0.5).clamp(0.0, 1.0);
    const finderSpots = [(0, 0), (0, grid - 3), (grid - 3, 0)];
    final finders = (finderProgress * 3).floor();
    for (var i = 0; i < finders; i++) {
      final (fr, fc) = finderSpots[i];
      // Bingkai 3×3 hitam + cincin card + inti 1×1.
      canvas.drawRect(Rect.fromLTWH(ox + fc * m, oy + fr * m, 3 * m, 3 * m), black);
      canvas.drawRect(Rect.fromLTWH(ox + fc * m + 0.9 * m, oy + fr * m + 0.9 * m, 1.2 * m, 1.2 * m), card);
      module(fr + 1, fc + 1);
    }

    // Modul data menyala berurutan (50–100% dari bars).
    final dataProgress = ((bars - 0.5) / 0.5).clamp(0.0, 1.0);
    final dataCells = <(int, int)>[];
    for (var r = 0; r < grid; r++) {
      for (var c = 0; c < grid; c++) {
        if (!_isFinder(r, c) && _isDataCell(r, c)) dataCells.add((r, c));
      }
    }
    final shown = (dataCells.length * dataProgress).floor();
    for (var i = 0; i < shown; i++) {
      final (r, c) = dataCells[i];
      module(r, c);
    }

    // Garis scan kuning menyapu vertikal saat barcode sudah penuh.
    if (bars >= 1.0) {
      final scanY = oy + scan * (m * grid);
      final glow = Paint()
        ..color = AppColors.primary.withAlpha(60)
        ..strokeWidth = 9;
      final line = Paint()
        ..color = AppColors.primary
        ..strokeWidth = 2.5;
      canvas.drawLine(Offset(ox, scanY), Offset(ox + m * grid, scanY), glow);
      canvas.drawLine(Offset(ox, scanY), Offset(ox + m * grid, scanY), line);
    }
  }

  @override
  bool shouldRepaint(QrPainter oldDelegate) =>
      oldDelegate.bars != bars || oldDelegate.scan != scan;
}