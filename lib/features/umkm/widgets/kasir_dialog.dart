import 'package:flutter/material.dart';
import 'package:fairsplit/core/models/transaksi_umkm.dart';
import 'package:fairsplit/core/state/transaksi_umkm_store.dart';
import 'package:fairsplit/core/theme/app_colors.dart';
import 'package:fairsplit/core/utils/currency_formatter.dart';
import 'package:fairsplit/shared/widgets/neo_button.dart';
import 'package:fairsplit/shared/widgets/neo_card.dart';

class KasirDialog extends StatefulWidget {
  final String merchantName;
  final List<TransaksiItem> items;
  final double subtotal;
  final double ppn;
  final double serviceCharge;
  final double totalAmount;
  final ValueChanged<TransaksiUmkm> onConfirm;

  const KasirDialog({
    super.key,
    required this.merchantName,
    required this.items,
    required this.subtotal,
    required this.ppn,
    required this.serviceCharge,
    required this.totalAmount,
    required this.onConfirm,
  });

  @override
  State<KasirDialog> createState() => _KasirDialogState();
}

class _KasirDialogState extends State<KasirDialog> {
  PaymentMethod _paymentMethod = PaymentMethod.cash;
  final _amountController = TextEditingController();
  final _categoryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _amountController.text = widget.totalAmount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  double get _amountPaid {
    final raw = _amountController.text.replaceAll('.', '').replaceAll(',', '');
    return double.tryParse(raw) ?? 0;
  }

  double get _change => _amountPaid - widget.totalAmount;

  void _confirm() {
    final t = TransaksiUmkm(
      id: 'trx_${DateTime.now().millisecondsSinceEpoch}',
      merchantName: widget.merchantName,
      date: DateTime.now(),
      items: widget.items,
      subtotal: widget.subtotal,
      ppn: widget.ppn,
      serviceCharge: widget.serviceCharge,
      totalAmount: widget.totalAmount,
      paymentMethod: _paymentMethod,
      amountPaid: _amountPaid,
      category: _categoryController.text.trim(),
    );
    widget.onConfirm(t);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: c.surfaceContainerLowest,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: c.borderBlack, width: AppColors.borderWidth),
          left: BorderSide(color: c.borderBlack, width: AppColors.borderWidth),
          right: BorderSide(color: c.borderBlack, width: AppColors.borderWidth),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: c.outline,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Row(
              children: [
                Icon(Icons.store_rounded, color: c.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.merchantName.isNotEmpty ? widget.merchantName : 'Transaksi Baru',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: c.onSurface),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Items list
            NeoCard(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Items', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: c.onSurfaceVariant)),
                  const SizedBox(height: 8),
                  ...widget.items.map((i) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${i.quantity}x ${i.name}',
                            style: TextStyle(fontSize: 13, color: c.onSurface),
                          ),
                        ),
                        Text(
                          formatCurrency(i.lineTotal),
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c.onSurface),
                        ),
                      ],
                    ),
                  )),
                  const Divider(height: 16),
                  _summaryRow('Subtotal', formatCurrency(widget.subtotal), c),
                  if (widget.ppn > 0) _summaryRow('PPN', formatCurrency(widget.ppn), c),
                  if (widget.serviceCharge > 0) _summaryRow('Service', formatCurrency(widget.serviceCharge), c),
                  const SizedBox(height: 4),
                  _summaryRow('TOTAL', formatCurrency(widget.totalAmount), c, bold: true),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Kategori
            Text('Kategori', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: c.onSurfaceVariant)),
            const SizedBox(height: 6),
            Autocomplete<String>(
              optionsBuilder: (textEditingValue) {
                if (textEditingValue.text.isEmpty) return const Iterable.empty();
                final cats = TransaksiUmkmStore.instance.existingCategories;
                return cats.where((cat) =>
                    cat.toLowerCase().contains(textEditingValue.text.toLowerCase()));
              },
              onSelected: (value) => _categoryController.text = value,
              fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
                focusNode.addListener(() {
                  if (!focusNode.hasFocus) {
                    _categoryController.text = controller.text;
                  }
                });
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  onEditingComplete: () {
                    _categoryController.text = controller.text;
                    focusNode.unfocus();
                  },
                  onChanged: (_) => _categoryController.text = controller.text,
                  decoration: InputDecoration(
                    hintText: 'F&B, Minuman, dll.',
                    hintStyle: TextStyle(color: c.outline),
                    filled: true,
                    fillColor: c.surfaceContainerHigh,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: c.borderBlack, width: AppColors.borderWidth),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: c.borderBlack, width: AppColors.borderWidth),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  style: TextStyle(fontSize: 13, color: c.onSurface),
                );
              },
            ),
            const SizedBox(height: 16),

            // Payment method
            Text('Metode Bayar', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: c.onSurfaceVariant)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: PaymentMethod.values.map((m) {
                final selected = _paymentMethod == m;
                return GestureDetector(
                  onTap: () => setState(() => _paymentMethod = m),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: selected ? c.primaryContainer : c.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: c.borderBlack,
                        width: AppColors.borderWidth,
                      ),
                      boxShadow: selected
                          ? [BoxShadow(color: c.borderBlack, offset: const Offset(2, 2))]
                          : [],
                    ),
                    child: Text(
                      paymentMethodName(m),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: selected ? c.onPrimaryContainer : c.onSurface,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Amount paid
            Text('Bayar', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: c.onSurfaceVariant)),
            const SizedBox(height: 6),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                prefixText: 'Rp ',
                prefixStyle: TextStyle(fontWeight: FontWeight.w700, color: c.onSurface),
                filled: true,
                fillColor: c.surfaceContainerHigh,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: c.borderBlack, width: AppColors.borderWidth),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: c.borderBlack, width: AppColors.borderWidth),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: c.onSurface),
            ),
            const SizedBox(height: 8),

            // Quick pay buttons
            Row(
              children: [
                _quickPayButton('Uang Pas', widget.totalAmount, c),
                const SizedBox(width: 8),
                _quickPayButton('50.000', 50000, c),
                const SizedBox(width: 8),
                _quickPayButton('100.000', 100000, c),
              ],
            ),
            const SizedBox(height: 12),

            // Change
            if (_amountPaid >= widget.totalAmount)
              NeoCard(
                padding: const EdgeInsets.all(12),
                backgroundColor: c.primaryContainer,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Kembali', style: TextStyle(fontWeight: FontWeight.w700, color: c.onPrimaryContainer)),
                    Text(
                      formatCurrency(_change),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: c.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            if (_amountPaid > 0 && _amountPaid < widget.totalAmount)
              NeoCard(
                padding: const EdgeInsets.all(12),
                backgroundColor: c.errorContainer,
                child: Text(
                  'Bayar kurang dari total',
                  style: TextStyle(fontWeight: FontWeight.w700, color: c.onSurface),
                ),
              ),
            const SizedBox(height: 16),

            // Confirm
            NeoButton(
              onTap: _amountPaid >= widget.totalAmount ? _confirm : () {},
              width: double.infinity,
              backgroundColor: _amountPaid >= widget.totalAmount ? c.primary : c.outline,
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Text(
                'Simpan Transaksi',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: _amountPaid >= widget.totalAmount ? Colors.white : c.onSurface,
                ),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value, PaletteData c, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: bold ? 14 : 13,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
              color: c.onSurface,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: bold ? 14 : 13,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              color: c.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickPayButton(String label, double amount, PaletteData c) {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _amountController.text = amount.toStringAsFixed(0).replaceAllMapped(
                RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                (m) => '${m[1]}.',
              );
        }),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: c.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: c.borderBlack, width: AppColors.borderWidth),
          ),
          alignment: Alignment.center,
          child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: c.onSurface)),
        ),
      ),
    );
  }
}
