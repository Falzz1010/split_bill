import 'package:flutter/material.dart';
import '../../../core/utils/app_l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/state/transaksi_umkm_store.dart';
import '../../../core/state/split_store.dart';
import '../../../core/services/inventory_service.dart';
import '../../../core/services/gemini_service.dart';
import '../../../shared/widgets/neo_card.dart';

class DemoModeScreen extends StatefulWidget {
  final void Function(int tabIndex)? onSelectTab;

  const DemoModeScreen({super.key, this.onSelectTab});

  @override
  State<DemoModeScreen> createState() => _DemoModeScreenState();
}

class _DemoModeScreenState extends State<DemoModeScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  int _currentStep = 0;
  bool _isPlaying = false;
  bool _isPaused = false;

  final List<_DemoStep> _steps = [
    _DemoStep(
      icon: Icons.receipt_long_rounded,
      title: 'Riwayat Transaksi',
      subtitle: '12 transaksi UMKM sudah dimuat',
      color: const Color(0xFF4CAF50),
      tabIndex: 0,
    ),
    _DemoStep(
      icon: Icons.qr_code_scanner_rounded,
      title: 'OCR Scanner',
      subtitle: '3 mode: Offline ML Kit, AI Gemini, Auto-fallback',
      color: const Color(0xFF2196F3),
      tabIndex: 2,
    ),
    _DemoStep(
      icon: Icons.category_rounded,
      title: 'Kategorisasi Otomatis',
      subtitle: 'Autocomplete dari transaksi sebelumnya',
      color: const Color(0xFF9C27B0),
      tabIndex: 0,
    ),
    _DemoStep(
      icon: Icons.inventory_2_rounded,
      title: 'Inventaris',
      subtitle: '8 item, 3 stok rendah, 1 kritis',
      color: const Color(0xFFFF9800),
      tabIndex: 4,
    ),
    _DemoStep(
      icon: Icons.show_chart_rounded,
      title: 'Sales Analytics',
      subtitle: 'SMA, EMA, Growth, Anomaly, Trend, ABC',
      color: const Color(0xFF00BCD4),
      tabIndex: 1,
    ),
    _DemoStep(
      icon: Icons.auto_awesome_rounded,
      title: 'AI Insight',
      subtitle: '9 rekomendasi cerdas otomatis',
      color: const Color(0xFFE91E63),
      tabIndex: 5,
    ),
    _DemoStep(
      icon: Icons.account_balance_wallet_rounded,
      title: 'Cash Flow Projection',
      subtitle: 'Prediksi 7 hari dengan confidence',
      color: const Color(0xFF795548),
      tabIndex: 3,
    ),
    _DemoStep(
      icon: Icons.picture_as_pdf_rounded,
      title: 'PDF Export',
      subtitle: 'Laporan harian & semua transaksi',
      color: const Color(0xFFF44336),
      tabIndex: 3,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _fadeController.forward();
    // Muat data demo setelah frame pertama — memanggil loadDemo() langsung
    // di initState memicu notifyListeners() saat build (assertion
    // 'setState() called during build').
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadDemoData());
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadDemoData() async {
    GeminiService.instance.demoMode = true;
    try {
      await TransaksiUmkmStore.instance.loadDemo();
      await InventoryService.instance.loadDemo();
      SplitStore.instance.loadDemo();
    } catch (e) {
      debugPrint('Demo data load error: $e');
    }
  }

  void _navigateToStep(int index) {
    final tabIndex = _steps[index].tabIndex;
    widget.onSelectTab?.call(tabIndex);
    if (mounted) Navigator.of(context).pop();
  }

  void _startDemo() {
    setState(() {
      _isPlaying = true;
      _currentStep = 0;
    });
    _playNextStep();
  }

  void _playNextStep() {
    if (!_isPlaying || _isPaused) return;
    if (_currentStep >= _steps.length) {
      setState(() => _isPlaying = false);
      return;
    }

    _fadeController.reset();
    _fadeController.forward();

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && _isPlaying && !_isPaused) {
        final nextStep = _currentStep;
        setState(() => _currentStep++);
        _navigateToStep(nextStep);
      }
    });
  }

  void _togglePause() {
    setState(() => _isPaused = !_isPaused);
    if (!_isPaused && _isPlaying) {
      _playNextStep();
    }
  }

  void _resetDemo() {
    setState(() {
      _isPlaying = false;
      _isPaused = false;
      _currentStep = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    
    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Icon(Icons.arrow_back_rounded, color: c.onSurface, size: 24),
                  ),
                  const SizedBox(width: 10),
                  Icon(Icons.play_circle_rounded, color: c.primary, size: 28),
                  const SizedBox(width: 8),
                  Text(
                    tr('demo_mode'),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  if (_isPlaying)
                    IconButton(
                      onPressed: _togglePause,
                      icon: Icon(
                        _isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                        color: c.primary,
                      ),
                    ),
                  if (_isPlaying)
                    IconButton(
                      onPressed: _resetDemo,
                      icon: Icon(Icons.stop_rounded, color: c.error),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Auto-play semua fitur untuk presentasi hackathon',
                style: TextStyle(fontSize: 12, color: c.onSurfaceVariant),
              ),
            ),
            const SizedBox(height: 16),

            // Progress indicator
            if (_isPlaying)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _currentStep / _steps.length,
                        backgroundColor: c.outlineVariant,
                        valueColor: AlwaysStoppedAnimation(c.primary),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Step ${_currentStep + 1} / ${_steps.length}',
                      style: TextStyle(fontSize: 10, color: c.onSurfaceVariant),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            // Steps list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _steps.length,
                itemBuilder: (context, index) {
                  final step = _steps[index];
                  final isActive = _isPlaying && index == _currentStep;
                  final isDone = _isPlaying && index < _currentStep;

                  return AnimatedBuilder(
                    animation: _fadeAnimation,
                    builder: (context, child) {
                      return GestureDetector(
                        onTap: () => _navigateToStep(index),
                        child: Opacity(
                        opacity: isActive ? _fadeAnimation.value : 1.0,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: NeoCard(
                            backgroundColor: isActive
                                ? step.color.withValues(alpha: 0.1)
                                : c.surfaceContainerLowest,
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: isDone
                                        ? Colors.green
                                        : isActive
                                            ? step.color
                                            : c.outlineVariant,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Center(
                                    child: isDone
                                        ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
                                        : Icon(step.icon, color: Colors.white, size: 20),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        step.title,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                          color: isActive ? step.color : c.onSurface,
                                        ),
                                      ),
                                      Text(
                                        step.subtitle,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: c.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isActive)
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: step.color,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      );
                    },
                  );
                },
              ),
            ),

            // Start button
            if (!_isPlaying)
              Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _startDemo,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: c.primary,
                      foregroundColor: c.onPrimaryContainer,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.play_arrow_rounded, size: 24),
                        SizedBox(width: 8),
                        Text(
                          'Mulai Demo',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Stats summary
            if (!_isPlaying)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: NeoCard(
                  backgroundColor: c.surfaceContainerLowest,
                  child: Column(
                    children: [
                      Text(
                        'Data Demo Siap',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: c.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildMiniStat(c, '12', 'Transaksi'),
                          _buildMiniStat(c, '8', 'Item Stok'),
                          _buildMiniStat(c, '9', 'Rekomendasi'),
                          _buildMiniStat(c, '7H', 'Prediksi'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(PaletteData c, String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: c.primary,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: c.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _DemoStep {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final int tabIndex;

  const _DemoStep({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.tabIndex,
  });
}
