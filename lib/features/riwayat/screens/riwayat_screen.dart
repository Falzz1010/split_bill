import 'package:flutter/material.dart';
import '../../../core/utils/app_l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/split_model.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../shared/widgets/neo_avatar.dart';
import '../../../shared/widgets/neo_card.dart';
import '../../../shared/widgets/neo_chip.dart';
import '../../../shared/widgets/neo_search_bar.dart';
import '../../../shared/widgets/neo_confirm_dialog.dart';

class RiwayatScreen extends StatefulWidget {
  final List<SplitBill> splits;
  final Function(SplitBill) onSelectSplit;
  final Function(String)? onDeleteSplit;

  const RiwayatScreen({
    super.key,
    required this.splits,
    required this.onSelectSplit,
    this.onDeleteSplit,
  });

  @override
  State<RiwayatScreen> createState() => _RiwayatScreenState();
}

class _RiwayatScreenState extends State<RiwayatScreen> {
  int _selectedTab = 0; // 0: Semua, 1: Lunas, 2: Pending
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<SplitBill> filteredSplits = widget.splits.where((split) {
      if (_selectedTab == 1) return split.isCompleted;
      if (_selectedTab == 2) return !split.isCompleted;
      return true;
    }).where((split) => split.matches(_searchQuery)).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                tr('his_title'),
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),

              // Search Bar
              NeoSearchBar(
                hintText: tr('his_search_hint'),
                controller: _searchController,
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
              const SizedBox(height: 16),

              // Filter Tabs
              Row(
                children: [
                  _buildTabChip('${tr('his_tab_all')} (${widget.splits.length})', index: 0),
                  const SizedBox(width: 8),
                  _buildTabChip(tr('his_tab_lunas'), index: 1),
                  const SizedBox(width: 8),
                  _buildTabChip(tr('his_tab_pending'), index: 2),
                ],
              ),
              const SizedBox(height: 16),

              // History List
              Expanded(
                child: filteredSplits.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.receipt_long_outlined, size: 64, color: AppColors.outline),
                            const SizedBox(height: 12),
                            Text(
                              _searchQuery.trim().isEmpty
                                  ? tr('his_empty')
                                  : tr('his_empty_search'),
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 100),
                        itemCount: filteredSplits.length,
                        itemBuilder: (context, index) {
                          final split = filteredSplits[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: NeoCard(
                              onTap: () => widget.onSelectSplit(split),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              split.title,
                                              style: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 16),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              split.category,
                                              style: Theme.of(context).textTheme.bodySmall,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 2),
                                            Row(
                                              children: [
                                                Icon(Icons.calendar_today_rounded, size: 12, color: AppColors.outline),
                                                const SizedBox(width: 4),
                                                Text(
                                                  DateFormatter.formatDate(split.date),
                                                  style: Theme.of(context).textTheme.bodySmall,
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          if (widget.onDeleteSplit != null) ...[
                                            IconButton(
                                              icon: Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                                              onPressed: () async {
                                                final confirmed = await showDeleteConfirmDialog(context, split.title);
                                                if (!confirmed || !context.mounted) return;
                                                widget.onDeleteSplit!(split.id);
                                                showNeoSnack(context, tr('ring_deleted').replaceAll('{title}', split.title));
                                              },
                                            ),
                                            const SizedBox(width: 4),
                                          ],
                                          NeoChip(
                                            label: split.isCompleted ? tr('his_lunas') : tr('his_menunggu'),
                                            backgroundColor: split.isCompleted ? AppColors.secondaryContainer : AppColors.errorContainer,
                                            textColor: split.isCompleted
                                                ? AppColors.onAccent(AppColors.secondaryContainer)
                                                : AppColors.error,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Divider(height: 20, thickness: 1.5, color: AppColors.outlineVariant),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          ...split.members.take(3).map(
                                            (m) => Padding(
                                              padding: const EdgeInsets.only(right: 8),
                                              child: NeoAvatar(member: m, size: 32, fontSize: 12),
                                            ),
                                          ),
                                          if (split.members.isEmpty)
                                            Container(
                                              width: 32,
                                              height: 32,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: AppColors.surfaceContainerHighest,
                                                border: Border.all(color: AppColors.borderBlack, width: 1.5),
                                              ),
                                              child: Icon(Icons.group_rounded, size: 16, color: AppColors.outline),
                                            ),
                                          if (split.members.length > 3)
                                            Container(
                                              width: 32,
                                              height: 32,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: AppColors.surfaceContainerHighest,
                                                border: Border.all(color: AppColors.borderBlack, width: 1.5),
                                              ),
                                              child: Center(
                                                child: Text(
                                                  '+${split.members.length - 3}',
                                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.onSurface),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      Text(
                                        formatCurrency(split.totalAmount),
                                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                              color: AppColors.primary,
                                              fontSize: 16,
                                            ),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabChip(String label, {required int index}) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryContainer : AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.borderBlack, width: 2),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.borderBlack,
                    offset: Offset(2, 2),
                    blurRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            fontSize: 12,
            color: isSelected ? AppColors.onPrimaryContainer : AppColors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
