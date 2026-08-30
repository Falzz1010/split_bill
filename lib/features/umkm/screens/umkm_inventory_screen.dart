import 'package:flutter/material.dart';
import '../../../core/utils/app_l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/inventory_service.dart';
import '../../../core/state/transaksi_umkm_store.dart';
import '../../../shared/widgets/neo_card.dart';

class UmkmInventoryScreen extends StatefulWidget {
  const UmkmInventoryScreen({super.key});

  @override
  State<UmkmInventoryScreen> createState() => _UmkmInventoryScreenState();
}

class _UmkmInventoryScreenState extends State<UmkmInventoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
                  Icon(Icons.inventory_2_rounded, color: c.primary, size: 24),
                  const SizedBox(width: 10),
                  Text(tr('umkm_inventory'), style: Theme.of(context).textTheme.headlineLarge),
                ],
              ),
            ),

            // Summary cards
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  _buildMiniStat(c, 'Total Item', '${InventoryService.instance.items.length}', Icons.category_rounded),
                  const SizedBox(width: 8),
                  _buildMiniStat(c, 'Stok Rendah', '${InventoryService.instance.lowStockItems.length}', Icons.warning_rounded,
                      color: InventoryService.instance.lowStockItems.isNotEmpty ? c.error : null),
                  const SizedBox(width: 8),
                  _buildMiniStat(c, 'Nilai Stok', _formatValue(InventoryService.instance.totalInventoryValue), Icons.attach_money_rounded),
                ],
              ),
            ),

            // Tabs
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Container(
                decoration: BoxDecoration(
                  color: c.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: c.borderBlack, width: 1.5),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: c.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                  unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: c.onSurfaceVariant),
                  tabs: [
                    Tab(text: tr('umkm_inv_all')),
                    Tab(text: tr('umkm_inv_alert')),
                    Tab(text: tr('umkm_inv_fast')),
                  ],
                ),
              ),
            ),

            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildAllItems(c),
                  _buildAlerts(c),
                  _buildFastMoving(c),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(PaletteData c, String label, String value, IconData icon, {Color? color}) {
    return Expanded(
      child: NeoCard(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Icon(icon, size: 18, color: color ?? c.primary),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: color ?? c.onSurface)),
            Text(label, style: TextStyle(fontSize: 9, color: c.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }

  Widget _buildAllItems(PaletteData c) {
    final items = InventoryService.instance.items;
    if (items.isEmpty) {
      return Center(child: Text(tr('umkm_inv_empty'), style: TextStyle(color: c.outline)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) => _buildItemCard(c, items[index]),
    );
  }

  Widget _buildAlerts(PaletteData c) {
    final alerts = InventoryService.instance.reorderSuggestions;
    if (alerts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_rounded, size: 48, color: Colors.green),
            const SizedBox(height: 12),
            Text(tr('umkm_inv_no_alert'), style: TextStyle(color: c.outline)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: alerts.length,
      itemBuilder: (context, index) {
        final a = alerts[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: NeoCard(
          backgroundColor: a.item.isCritical ? c.errorContainer : c.surfaceContainerLowest,
          child: Row(
            children: [
              Container(
                width: 4, height: 48,
                decoration: BoxDecoration(
                  color: a.item.isCritical ? c.error : Colors.orange,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(a.item.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    Text(a.reason, style: TextStyle(fontSize: 11, color: c.error)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${a.item.currentStock} / ${a.item.minStock}',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: c.error)),
                  Text('Order ${a.suggestedOrder} ${a.item.unit}',
                      style: TextStyle(fontSize: 10, color: c.primary)),
                ],
              ),
            ],
          ),
          ),
        );
      },
    );
  }

  Widget _buildFastMoving(PaletteData c) {
    final fast = InventoryService.instance.fastMoving(
      TransaksiUmkmStore.instance.transaksi,
      limit: 10,
    );
    if (fast.isEmpty) {
      return Center(child: Text(tr('umkm_inv_no_data'), style: TextStyle(color: c.outline)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: fast.length,
      itemBuilder: (context, index) {
        final f = fast[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: NeoCard(
          child: Row(
            children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: c.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text('${index + 1}', style: TextStyle(fontWeight: FontWeight.w800, color: c.onPrimaryContainer, fontSize: 14)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(f.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    Text('${f.totalSold} terjual', style: TextStyle(fontSize: 11, color: c.onSurfaceVariant)),
                  ],
                ),
              ),
              Text(_formatCurrency(f.revenue), style: TextStyle(fontWeight: FontWeight.w800, color: c.primary, fontSize: 13)),
            ],
          ),
          ),
        );
      },
    );
  }

  Widget _buildItemCard(PaletteData c, InventoryItem item) {
    final stockColor = item.isCritical
        ? c.error
        : item.isLow ? Colors.orange : c.primary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: NeoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(item.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                        const SizedBox(width: 6),
                        if (item.isCritical)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: c.error, borderRadius: BorderRadius.circular(6)),
                            child: Text('KRITIS', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: c.background)),
                          )
                        else if (item.isLow)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(6)),
                            child: Text('RENDAH', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: c.background)),
                          ),
                      ],
                    ),
                    Text('${item.category} • ${item.unit}',
                        style: TextStyle(fontSize: 11, color: c.onSurfaceVariant)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${item.currentStock}',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: stockColor)),
                  Text('/ ${item.maxStock}',
                      style: TextStyle(fontSize: 10, color: c.onSurfaceVariant)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: item.stockPercent / 100,
              backgroundColor: c.outlineVariant,
              valueColor: AlwaysStoppedAnimation(stockColor),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text('Min: ${item.minStock}', style: TextStyle(fontSize: 10, color: c.onSurfaceVariant)),
              const Spacer(),
              // Adjust buttons
              GestureDetector(
                onTap: () => InventoryService.instance.adjustStock(item.id, -1),
                child: Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color: c.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: c.borderBlack, width: 1),
                  ),
                  child: Icon(Icons.remove, size: 16, color: c.error),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => InventoryService.instance.adjustStock(item.id, 1),
                child: Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color: c.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: c.borderBlack, width: 1),
                  ),
                  child: Icon(Icons.add, size: 16, color: c.onPrimaryContainer),
                ),
              ),
            ],
          ),
        ],
      ),
      ),
    );
  }

  String _formatValue(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K';
    return v.toStringAsFixed(0);
  }

  String _formatCurrency(double v) {
    return 'Rp ${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }
}
