import 'package:flutter/material.dart';
import '../../../core/utils/app_l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/split_model.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/widgets/neo_card.dart';
import '../../../shared/widgets/neo_button.dart';
import '../../../shared/widgets/neo_search_bar.dart';
import '../../../shared/widgets/neo_chip.dart';
import '../../../shared/widgets/neo_paw_logo.dart';
import '../../../shared/widgets/neo_pie_chart.dart';
import '../../../shared/widgets/neo_line_chart.dart';
import '../../../shared/widgets/neo_shimmer_skeleton.dart';

class DashboardScreen extends StatefulWidget {
  final List<SplitBill> splits;
  final SplitBill activeFeaturedSplit;
  final bool isLoading;
  final VoidCallback onOpenScanner;
  final VoidCallback onCreateNewSplit;
  final Function(SplitBill) onSelectSplit;

  const DashboardScreen({
    super.key,
    required this.splits,
    required this.activeFeaturedSplit,
    this.isLoading = false,
    required this.onOpenScanner,
    required this.onCreateNewSplit,
    required this.onSelectSplit,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<SplitBill> get _visibleSplits {
    if (_searchQuery.trim().isEmpty) return widget.splits;
    return widget.splits.where((s) => s.matches(_searchQuery)).toList();
  }

  SplitBill get _featuredSplit {
    final visible = _visibleSplits;
    if (visible.isEmpty) return widget.activeFeaturedSplit;
    final current = widget.activeFeaturedSplit;
    if (visible.any((s) => s.id == current.id)) return current;
    return visible.first;
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 11) return tr('dash_greeting_morning');
    if (hour >= 11 && hour < 18) return tr('dash_greeting_afternoon');
    return tr('dash_greeting_evening');
  }

  List<PieChartDataSection> _calculatePieSections(List<SplitBill> splits) {
    if (splits.isEmpty) {
      return [
        PieChartDataSection(
          label: tr('dash_empty_all'),
          value: 100,
          color: context.palette.surfaceContainerHigh,
        ),
      ];
    }

    final Map<String, double> categoryTotals = {};
    for (var split in splits) {
      final categoryName = split.categoryLabel;
      categoryTotals[categoryName] =
          (categoryTotals[categoryName] ?? 0) + split.totalAmount;
    }

    final colors = [
      context.palette.primaryContainer,
      context.palette.secondaryContainer,
      context.palette.errorContainer,
      AppColors.tertiaryFixedDim,
      AppColors.primaryFixed,
    ];

    int colorIdx = 0;
    return categoryTotals.entries.map((entry) {
      final color = colors[colorIdx % colors.length];
      colorIdx++;
      return PieChartDataSection(
        label: entry.key,
        value: entry.value,
        color: color,
      );
    }).toList();
  }

  List<LinePoint> _calculateLineData(List<SplitBill> splits) {
    final now = DateTime.now();
    final monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];

    final List<LinePoint> linePoints = [];

    for (int i = 5; i >= 0; i--) {
      final targetMonthDate = DateTime(now.year, now.month - i, 1);
      final monthLabel = monthNames[targetMonthDate.month - 1];

      double monthTotal = 0;
      for (var split in splits) {
        if (split.date.year == targetMonthDate.year &&
            split.date.month == targetMonthDate.month) {
          monthTotal += split.totalAmount;
        }
      }

      linePoints.add(LinePoint(monthLabel, (monthTotal / 1000)));
    }

    return linePoints;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final dynamicPieSections = _calculatePieSections(_visibleSplits);
    final dynamicLinePoints = _calculateLineData(_visibleSplits);

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Header Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        NeoPawLogo(size: 52),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tr('dash_title'),
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w800,
                                    ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _greeting(),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(fontSize: 14),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  NeoButton(
                    onTap: widget.onCreateNewSplit,
                    backgroundColor: c.surfaceContainerLowest,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add, size: 16, color: c.onSurface),
                        const SizedBox(width: 4),
                        Text(
                          tr('dash_new_receipts'),
                          style: Theme.of(
                            context,
                          ).textTheme.labelMedium?.copyWith(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Search Bar
              NeoSearchBar(
                hintText: tr('dash_search_hint'),
                controller: _searchController,
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
              const SizedBox(height: 24),

              // Dynamic Horizontal Split Aktif Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${tr('dash_split_active')} (${_visibleSplits.length})',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  GestureDetector(
                    onTap: widget.onCreateNewSplit,
                    child: Text(
                      tr('dash_buat_baru_plus'),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: c.secondary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              SizedBox(
                height: 76,
                child: ListView.builder(
                  clipBehavior: Clip.none,
                  scrollDirection: Axis.horizontal,
                  itemCount:
                      widget.isLoading ? 3 : _visibleSplits.length + 1,
                  itemBuilder: (context, index) {
                    if (widget.isLoading) {
                      return const Padding(
                        padding: EdgeInsets.only(right: 12, bottom: 6),
                        child: NeoShimmerCard(
                          width: 150,
                          height: 76,
                          lines: 2,
                        ),
                      );
                    }

                    if (index == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 12, bottom: 6),                          child: NeoCard(
                          onTap: widget.onCreateNewSplit,
                          backgroundColor: c.secondaryContainer,
                          borderRadius: 14,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          shadowOffset: const Offset(2.5, 2.5),
                          child: Row(
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: c.secondary,
                                ),
                                child: Icon(
                                  Icons.add,
                                  size: 20,
                                  color: AppColors.onAccent(
                                    c.secondary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                tr('dash_buat_baru'),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: AppColors.onAccent(
                                    c.secondaryContainer,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    final split = _visibleSplits[index - 1];
                    final isSelected = _featuredSplit.id == split.id;
                    final memberName = split.members.isNotEmpty
                        ? split.members.first.name
                        : tr('dash_group');
                    final accentColorHex = split.members.isNotEmpty
                        ? split.members.first.accentColorHex
                        : '#FFCD00';

                    final accentColor = AppColors.fromHex(accentColorHex);
                    final onAccent = AppColors.onAccent(accentColor);

                    return Padding(
                      padding: const EdgeInsets.only(right: 12, bottom: 6),
                      child: NeoCard(
                        onTap: () => widget.onSelectSplit(split),
                        backgroundColor: accentColor,
                        borderRadius: 14,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        shadowOffset: isSelected
                            ? const Offset(3.5, 3.5)
                            : const Offset(2, 2),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                              color: c.surfaceContainerLowest,
                              border: Border.all(
                                color: c.borderBlack,
                                  width: 1.5,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  memberName[0],
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: c.onSurface,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  memberName,
                                  style: Theme.of(context).textTheme.labelMedium
                                      ?.copyWith(
                                        color: onAccent,
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                                Text(
                                  split.title,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(fontSize: 11, color: onAccent),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Dynamic Featured Split Card
              if (widget.isLoading)
                const NeoShimmerCard(
                  height: 320,
                  boxSize: 60,
                  lines: 5,
                  trailing: true,
                )
              else if (widget.splits.isEmpty)
                _buildEmptyStateCard(context)
              else if (_visibleSplits.isEmpty)
                _buildNoResultsCard(context)
              else
                NeoCard(
                  borderRadius: 28,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Info
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: c.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: c.borderBlack,
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.receipt_long_rounded,
                                size: 32,
                                color: c.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _featuredSplit.title,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(fontSize: 17),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _featuredSplit.displayCategory,
                                  style: Theme.of(context).textTheme.bodySmall,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                NeoChip(
                                  label: DateFormatter.formatDate(
                                    _featuredSplit.date,
                                  ),
                                  icon: Icons.calendar_month_rounded,
                                  backgroundColor: c.surfaceContainer,
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.more_vert_rounded,
                            color: c.onSurfaceVariant,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Status Badge Card
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: _featuredSplit.isCompleted
                              ? c.secondaryContainer.withAlpha(80)
                              : c.errorContainer.withAlpha(80),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: c.borderBlack,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _featuredSplit.isCompleted
                                    ? c.secondary
                                    : c.error,
                              ),
                              child: Icon(
                                _featuredSplit.isCompleted
                                    ? Icons.check
                                    : Icons.pending_rounded,
                                size: 14,
                                color: AppColors.onAccent(
                                  _featuredSplit.isCompleted
                                      ? c.secondary
                                      : c.error,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _featuredSplit.isCompleted
                                        ? tr('common_lunas')
                                        : tr('dash_not_settled'),
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium
                                        ?.copyWith(color: c.onSurface),
                                  ),
                                  Text(
                                    tr('dash_member_transfer')
                                        .replaceAll(
                                          '{paid}',
                                          '${_featuredSplit.paidCount}',
                                        )
                                        .replaceAll(
                                          '{total}',
                                          '${_featuredSplit.members.length}',
                                        ),
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: c.onSurfaceVariant,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 3 Grid Stat Boxes
                      Container(
                        decoration: BoxDecoration(
                          color: c.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: c.borderBlack,
                            width: 2,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 4,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildStatItem(
                                context,
                                icon: Icons.payments_rounded,
                                iconBg: c.primaryContainer,
                                label: tr('dash_total'),
                                value: formatCompactCurrency(
                                  _featuredSplit.totalAmount,
                                ),
                                tag: tr('dash_proporsional'),
                              ),
                            ),
                            Container(
                              width: 2,
                              height: 50,
                              color: c.borderBlack,
                            ),
                            Expanded(
                              child: _buildStatItem(
                                context,
                                icon: Icons.receipt_long_rounded,
                                iconBg: AppColors.tertiaryFixedDim,
                                label: tr('dash_items'),
                                value:
                                    '${_featuredSplit.items.length} ${tr('dash_psn')}',
                                tag: tr('dash_counted'),
                              ),
                            ),
                            Container(
                              width: 2,
                              height: 50,
                              color: c.borderBlack,
                            ),
                            Expanded(
                              child: _buildStatItem(
                                context,
                                icon: Icons.pending_actions_rounded,
                                iconBg: AppColors.primaryFixed,
                                label: tr('dash_status'),
                                value:
                                    '${_featuredSplit.members.length - _featuredSplit.paidCount} ${tr('dash_pndg')}',
                                tag: tr('dash_menunggu'),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // CTA Button
                      NeoButton(
                        onTap: () => widget.onSelectSplit(_featuredSplit),
                        width: double.infinity,
                        backgroundColor: c.primaryContainer,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Text(
                          tr('dash_lihat_edit'),
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                color: c.onPrimaryContainer,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),

              // Dynamic Real-Time Section 1: Pie Chart (Kategori Pengeluaran)
              if (widget.isLoading)
                const NeoShimmerCard(
                  height: 230,
                  boxSize: 48,
                  lines: 6,
                )
              else
                NeoPieChart(
                  title: tr('dash_category_chart'),
                  sections: dynamicPieSections,
                ),
              const SizedBox(height: 24),

              // Dynamic Real-Time Section 2: Line Chart (Tren Split Bill 6 Bulan)
              if (widget.isLoading)
                const NeoShimmerCard(
                  height: 230,
                  boxSize: 48,
                  lines: 6,
                )
              else
                NeoLineChart(
                  title: tr('dash_trend_chart'),
                  subtitle: tr('dash_chart_6mo'),
                  emptyText: tr('dash_no_line_data'),
                  data: dynamicLinePoints,
                ),

              // Bottom safe padding for bottom nav bar
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyStateCard(BuildContext context) {
    final c = context.palette;
    return NeoCard(
      borderRadius: 28,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: c.surfaceContainerLow,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: c.borderBlack, width: 2),
            ),
            child: Center(
              child: Icon(
                Icons.receipt_long_rounded,
                size: 36,
                color: c.primary,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            tr('dash_empty_all'),
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontSize: 18),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            tr('dash_empty_desc2'),
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          NeoButton(
            onTap: widget.onCreateNewSplit,
            backgroundColor: c.primaryContainer,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Text(
              tr('dash_buat_struk_baru'),
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: c.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsCard(BuildContext context) {
    final c = context.palette;
    return NeoCard(
      borderRadius: 28,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: c.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: c.borderBlack, width: 2),
            ),
            child: Center(
              child: Icon(
                Icons.search_off_rounded,
                size: 28,
                color: c.primary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            tr('dash_not_found'),
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontSize: 17),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            tr('dash_noresult_desc'),
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required IconData icon,
    required Color iconBg,
    required String label,
    required String value,
    required String tag,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: AppColors.onAccent(iconBg)),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10),
        ),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontSize: 13),
          ),
        ),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
          decoration: BoxDecoration(
            color: context.palette.surfaceContainerLowest.withAlpha(180),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            tag,
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.bold,
              color: context.palette.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
