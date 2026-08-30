import 'package:flutter/material.dart';
import '../../../core/utils/app_l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/transaksi_umkm.dart';
import '../../../core/state/transaksi_umkm_store.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/services/gemini_service.dart';
import '../../../core/services/sales_analytics_service.dart';
import '../../../core/services/inventory_service.dart';
import '../../../core/services/ai_insight_service.dart';
import '../../../shared/widgets/neo_card.dart';
import '../../../shared/widgets/neo_button.dart';
import '../widgets/revenue_chart.dart';

class UmkmDashboardScreen extends StatefulWidget {
  final VoidCallback onOpenScanner;
  final VoidCallback? onTestScan;

  const UmkmDashboardScreen({
    super.key,
    required this.onOpenScanner,
    this.onTestScan,
  });

  @override
  State<UmkmDashboardScreen> createState() => _UmkmDashboardScreenState();
}

class _UmkmDashboardScreenState extends State<UmkmDashboardScreen> {
  bool _aiLoading = false;
  BusinessInsights? _aiInsights;
  String? _aiNarrative;
  String? _morningBriefing;
  bool _briefingLoaded = false;

  // AI Feature states
  String? _smartPricingResult;
  bool _smartPricingLoading = false;
  String? _costOptResult;
  bool _costOptLoading = false;
  String? _competitorResult;
  bool _competitorLoading = false;
  String? _marketTrendResult;
  bool _marketTrendLoading = false;
  String? _growthTipsResult;
  bool _growthTipsLoading = false;
  String? _supplierResult;
  bool _supplierLoading = false;

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 11) return tr('dash_greeting_morning');
    if (hour >= 11 && hour < 18) return tr('dash_greeting_afternoon');
    return tr('dash_greeting_evening');
  }

  @override
  void initState() {
    super.initState();
    _loadMorningBriefing();
  }

  Future<void> _loadMorningBriefing() async {
    if (_briefingLoaded) return;
    final store = TransaksiUmkmStore.instance;
    if (store.transaksi.isEmpty) return;
    final result = await GeminiService.instance.generateMorningBriefing(store.transaksi);
    if (!mounted) return;
    setState(() {
      _briefingLoaded = true;
      _morningBriefing = result;
    });
  }

  Future<void> _analyzeWithAi() async {
    setState(() => _aiLoading = true);
    final store = TransaksiUmkmStore.instance;
    final ai = await GeminiService.instance.generateUmkmInsights(store.transaksi);
    if (!mounted) return;
    if (ai != null) {
      setState(() {
        _aiLoading = false;
        _aiInsights = ai;
      });
    } else {
      // Fallback to local
      final top = store.topItems(limit: 5);
      final total = store.monthRevenue;
      final count = store.todayCount;
      final narrative = 'Hari ini: $count transaksi, omzet Rp ${total.toStringAsFixed(0)}. Item terlaris: ${top.isNotEmpty ? top.first.name : "-"}.';
      setState(() {
        _aiLoading = false;
        _aiNarrative = narrative;
      });
    }
  }

  static const _emptyDataMsg = 'Belum ada data transaksi. Lakukan scan struk terlebih dahulu agar AI bisa menganalisis bisnismu.';

  Future<void> _loadSmartPricing() async {
    setState(() => _smartPricingLoading = true);
    final store = TransaksiUmkmStore.instance;
    if (store.transaksi.isEmpty) {
      setState(() { _smartPricingLoading = false; _smartPricingResult = _emptyDataMsg; });
      return;
    }
    final result = await GeminiService.instance.analyzeSmartPricing(store.transaksi);
    if (!mounted) return;
    setState(() {
      _smartPricingLoading = false;
      _smartPricingResult = result ?? 'Tidak ada data dengan harga modal. Pastikan item punya harga modal.';
    });
  }

  Future<void> _loadCostOpt() async {
    setState(() => _costOptLoading = true);
    final store = TransaksiUmkmStore.instance;
    if (store.transaksi.isEmpty) {
      setState(() { _costOptLoading = false; _costOptResult = _emptyDataMsg; });
      return;
    }
    final result = await GeminiService.instance.optimizeCosts(store.transaksi);
    if (!mounted) return;
    setState(() {
      _costOptLoading = false;
      _costOptResult = result ?? 'Tidak ada data biaya dari 7 hari terakhir.';
    });
  }

  Future<void> _loadCompetitor() async {
    setState(() => _competitorLoading = true);
    final store = TransaksiUmkmStore.instance;
    if (store.transaksi.isEmpty) {
      setState(() { _competitorLoading = false; _competitorResult = _emptyDataMsg; });
      return;
    }
    final result = await GeminiService.instance.analyzeCompetitors(store.transaksi);
    if (!mounted) return;
    setState(() {
      _competitorLoading = false;
      _competitorResult = result ?? 'Tidak ada data harga menu untuk dianalisis.';
    });
  }

  Future<void> _loadMarketTrend() async {
    setState(() => _marketTrendLoading = true);
    final store = TransaksiUmkmStore.instance;
    if (store.transaksi.isEmpty) {
      setState(() { _marketTrendLoading = false; _marketTrendResult = _emptyDataMsg; });
      return;
    }
    final result = await GeminiService.instance.analyzeMarketTrends(store.transaksi);
    if (!mounted) return;
    setState(() {
      _marketTrendLoading = false;
      _marketTrendResult = result ?? 'Tidak ada data tren dari 14 hari terakhir.';
    });
  }

  Future<void> _loadGrowthTips() async {
    setState(() => _growthTipsLoading = true);
    final store = TransaksiUmkmStore.instance;
    if (store.transaksi.isEmpty) {
      setState(() { _growthTipsLoading = false; _growthTipsResult = _emptyDataMsg; });
      return;
    }
    final result = await GeminiService.instance.suggestGrowthTips(store.transaksi);
    if (!mounted) return;
    setState(() {
      _growthTipsLoading = false;
      _growthTipsResult = result ?? 'Tidak ada data pertumbuhan bulan ini.';
    });
  }

  Future<void> _loadSupplier() async {
    setState(() => _supplierLoading = true);
    final store = TransaksiUmkmStore.instance;
    if (store.transaksi.isEmpty) {
      setState(() { _supplierLoading = false; _supplierResult = _emptyDataMsg; });
      return;
    }
    final result = await GeminiService.instance.recommendSuppliers(store.transaksi);
    if (!mounted) return;
    setState(() {
      _supplierLoading = false;
      _supplierResult = result ?? 'Tidak ada data biaya bahan untuk rekomendasi supplier.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final store = TransaksiUmkmStore.instance;

    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final todayRevenue = store.todayRevenue;
        final monthRevenue = store.monthRevenue;
        final todayPpn = todayRevenue * 0.11;
        final monthPpn = monthRevenue * 0.11;
        final todayCount = store.todayCount;
        final recent = store.transaksi.take(5).toList();

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
                      Icon(Icons.store_rounded, size: 32, color: c.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tr('dash_title'),
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(fontSize: 24, fontWeight: FontWeight.w800),
                            ),
                            Text(
                              '${_greeting()} ${tr("umkm_owner")}',
                              style: TextStyle(fontSize: 13, color: c.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Morning Briefing
                  if (_morningBriefing != null)
                    NeoCard(
                      backgroundColor: c.primaryContainer.withOpacity(0.3),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.wb_sunny_rounded, color: c.primary, size: 20),
                              const SizedBox(width: 6),
                              const Text(
                                'Briefing Pagi',
                                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _morningBriefing!,
                            style: const TextStyle(fontSize: 12, height: 1.5),
                          ),
                        ],
                      ),
                    ),
                  if (_morningBriefing != null) const SizedBox(height: 16),

                  // Quick Actions
                  Row(
                    children: [
                      Expanded(
                        child: NeoButton(
                          onTap: widget.onOpenScanner,
                          backgroundColor: c.primaryContainer,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.document_scanner_rounded, color: c.onPrimaryContainer),
                              const SizedBox(width: 8),
                              Text(
                                tr('umkm_scan_now'),
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                  color: c.onPrimaryContainer,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (widget.onTestScan != null) ...[
                        const SizedBox(width: 10),
                        NeoButton(
                          onTap: widget.onTestScan!,
                          backgroundColor: c.secondaryContainer,
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.science_rounded, size: 20, color: c.onSecondaryContainer),
                              const SizedBox(width: 6),
                              Text(
                                'Test',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                  color: c.onSecondaryContainer,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Stats Cards
                  Text(tr('umkm_today'),
                      style: Theme.of(context)
                          .textTheme
                          .labelLarge
                          ?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          icon: Icons.attach_money_rounded,
                          label: tr('umkm_revenue'),
                          value: formatCurrency(todayRevenue),
                          color: c.primaryContainer,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.receipt_long_rounded,
                          label: tr('umkm_trans'),
                          value: '$todayCount',
                          color: c.secondaryContainer,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          icon: Icons.account_balance_rounded,
                          label: 'PPN ${tr("umkm_today")}',
                          value: formatCurrency(todayPpn),
                          color: c.errorContainer,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.calendar_month_rounded,
                          label: '${tr("umkm_revenue")} ${tr("umkm_month")}',
                          value: formatCurrency(monthRevenue),
                          color: c.secondaryContainer,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _StatCard(
                    icon: Icons.account_balance_wallet_rounded,
                    label: 'PPN ${tr("umkm_month")} = ${formatCurrency(monthPpn)}',
                    value: formatCurrency(monthPpn),
                    color: c.primaryContainer,
                    fullWidth: true,
                  ),
                  const SizedBox(height: 24),

                  // Revenue Chart
                  Text('Grafik Omzet 7 Hari', style: Theme.of(context).textTheme.headlineLarge),
                  const SizedBox(height: 8),
                  NeoCard(
                    backgroundColor: c.surfaceContainerLowest,
                    child: RevenueChart(transactions: store.transaksi, days: 7),
                  ),
                  const SizedBox(height: 24),

                  // Local Business Analytics
                  Text('Analytics', style: Theme.of(context).textTheme.headlineLarge),
                  const SizedBox(height: 8),
                  _buildAnalyticsCards(c, store.transaksi),
                  const SizedBox(height: 24),

                  // AI Insight
                  NeoCard(
                    backgroundColor: c.surfaceContainerLowest,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.auto_awesome_rounded, color: c.primary, size: 20),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                tr('dash_ai_title'),
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                              ),
                            ),
                            if (_aiInsights?.fromAI == true)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: c.secondaryContainer,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: c.borderBlack, width: 1.5),
                                ),
                                child: Text(tr('dash_ai_gemini_badge'),
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800)),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: c.surfaceContainerLow,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: c.outlineVariant, width: 1),
                                ),
                                child: Text(tr('dash_ai_local_badge'),
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: c.outline)),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(tr('dash_ai_subtitle'),
                            style: TextStyle(fontSize: 12, color: c.onSurfaceVariant)),
                        const SizedBox(height: 12),

                        Row(
                          children: [
                            _MiniStat(label: tr('dash_ai_top_items'), value: '${store.topItems(limit: 5).length}'),
                            const SizedBox(width: 16),
                            _MiniStat(
                                label: tr('dash_ai_top_category'),
                                value: store.categoryBreakdown().isNotEmpty
                                    ? store.categoryBreakdown().first.category
                                    : '-'),
                          ],
                        ),
                        const SizedBox(height: 10),

                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: c.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: c.outlineVariant, width: 1),
                          ),
                          child: Text(
                            _aiInsights?.narrative ?? _aiNarrative ?? tr('dash_ai_empty'),
                            style: const TextStyle(fontSize: 12, height: 1.5),
                          ),
                        ),
                        const SizedBox(height: 12),

                        NeoButton(
                          onTap: _aiLoading ? () {} : _analyzeWithAi,
                          width: double.infinity,
                          backgroundColor: c.primaryContainer,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: _aiLoading
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: c.onPrimaryContainer),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(tr('dash_ai_analyzing'),
                                        style: TextStyle(fontWeight: FontWeight.w800, color: c.onPrimaryContainer)),
                                  ],
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.auto_awesome, size: 16, color: c.onPrimaryContainer),
                                    const SizedBox(width: 6),
                                    Text(tr('dash_ai_analyze'),
                                        style: TextStyle(fontWeight: FontWeight.w800, color: c.onPrimaryContainer)),
                                  ],
                                ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Local AI Insight
                  Text('Rekomendasi Cerdas', style: Theme.of(context).textTheme.headlineLarge),
                  const SizedBox(height: 8),
                  _buildLocalInsights(c, store.transaksi),
                  const SizedBox(height: 24),

                  // AI Tools Section
                  Text('AI Bisnis',
                      style: Theme.of(context)
                          .textTheme
                          .labelLarge
                          ?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  _AiFeatureCard(
                    icon: Icons.price_change_rounded,
                    title: 'Smart Pricing',
                    subtitle: 'Saran harga jual berdasarkan modal',
                    loading: _smartPricingLoading,
                    result: _smartPricingResult,
                    onTap: _loadSmartPricing,
                    color: c.primaryContainer,
                  ),
                  const SizedBox(height: 8),
                  _AiFeatureCard(
                    icon: Icons.savings_rounded,
                    title: 'Cost Optimization',
                    subtitle: 'Tips kurangi waste & optimasi biaya',
                    loading: _costOptLoading,
                    result: _costOptResult,
                    onTap: _loadCostOpt,
                    color: c.secondaryContainer,
                  ),
                  const SizedBox(height: 8),
                  _AiFeatureCard(
                    icon: Icons.storefront_rounded,
                    title: 'Analisis Kompetitor',
                    subtitle: 'Bandingkan harga dengan pasar lokal',
                    loading: _competitorLoading,
                    result: _competitorResult,
                    onTap: _loadCompetitor,
                    color: c.secondaryContainer.withOpacity(0.7),
                  ),
                  const SizedBox(height: 8),
                  _AiFeatureCard(
                    icon: Icons.trending_up_rounded,
                    title: 'Tren Pasar',
                    subtitle: 'Apa yang lagi laris di sekitar',
                    loading: _marketTrendLoading,
                    result: _marketTrendResult,
                    onTap: _loadMarketTrend,
                    color: c.primaryContainer,
                  ),
                  const SizedBox(height: 8),
                  _AiFeatureCard(
                    icon: Icons.rocket_launch_rounded,
                    title: 'Tips Berkembang',
                    subtitle: 'Expand, digital marketing, marketplace',
                    loading: _growthTipsLoading,
                    result: _growthTipsResult,
                    onTap: _loadGrowthTips,
                    color: c.secondaryContainer,
                  ),
                  const SizedBox(height: 8),
                  _AiFeatureCard(
                    icon: Icons.local_shipping_rounded,
                    title: 'Koneksi Supplier',
                    subtitle: 'Rekomendasi supplier terdekat & murah',
                    loading: _supplierLoading,
                    result: _supplierResult,
                    onTap: _loadSupplier,
                    color: c.secondaryContainer.withOpacity(0.7),
                  ),
                  const SizedBox(height: 24),

                  // Recent Transactions
                  Text(tr('umkm_recent'),
                      style: Theme.of(context)
                          .textTheme
                          .labelLarge
                          ?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  if (recent.isEmpty)
                    NeoCard(
                      backgroundColor: c.surfaceContainerLowest,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(tr('umkm_no_trans'), style: TextStyle(color: c.outline)),
                        ),
                      ),
                    )
                  else
                    ...recent.map((t) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: NeoCard(
                            backgroundColor: c.surfaceContainerLowest,
                            child: Row(
                              children: [
                                Container(
                                  width: 4,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(t.merchantName.isNotEmpty ? t.merchantName : 'Transaksi',
                                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                                      Text(
                                        '${t.items.length} items - ${paymentMethodName(t.paymentMethod)}',
                                        style: TextStyle(fontSize: 11, color: c.onSurfaceVariant),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  formatCurrency(t.totalAmount),
                                  style: TextStyle(fontWeight: FontWeight.w800, color: c.primary, fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        )),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  Widget _buildLocalInsights(PaletteData c, List<TransaksiUmkm> transaksi) {
    final insights = AIInsightService.generate(transaksi);
    if (insights.isEmpty) {
      return NeoCard(
        backgroundColor: c.surfaceContainerLowest,
        child: Text(tr('dash_ai_empty'), style: TextStyle(color: c.outline)),
      );
    }

    return Column(
      children: insights.map((insight) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: NeoCard(
          backgroundColor: c.surfaceContainerLowest,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(insight.icon, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(insight.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    const SizedBox(height: 2),
                    Text(insight.body, style: TextStyle(fontSize: 11, color: c.onSurfaceVariant, height: 1.4)),
                  ],
                ),
              ),
            ],
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildAnalyticsCards(PaletteData c, List<TransaksiUmkm> transaksi) {
    final growthRate = SalesAnalyticsService.weeklyGrowthRate(transaksi);
    final trend = SalesAnalyticsService.trendAnalysis(transaksi);
    final lowStock = InventoryService.instance.lowStockItems;

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _StatCard(
              icon: Icons.trending_up_rounded,
              label: 'Growth 7H',
              value: '${growthRate >= 0 ? '+' : ''}${growthRate.toStringAsFixed(1)}%',
              color: growthRate >= 0 ? c.primaryContainer : c.errorContainer,
            )),
            const SizedBox(width: 10),
            Expanded(child: _StatCard(
              icon: Icons.show_chart_rounded,
              label: 'Trend',
              value: '${trend.direction} ${trend.confidence.toStringAsFixed(0)}%',
              color: c.secondaryContainer,
            )),
          ],
        ),
        const SizedBox(height: 10),
        _StatCard(
          icon: Icons.warning_amber_rounded,
          label: 'Stok Rendah',
          value: lowStock.isEmpty ? 'Aman' : '${lowStock.length} item',
          color: lowStock.isEmpty ? c.primaryContainer : c.errorContainer,
          fullWidth: true,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool fullWidth;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return NeoCard(
      backgroundColor: color,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: fullWidth ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 22, color: c.onSurface),
          const SizedBox(height: 6),
          Text(label,
              style: TextStyle(fontSize: 11, color: c.onSurfaceVariant),
              textAlign: fullWidth ? TextAlign.left : TextAlign.center),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: c.onSurface),
              textAlign: fullWidth ? TextAlign.left : TextAlign.center),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 10, color: context.palette.onSurfaceVariant)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
      ],
    );
  }
}

class _AiFeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool loading;
  final String? result;
  final VoidCallback onTap;
  final Color color;

  const _AiFeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.loading,
    required this.result,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return NeoButton(
      onTap: loading ? () {} : onTap,
      backgroundColor: color,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: c.onSurface),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                    Text(subtitle, style: TextStyle(fontSize: 11, color: c.onSurfaceVariant)),
                  ],
                ),
              ),
              if (loading)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: c.onSurface),
                )
              else
                Icon(Icons.chevron_right_rounded, color: c.onSurfaceVariant),
            ],
          ),
          if (result != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: c.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: c.outlineVariant, width: 1),
              ),
              child: Text(result!, style: const TextStyle(fontSize: 12, height: 1.5)),
            ),
          ],
        ],
      ),
    );
  }
}
