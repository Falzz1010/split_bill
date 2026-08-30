import 'package:flutter/material.dart';
import '../../../core/utils/app_l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/transaksi_umkm.dart';
import '../../../core/state/transaksi_umkm_store.dart';
import '../../../core/services/pdf_export_service.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/widgets/neo_card.dart';
import '../../../shared/widgets/neo_confirm_dialog.dart';
import 'umkm_transaksi_detail_screen.dart';

class UmkmTransaksiListScreen extends StatefulWidget {
  const UmkmTransaksiListScreen({super.key});

  @override
  State<UmkmTransaksiListScreen> createState() => _UmkmTransaksiListScreenState();
}

class _UmkmTransaksiListScreenState extends State<UmkmTransaksiListScreen> {
  String _search = '';
  String? _filterCategory;
  DateTimeRange? _dateRange;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return ListenableBuilder(
      listenable: TransaksiUmkmStore.instance,
      builder: (context, _) {
        var list = TransaksiUmkmStore.instance.transaksi;

        // Filter search
        if (_search.isNotEmpty) {
          final q = _search.toLowerCase();
          list = list.where((t) {
            final merchant = t.merchantName.toLowerCase();
            final cats = t.category.toLowerCase();
            final items = t.items.any((i) => i.name.toLowerCase().contains(q));
            return merchant.contains(q) || cats.contains(q) || items;
          }).toList();
        }

        // Filter category
        if (_filterCategory != null) {
          list = list.where((t) => t.category == _filterCategory).toList();
        }

        // Filter date range
        if (_dateRange != null) {
          list = list.where((t) {
            final d = t.date;
            return !d.isBefore(_dateRange!.start) && !d.isAfter(_dateRange!.end);
          }).toList();
        }

        // Group by date
        final grouped = <String, List<TransaksiUmkm>>{};
        for (final t in list) {
          final key = '${t.date.day}/${t.date.month}/${t.date.year}';
          grouped.putIfAbsent(key, () => []).add(t);
        }

        return Scaffold(
          backgroundColor: c.background,
          body: SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Row(
                    children: [
                      Icon(Icons.receipt_long_rounded, color: c.primary, size: 24),
                      const SizedBox(width: 10),
                      Text(tr('umkm_transaksi_list'),
                          style: Theme.of(context).textTheme.headlineLarge),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => PdfExportService.exportAllTransactions(range: _dateRange),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: c.secondaryContainer,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: c.borderBlack, width: 1.5),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.picture_as_pdf_rounded, size: 16, color: c.onSecondaryContainer),
                              const SizedBox(width: 4),
                              Text('PDF', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: c.onSecondaryContainer)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('${list.length} transaksi',
                          style: TextStyle(fontSize: 12, color: c.onSurfaceVariant)),
                    ],
                  ),
                ),

                // Search bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: TextField(
                    onChanged: (v) => setState(() => _search = v),
                    decoration: InputDecoration(
                      hintText: tr('umkm_transaksi_search'),
                      prefixIcon: Icon(Icons.search_rounded, size: 20, color: c.onSurfaceVariant),
                      filled: true,
                      fillColor: c.surfaceContainerLowest,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: c.borderBlack, width: 1.5),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: c.borderBlack, width: 1.5),
                      ),
                    ),
                  ),
                ),

                // Filter chips
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                  child: Row(
                    children: [
                      _buildFilterChip(
                        c,
                        label: _dateRange != null
                            ? '${_dateRange!.start.day}/${_dateRange!.start.month} - ${_dateRange!.end.day}/${_dateRange!.end.month}'
                            : 'Semua Tanggal',
                        icon: Icons.date_range_rounded,
                        active: _dateRange != null,
                        onTap: _pickDateRange,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        c,
                        label: _filterCategory ?? 'Semua Kategori',
                        icon: Icons.category_rounded,
                        active: _filterCategory != null,
                        onTap: _pickCategory,
                      ),
                      if (_dateRange != null || _filterCategory != null) ...[
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => setState(() {
                            _dateRange = null;
                            _filterCategory = null;
                          }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: c.errorContainer,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: c.borderBlack, width: 1),
                            ),
                            child: Text(tr('umkm_clear_filter'),
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: c.error)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // List
                Expanded(
                  child: list.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.receipt_long_rounded, size: 48, color: c.outline),
                              const SizedBox(height: 12),
                              Text(tr('umkm_no_trans'), style: TextStyle(color: c.outline)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          itemCount: grouped.entries.length,
                          itemBuilder: (context, index) {
                            final entry = grouped.entries.elementAt(index);
                            final dayTotal = entry.value.fold(0.0, (s, t) => s + t.totalAmount);
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 8, bottom: 4),
                                  child: Row(
                                    children: [
                                      Text(entry.key,
                                          style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w800,
                                              color: c.onSurfaceVariant)),
                                      const SizedBox(width: 8),
                                      Expanded(child: Divider(color: c.outlineVariant)),
                                      const SizedBox(width: 8),
                                      Text(formatCurrency(dayTotal),
                                          style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: c.primary)),
                                    ],
                                  ),
                                ),
                                ...entry.value.map((t) => _buildTransactionCard(c, t)),
                              ],
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(PaletteData c,
      {required String label, required IconData icon, required bool active, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: active ? c.primaryContainer : c.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: c.borderBlack, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: active ? c.onPrimaryContainer : c.onSurfaceVariant),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: active ? c.onPrimaryContainer : c.onSurface)),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionCard(PaletteData c, TransaksiUmkm t) {
    return Dismissible(
      key: ValueKey(t.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: c.error,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(Icons.delete_rounded, color: c.background),
      ),
      confirmDismiss: (_) async {
        return await showConfirmDialog(
          context,
          title: tr('umkm_delete_title'),
          message: tr('umkm_delete_desc').replaceAll('{name}', t.merchantName),
          confirmLabel: tr('del_hapus'),
        );
      },
      onDismissed: (_) {
        TransaksiUmkmStore.instance.delete(t.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr('umkm_deleted')),
            backgroundColor: c.onSurface,
          ),
        );
      },
      child: GestureDetector(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => UmkmTransaksiDetailScreen(transaksi: t)),
        ),
        child: NeoCard(
          backgroundColor: c.surfaceContainerLowest,
          child: Row(
            children: [
              Container(
                width: 4,
                height: 52,
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
                    Text(
                      t.merchantName.isNotEmpty ? t.merchantName : 'Transaksi',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          '${t.items.length} items',
                          style: TextStyle(fontSize: 11, color: c.onSurfaceVariant),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: c.primaryContainer,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            paymentMethodName(t.paymentMethod),
                            style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: c.onPrimaryContainer),
                          ),
                        ),
                        if (t.category.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Text(t.category,
                              style: TextStyle(fontSize: 10, color: c.onSurfaceVariant)),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatCurrency(t.totalAmount),
                    style: TextStyle(
                        fontWeight: FontWeight.w800, color: c.primary, fontSize: 14),
                  ),
                  Text(
                    '${t.date.hour.toString().padLeft(2, '0')}:${t.date.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(fontSize: 10, color: c.onSurfaceVariant),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: now,
      initialDateRange: _dateRange,
    );
    if (range != null) setState(() => _dateRange = range);
  }

  Future<void> _pickCategory() async {
    final cats = TransaksiUmkmStore.instance.existingCategories;
    if (cats.isEmpty) return;
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (context) {
        final c = context.palette;
        return Container(
          decoration: BoxDecoration(
            color: c.surfaceContainerLowest,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(color: c.borderBlack, width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: c.outline, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              Text(tr('umkm_pick_category'),
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: 8),
              ...cats.map((cat) => ListTile(
                    title: Text(cat),
                    trailing: _filterCategory == cat
                        ? Icon(Icons.check_rounded, color: c.primary)
                        : null,
                    onTap: () => Navigator.pop(context, cat),
                  )),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
    if (selected != null) setState(() => _filterCategory = selected);
  }
}
