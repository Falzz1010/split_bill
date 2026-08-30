import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../core/settings/settings_service.dart';
import '../../core/theme/app_colors.dart';
import '../widgets/neo_paw_logo.dart';

/// Splash screen animasi singkat saat mode switch (Personal ↔ UMKM).
/// Menampilkan logo + nama mode dengan progress bar, lalu callback.
class ModeSwitchSplash extends StatefulWidget {
  final AppMode targetMode;
  final VoidCallback onComplete;

  const ModeSwitchSplash({
    super.key,
    required this.targetMode,
    required this.onComplete,
  });

  @override
  State<ModeSwitchSplash> createState() => _ModeSwitchSplashState();

  /// Show splash overlay lalu panggil [onComplete] selesai.
  static Future<void> show(BuildContext context, AppMode targetMode) {
    final completer = _SplashCompleter();
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => ModeSwitchSplash(
        targetMode: targetMode,
        onComplete: () {
          entry.remove();
          completer._complete();
        },
      ),
    );
    overlay.insert(entry);
    return completer.future;
  }
}

class _SplashCompleter {
  final _controller = StreamController<void>.broadcast();
  Future<void> get future => _controller.stream.first;
  void _complete() {
    _controller.add(null);
    _controller.close();
  }
}

class _ModeSwitchSplashState extends State<ModeSwitchSplash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _logoAnim;
  late final Animation<double> _textAnim;
  late final Animation<double> _barAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _logoAnim = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOutBack),
    );
    _textAnim = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.2, 0.6, curve: Curves.easeOutCubic),
    );
    _barAnim = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.3, 0.85, curve: Curves.easeInOut),
    );
    _fadeAnim = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
    );

    _ctrl.forward().then((_) {
      if (mounted) widget.onComplete();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final isUmkm = widget.targetMode == AppMode.umkm;
    final appName = isUmkm ? 'Neobill Kasir' : 'Neobill';
    final tagline = isUmkm
        ? 'AI Smart Bill & Business Assistant'
        : 'Hitung Cepat, Split Adil ⚡';
    final accentColor = isUmkm ? c.secondaryContainer : c.primaryContainer;
    final accentOn = isUmkm ? c.onSecondaryContainer : c.onPrimaryContainer;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final fadeOut = (_fadeAnim.value).clamp(0.0, 1.0);
        final opacity = _ctrl.value < 0.7 ? 1.0 : (1.0 - fadeOut);

        return IgnorePointer(
          ignoring: _ctrl.value >= 0.9,
          child: Opacity(
            opacity: opacity,
            child: Container(
              color: c.background,
              width: double.infinity,
              height: double.infinity,
              child: SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(flex: 3),

                    // Logo pop in
                    Transform.scale(
                      scale: 0.3 + _logoAnim.value * 0.7,
                      child: Transform.rotate(
                        angle: (1 - _logoAnim.value) * -0.08 * math.pi,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: accentColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: c.borderBlack,
                              width: AppColors.borderWidth,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: c.borderBlack,
                                offset: Offset(3, 3),
                              ),
                            ],
                          ),
                          child: NeoPawLogo(size: 100),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // App name
                    Opacity(
                      opacity: _textAnim.value.clamp(0, 1),
                      child: Transform.translate(
                        offset: Offset(0, (1 - _textAnim.value) * 20),
                        child: Text(
                          appName,
                          style: Theme.of(context)
                              .textTheme
                              .headlineLarge
                              ?.copyWith(
                                fontSize: 30,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Tagline badge
                    Opacity(
                      opacity: _textAnim.value.clamp(0, 1),
                      child: Transform.translate(
                        offset: Offset(0, (1 - _textAnim.value) * 16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: accentColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: c.borderBlack,
                              width: 2,
                            ),
                          ),
                          child: Text(
                            tagline,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: accentOn,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const Spacer(flex: 3),

                    // Progress bar
                    Opacity(
                      opacity: _barAnim.value.clamp(0, 1),
                      child: Column(
                        children: [
                          Container(
                            width: 200,
                            height: 14,
                            decoration: BoxDecoration(
                              color: c.surfaceContainerLowest,
                              border: Border.all(
                                color: c.borderBlack,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: c.borderBlack,
                                  offset: Offset(2, 2),
                                ),
                              ],
                            ),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: FractionallySizedBox(
                                widthFactor: _barAnim.value.clamp(0.0, 1.0),
                                heightFactor: 1,
                                child: Container(color: accentColor),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Beralih mode...',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: c.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
