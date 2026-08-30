import 'package:flutter/material.dart';
import '../../../core/utils/app_l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/transaksi_umkm.dart';
import '../../../core/state/transaksi_umkm_store.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/widgets/neo_card.dart';
import '../../../shared/widgets/neo_button.dart';
import '../widgets/dynamic_qr_widget.dart';

class UmkmTransaksiDetailScreen extends StatefulWidget {
  final TransaksiUmkm transaksi;

  const UmkmTransaksiDetailScreen({super.key, required this.transaksi});

  @override
  State<UmkmTransaksiDetailScreen> createState() => _UmkmTransaksiDetailScreenState();
}

class _UmkmTransaksiDetailScreenState extends State<UmkmTransaksiDetailScreen> {
  late PaymentMethod _paymentMethod;
  late TextEditingController _categoryController;
  late TextEditingController _amountController;
  late List<TransaksiItem> _items;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _paymentMethod = widget.transaksi.paymentMethod;
    _categoryController = TextEditingController(text: widget.transaksi.category);
    _amountController = TextEditingController(
        text: widget.transaksi.amountPaid.toStringAsFixed(0).replaceAllMapped(
              RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
              (m) => '${m[1]}.',
            ));
    _items = List.from(widget.transaksi.items);
  }

  @override
  void dispose() {
    _categoryController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _markChanged() => setState(() => _hasChanges = true);

  double get _subtotal => _items.fold(0.0, (s, i) => s + i.lineTotal);
  double get _ppn => (_subtotal * 0.11).roundToDouble();
  double get _serviceCharge => widget.transaksi.serviceCharge;
  double get _total => _subtotal + _ppn + _serviceCharge;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final t = widget.transaksi;
    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: c.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: c.borderBlack, width: 1.5),
                      ),
                      child: Icon(Icons.arrow_back_rounded, size: 20, color: c.onSurface),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.merchantName.isNotEmpty ? t.merchantName : 'Transaksi',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${t.date.day}/${t.date.month}/${t.date.year} • ${t.date.hour.toString().padLeft(2, '0')}:${t.date.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(fontSize: 11, color: c.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  if (_hasChanges)
                    NeoButton(
                      onTap: _saveChanges,
                      backgroundColor: c.primaryContainer,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      child: Text(tr('umkm_save'),
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w800, color: c.onPrimaryContainer)),
                    ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Payment Method
                    _buildSectionTitle(c, 'Metode Pembayaran'),
                    const SizedBox(height: 8),
                    Row(
                      children: PaymentMethod.values.map((m) {
                        final selected = m == _paymentMethod;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _paymentMethod = m;
                                _hasChanges = true;
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: selected ? c.primaryContainer : c.surfaceContainerLowest,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: selected ? c.borderBlack : c.outlineVariant,
                                    width: selected ? 2 : 1),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    _paymentIcon(m),
                                    size: 20,
                                    color: selected ? c.onPrimaryContainer : c.onSurfaceVariant,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    paymentMethodName(m),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: selected ? c.onPrimaryContainer : c.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    // QR Code for QRIS
                    if (_paymentMethod == PaymentMethod.qris) ...[
                      const SizedBox(height: 16),
                      Center(
                        child: DynamicQRWidget(transaksi: widget.transaksi),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          'Scan untuk bayar QRIS',
                          style: TextStyle(fontSize: 11, color: c.onSurfaceVariant),
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // Category
                    _buildSectionTitle(c, 'Kategori'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _categoryController,
                      onChanged: (_) => _markChanged(),
                      decoration: InputDecoration(
                        hintText: 'Makanan, Minuman, Snack...',
                        filled: true,
                        fillColor: c.surfaceContainerLowest,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: c.borderBlack, width: 1.5),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: c.borderBlack, width: 1.5),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Amount Paid
                    _buildSectionTitle(c, 'Jumlah Bayar'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => _markChanged(),
                      decoration: InputDecoration(
                        prefixText: 'Rp ',
                        filled: true,
                        fillColor: c.surfaceContainerLowest,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: c.borderBlack, width: 1.5),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: c.borderBlack, width: 1.5),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Items
                    _buildSectionTitle(c, 'Item (${_items.length})'),
                    const SizedBox(height: 8),
                    ..._items.asMap().entries.map((entry) {
                      final i = entry.key;
                      final item = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: NeoCard(
                          backgroundColor: c.surfaceContainerLowest,
                          child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700, fontSize: 13)),
                                  Text(
                                    '${item.quantity} x ${formatCurrency(item.price)}',
                                    style: TextStyle(fontSize: 11, color: c.onSurfaceVariant),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              formatCurrency(item.lineTotal),
                              style: TextStyle(
                                  fontWeight: FontWeight.w800, color: c.primary, fontSize: 13),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => _removeItem(i),
                              child: Icon(Icons.remove_circle_outline_rounded,
                                  size: 20, color: c.error),
                            ),
                          ],
                        ),
                      ),
                      );
                    }),

                    const SizedBox(height: 12),

                    // Summary
                    NeoCard(
                      backgroundColor: c.surfaceContainerLowest,
                      child: Column(
                        children: [
                          _buildSummaryRow(c, 'Subtotal', formatCurrency(_subtotal)),
                          _buildSummaryRow(c, 'PPN 11%', formatCurrency(_ppn)),
                          if (_serviceCharge > 0)
                            _buildSummaryRow(c, 'Service', formatCurrency(_serviceCharge)),
                          Divider(color: c.outlineVariant, height: 16),
                          _buildSummaryRow(c, 'Total', formatCurrency(_total), bold: true),
                        ],
                      ),
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

  Widget _buildSectionTitle(PaletteData c, String title) {
    return Text(title,
        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: c.onSurfaceVariant));
  }

  Widget _buildSummaryRow(PaletteData c, String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: bold ? 14 : 12,
                  fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                  color: c.onSurface)),
          Text(value,
              style: TextStyle(
                  fontSize: bold ? 14 : 12,
                  fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                  color: bold ? c.primary : c.onSurface)),
        ],
      ),
    );
  }

  IconData _paymentIcon(PaymentMethod m) {
    switch (m) {
      case PaymentMethod.cash:
        return Icons.payments_rounded;
      case PaymentMethod.qris:
        return Icons.qr_code_rounded;
      case PaymentMethod.debit:
        return Icons.credit_card_rounded;
      case PaymentMethod.credit:
        return Icons.credit_card_rounded;
    }
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
      _hasChanges = true;
    });
  }

  Future<void> _saveChanges() async {
    final amountPaid = double.tryParse(_amountController.text.replaceAll('.', '')) ?? _total;
    final updated = widget.transaksi.copyWith(
      paymentMethod: _paymentMethod,
      category: _categoryController.text.trim(),
      amountPaid: amountPaid,
      items: _items,
      subtotal: _subtotal,
      ppn: _ppn,
      totalAmount: _total,
    );
    await TransaksiUmkmStore.instance.update(updated);
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('umkm_updated')), backgroundColor: context.palette.secondary),
      );
    }
  }
}
