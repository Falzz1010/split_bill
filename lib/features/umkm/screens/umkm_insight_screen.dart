import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/state/transaksi_umkm_store.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/services/gemini_service.dart';
import '../../../core/services/sales_analytics_service.dart';
import '../../../shared/widgets/neo_card.dart';
import '../../../shared/widgets/neo_button.dart';

class UmkmInsightScreen extends StatefulWidget {
  const UmkmInsightScreen({super.key});

  @override
  State<UmkmInsightScreen> createState() => _UmkmInsightScreenState();
}

class _UmkmInsightScreenState extends State<UmkmInsightScreen> {
  bool _profitLoading = false;
  bool _forecastLoading = false;
  bool _healthLoading = false;
  String? _profitText;
  String? _forecastText;
  ({int score, String analysis})? _healthResult;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    final store = TransaksiUmkmStore.instance;
    if (store.transaksi.isEmpty) return;

    // Load all in parallel
    final results = await Future.wait([
      GeminiService.instance.analyzeMenuProfitability(store.transaksi),
      GeminiService.instance.forecastSales(store.transaksi),
      GeminiService.instance.calculateHealthScore(store.transaksi),
    ]);

    if (!mounted) return;
    setState(() {
      _profitText = results[0] as String?;
      _forecastText = results[1] as String?;
      final health = results[2] as ({int score, String analysis})?;
      if (health != null) _healthResult = health;
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.palette;

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(Icons.insights_rounded, size: 28, color: c.primary),
                  const SizedBox(width: 10),
                  Text(
                    'Insight Bisnis',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Analisis mendalam dari AI Gemini',
                style: TextStyle(fontSize: 13, color: c.onSurfaceVariant),
              ),
              const SizedBox(height: 20),

              // 1. Health Score
              _buildHealthScore(c),
              const SizedBox(height: 16),

              // 2. Menu Profitability
              _buildInsightCard(
                title: 'Profitabilitas Menu',
                icon: Icons.account_balance_wallet_rounded,
                isLoading: _profitLoading,
                text: _profitText,
                onRefresh: () async {
                  setState(() => _profitLoading = true);
                  final result = await GeminiService.instance
                      .analyzeMenuProfitability(TransaksiUmkmStore.instance.transaksi);
                  if (!mounted) return;
                  setState(() {
                    _profitLoading = false;
                    _profitText = result;
                  });
                },
                c: c,
              ),
              const SizedBox(height: 16),

              // 3. Sales Forecast
              _buildInsightCard(
                title: 'Prediksi Penjualan',
                icon: Icons.trending_up_rounded,
                isLoading: _forecastLoading,
                text: _forecastText,
                onRefresh: () async {
                  setState(() => _forecastLoading = true);
                  final result = await GeminiService.instance
                      .forecastSales(TransaksiUmkmStore.instance.transaksi);
                  if (!mounted) return;
                  setState(() {
                    _forecastLoading = false;
                    _forecastText = result;
                  });
                },
                c: c,
              ),
              const SizedBox(height: 16),

              // 4. Cash Flow Projection (Local)
              _buildCashFlowProjection(c),
              const SizedBox(height: 16),

              // Quick stats from store
              _buildQuickStats(c),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCashFlowProjection(PaletteData c) {
    final transaksi = TransaksiUmkmStore.instance.transaksi;
    final projection = SalesAnalyticsService.projectCashFlow(transaksi);
    
    if (projection.isEmpty) {
      return const SizedBox.shrink();
    }

    return NeoCard(
      backgroundColor: c.surfaceContainerLowest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_balance_wallet_rounded, color: c.primary, size: 20),
              const SizedBox(width: 8),
              const Text('Prediksi Kas 7 Hari', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 12),
          ...projection.map((p) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 60,
                  child: Text(p.label, style: TextStyle(fontSize: 12, color: c.onSurfaceVariant)),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: projection.first.projected > 0 
                          ? (p.projected / projection.first.projected).clamp(0.0, 1.0)
                          : 0,
                      backgroundColor: c.outlineVariant,
                      valueColor: AlwaysStoppedAnimation(c.primary),
                      minHeight: 8,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 70,
                  child: Text(
                    formatCurrency(p.projected),
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                    textAlign: TextAlign.right,
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: p.confidence == 'Tinggi' ? c.primaryContainer : c.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(p.confidence, style: TextStyle(fontSize: 8, color: c.onSurfaceVariant)),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildHealthScore(PaletteData c) {
    final score = _healthResult?.score;
    final analysis = _healthResult?.analysis;

    Color scoreColor;
    String label;
    if (score == null) {
      scoreColor = c.outline;
      label = '-';
    } else if (score >= 80) {
      scoreColor = Colors.green;
      label = 'Sehat';
    } else if (score >= 60) {
      scoreColor = Colors.orange;
      label = 'Cukup';
    } else {
      scoreColor = Colors.red;
      label = 'Perlu Perhatian';
    }

    return NeoCard(
      backgroundColor: c.surfaceContainerLowest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.favorite_rounded, color: scoreColor, size: 22),
              const SizedBox(width: 8),
              const Text(
                'Health Score',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
              ),
              const Spacer(),
              if (score != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: scoreColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: scoreColor, width: 2),
                  ),
                  child: Row(
                    children: [
                      Text(
                        '$score',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          color: scoreColor,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        label,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: scoreColor,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (_healthLoading)
            const Center(child: CircularProgressIndicator())
          else if (analysis != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: c.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: c.outlineVariant, width: 1),
              ),
              child: Text(analysis, style: const TextStyle(fontSize: 12, height: 1.5)),
            )
          else
            NeoButton(
              onTap: () async {
                setState(() => _healthLoading = true);
                final result = await GeminiService.instance
                    .calculateHealthScore(TransaksiUmkmStore.instance.transaksi);
                if (!mounted) return;
                setState(() {
                  _healthLoading = false;
                  if (result != null) _healthResult = result;
                });
              },
              width: double.infinity,
              backgroundColor: c.primaryContainer,
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_rounded, size: 16, color: c.onPrimaryContainer),
                  const SizedBox(width: 6),
                  Text(
                    'Hitung Skor',
                    style: TextStyle(fontWeight: FontWeight.w800, color: c.onPrimaryContainer),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInsightCard({
    required String title,
    required IconData icon,
    required bool isLoading,
    required String? text,
    required VoidCallback onRefresh,
    required PaletteData c,
  }) {
    return NeoCard(
      backgroundColor: c.surfaceContainerLowest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: c.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
              ),
              GestureDetector(
                onTap: onRefresh,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: c.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.refresh_rounded, size: 16, color: c.onPrimaryContainer),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (isLoading)
            const Center(child: CircularProgressIndicator())
          else if (text != null && text.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: c.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: c.outlineVariant, width: 1),
              ),
              child: Text(text, style: const TextStyle(fontSize: 12, height: 1.5)),
            )
          else
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Belum ada data',
                  style: TextStyle(color: c.outline),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(PaletteData c) {
    final store = TransaksiUmkmStore.instance;
    final profit = store.menuProfitability(limit: 5);

    if (profit.isEmpty) return const SizedBox.shrink();

    return NeoCard(
      backgroundColor: c.surfaceContainerLowest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.leaderboard_rounded, size: 18, color: c.primary),
              const SizedBox(width: 6),
              const Text(
                'Top Menu by Profit',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...profit.asMap().entries.map((entry) {
            final idx = entry.key;
            final item = entry.value;
            final maxProfit = profit.first.profit;
            final pct = maxProfit > 0 ? item.profit / maxProfit : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '${idx + 1}.',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          color: c.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          item.name,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${item.margin.round()}%',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          color: item.margin >= 50
                              ? Colors.green
                              : item.margin >= 30
                                  ? Colors.orange
                                  : Colors.red,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        formatCurrency(item.profit),
                        style: TextStyle(fontSize: 11, color: c.onSurfaceVariant),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 6,
                      backgroundColor: c.surfaceContainerLow,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        idx == 0 ? c.primary : idx == 1 ? c.secondary : c.outline,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
