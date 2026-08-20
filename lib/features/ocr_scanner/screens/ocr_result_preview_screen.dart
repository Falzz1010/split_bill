import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/models/split_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_l10n.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/currency_rates.dart';
import '../../../core/utils/receipt_parser.dart';
import '../../../shared/widgets/neo_button.dart';

/// Layar preview hasil scan OCR sebelum dipakai:
/// - teks mentah OCR bisa diedit & di-parse ulang (koreksi salah baca OCR)
/// - daftar item hasil parse bisa diedit / dihapus / ditambah
/// - tombol Lanjutkan → mengembalikan ParsedReceiptResult yang sudah dikoreksi
class OcrResultPreviewScreen extends StatefulWidget {
  final String rawText;
  final ParsedReceiptResult parsed;
  final Uint8List? imageBytes;
  final void Function(ParsedReceiptResult parsed) onConfirm;

  const OcrResultPreviewScreen({
    super.key,
    required this.rawText,
    required this.parsed,
    required this.onConfirm,
    this.imageBytes,
  });

  @override
  State<OcrResultPreviewScreen> createState() => _OcrResultPreviewScreenState();
}

class _OcrResultPreviewScreenState extends State<OcrResultPreviewScreen> {
  late final TextEditingController _titleController =
      TextEditingController(text: widget.parsed.merchantName);
  late final TextEditingController _rawTextController =
      TextEditingController(text: widget.rawText);

  late ParsedReceiptResult _parsed = widget.parsed;
  late List<ReceiptItem> _items = List.of(widget.parsed.items);

  /// Mata uang asal struk (terdeteksi dari teks; null/IDR = rupiah).
  String? _currency;

  @override
  void initState() {
    super.initState();
    _currency = CurrencyRatesService.detectCurrency(widget.rawText);
  }

  bool get _isForeign => _currency != null && _currency != 'IDR';

  /// Format nilai dalam mata uang asal struk ("$ 12.50" / "Rp 28.000").
  String _fmt(double v, {int d = 0}) {
    final code = _currency;
    final nf = code == null || code == 'IDR'
        ? NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: d)
        : NumberFormat.currency(locale: 'en_US', symbol: '$code ', decimalDigits: code == 'JPY' ? 0 : d);
    return nf.format(v);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _rawTextController.dispose();
    super.dispose();
  }

  /// Parse ulang dari teks mentah yang sudah diedit pengguna.
  void _reparse() {
    final c = context.palette;
    final currency = CurrencyRatesService.detectCurrency(_rawTextController.text);
    final re = ReceiptParser.parseText(_rawTextController.text, currency: currency ?? 'IDR');
    setState(() {
      _currency = currency;
      _parsed = re;
      _items = List.of(re.items);
      if (_titleController.text.trim().isEmpty) {
        _titleController.text = re.merchantName;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${tr('ocr_preview_reparsed')} (${re.items.length} item)',
          style: TextStyle(color: c.background),
        ),
        backgroundColor: c.onSurface,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _addItem() {
    _showItemEditor();
  }

  void _editItem(int index) {
    _showItemEditor(item: _items[index], index: index);
  }

  void _removeItem(int index) {
    setState(() => _items.removeAt(index));
  }

  Future<void> _showItemEditor({ReceiptItem? item, int? index}) async {
    final nameController = TextEditingController(text: item?.name ?? '');
    final priceController = TextEditingController(
      text: item == null ? '' : item.price.toStringAsFixed(0),
    );
    final qtyController = TextEditingController(
      text: item == null ? '1' : item.quantity.toString(),
    );

    final result = await showDialog<ReceiptItem>(
      context: context,
      builder: (dialogContext) {
        final c = context.palette;
        return AlertDialog(
          backgroundColor: c.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: c.borderBlack, width: 2),
        ),
        title: Text(
          item == null ? tr('ocr_preview_add_item') : tr('ocr_preview_edit_item'),
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: tr('create_item_name'),
                  filled: true,
                  fillColor: Colors.white,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: c.borderBlack, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: tr('edit_item_price'),
                        filled: true,
                        fillColor: Colors.white,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: c.borderBlack, width: 1.5),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: qtyController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: tr('edit_item_qty'),
                        filled: true,
                        fillColor: Colors.white,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: c.borderBlack, width: 1.5),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(tr('common_batal'), style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          NeoButton(
            onTap: () {
              final name = nameController.text.trim();
              final price = double.tryParse(priceController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
              final qty = int.tryParse(qtyController.text.trim()) ?? 1;
              if (name.isEmpty || price <= 0) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(
                    content: Text(tr('create_invalid_input'), style: TextStyle(color: c.background)),
                    backgroundColor: c.error,
                  ),
                );
                return;
              }
              Navigator.pop(
                dialogContext,
                ReceiptItem(
                  id: item?.id ?? 'item_${DateTime.now().millisecondsSinceEpoch}',
                  name: name,
                  price: price,
                  quantity: qty < 1 ? 1 : qty,
                  assignedMemberIds: item?.assignedMemberIds ?? [],
                ),
              );
            },
            backgroundColor: c.primaryContainer,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Text(tr('common_ok'), style: const TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      );
      },
    );

    if (result != null) {
      setState(() {
        if (index != null && index < _items.length) {
          _items[index] = result;
        } else {
          _items.add(result);
        }
      });
    }
  }

  double get _subtotal => _items.fold(0.0, (s, i) => s + (i.price * i.quantity));

  /// Menampilkan gambar hasil scan/crop dalam layar penuh (bisa zoom).
  void _showImageFullScreen() {
    final bytes = widget.imageBytes;
    if (bytes == null) return;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.only(
          left: 12,
          right: 12,
          top: MediaQuery.of(context).padding.top + 12,
          bottom: MediaQuery.of(context).padding.bottom + 12,
        ),
        child: SizedBox(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height * 0.85,
          child: Stack(
            children: [
              Positioned.fill(
                child: InteractiveViewer(
                  maxScale: 5,
                  child: Center(
                    child: Image.memory(bytes, fit: BoxFit.contain),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () => Navigator.pop(dialogContext),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirm() {
    final title = _titleController.text.trim().isEmpty ? 'Struk Baru' : _titleController.text.trim();
    // Struk mata uang asing → konversi semua nilai ke IDR (kurs hari ini)
    // saat disimpan, agar seluruh alur split bill tetap dalam rupiah.
    final rates = CurrencyRatesService.instance;
    final items = _isForeign
        ? _items
            .map((i) => ReceiptItem(
                  id: i.id,
                  name: i.name,
                  price: rates.toIdr(i.price, _currency!),
                  quantity: i.quantity,
                  assignedMemberIds: i.assignedMemberIds,
                ))
            .toList()
        : _items;
    final subtotalIdr = _isForeign ? rates.toIdr(_subtotal, _currency!) : _subtotal;
    final taxIdr = _isForeign ? rates.toIdr(_parsed.tax, _currency!) : _parsed.tax;
    final serviceIdr = _isForeign ? rates.toIdr(_parsed.serviceCharge, _currency!) : _parsed.serviceCharge;
    widget.onConfirm(
      ParsedReceiptResult(
        merchantName: title,
        subtotal: subtotalIdr,
        tax: taxIdr,
        serviceCharge: serviceIdr,
        totalAmount: subtotalIdr + taxIdr + serviceIdr,
        items: items,
      ),
    );
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
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: c.surfaceContainerLowest,
                        shape: BoxShape.circle,
                        border: Border.all(color: c.borderBlack, width: 2),
                      ),
                      child: Icon(Icons.close, color: c.onSurface),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr('ocr_preview_title'),
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        Text(
                          '${tr('ocr_preview_item_count')}: ${_items.length}',
                          style: TextStyle(fontSize: 12, color: c.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Divider(color: c.borderBlack, height: 1, thickness: 2),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Pratinjau gambar hasil scan / crop
                    if (widget.imageBytes != null) ...[
                      Text(tr('ocr_preview_image'), style: Theme.of(context).textTheme.labelLarge),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: _showImageFullScreen,
                        child: Container(
                          width: double.infinity,
                          constraints: const BoxConstraints(maxHeight: 210),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: c.borderBlack, width: 1.5),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image.memory(
                                widget.imageBytes!,
                                fit: BoxFit.contain,
                                height: 170,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.zoom_in_rounded, size: 14, color: Colors.white70),
                                  const SizedBox(width: 4),
                                  Text(
                                    tr('ocr_preview_image_tap'),
                                    style: const TextStyle(fontSize: 11, color: Colors.white70),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],

                    // Nama struk
                    Text(tr('create_name'), style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        hintText: tr('create_name_hint'),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: c.borderBlack, width: 2),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: c.secondary, width: 2.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Teks mentah OCR + parse ulang
                    Row(
                      children: [
                        Expanded(
                          child: Text(tr('ocr_preview_raw'), style: Theme.of(context).textTheme.labelLarge),
                        ),
                        GestureDetector(
                          onTap: _reparse,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: c.secondaryContainer,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: c.borderBlack, width: 1.5),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.refresh_rounded, size: 14, color: c.borderBlack),
                                const SizedBox(width: 4),
                                Text(
                                  tr('ocr_preview_reparse'),
                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Container(
                      decoration: BoxDecoration(
                        color: c.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: c.outlineVariant, width: 1.5),
                      ),
                      child: TextField(
                        controller: _rawTextController,
                        maxLines: 7,
                        minLines: 4,
                        style: const TextStyle(fontSize: 12, fontFamily: 'monospace', height: 1.4),
                        decoration: InputDecoration(
                          hintText: tr('ocr_preview_raw_hint'),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Banner kurs: struk dalam mata uang asing → setara IDR
                    if (_isForeign) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: c.primaryContainer,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: c.borderBlack, width: 2),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.currency_exchange_rounded, size: 18, color: c.onPrimaryContainer),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    tr('ocr_preview_foreign_currency').replaceAll('{code}', _currency!),
                                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              CurrencyRatesService.instance.formatRate(_currency!),
                              style: TextStyle(fontSize: 12, color: c.onSurfaceVariant),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_fmt(_subtotal)} ≈ ${formatCurrency(CurrencyRatesService.instance.toIdr(_subtotal, _currency!))}',
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],

                    // Daftar item hasil parse
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${tr('ocr_preview_items')} (${_items.length})', style: Theme.of(context).textTheme.labelLarge),
                        GestureDetector(
                          onTap: _addItem,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: c.primaryContainer,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: c.borderBlack, width: 1.5),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add_rounded, size: 14, color: c.borderBlack),
                                const SizedBox(width: 4),
                                Text(
                                  tr('ocr_preview_add_item'),
                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_items.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: c.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: c.outlineVariant),
                        ),
                        child: Text(
                          tr('create_no_items'),
                          style: TextStyle(fontSize: 11, color: c.onSurfaceVariant),
                        ),
                      )
                    else
                      ..._items.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final item = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: c.surfaceContainerLowest,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: c.borderBlack, width: 1.5),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.name,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${item.quantity}x • ${_fmt(item.price)}',
                                        style: TextStyle(fontSize: 11, color: c.onSurfaceVariant),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  _fmt(item.price * item.quantity),
                                  style: TextStyle(fontWeight: FontWeight.w800, color: c.primary, fontSize: 13),
                                ),
                                const SizedBox(width: 4),
                                GestureDetector(
                                  onTap: () => _editItem(idx),
                                  child: Padding(
                                    padding: const EdgeInsets.all(4),
                                    child: Icon(Icons.edit_rounded, size: 16, color: c.onSurfaceVariant),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => _removeItem(idx),
                                  child: Padding(
                                    padding: const EdgeInsets.all(4),
                                    child: Icon(Icons.delete_outline, size: 16, color: c.error),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),

                    if (_items.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: c.secondaryContainer.withAlpha(70),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: c.borderBlack, width: 1.5),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(tr('create_subtotal'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                            Text(
                              _fmt(_subtotal),
                              style: TextStyle(fontWeight: FontWeight.w800, color: c.primary, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // CTA Lanjutkan
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
              child: NeoButton(
                onTap: _confirm,
                width: double.infinity,
                backgroundColor: c.primaryContainer,
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_rounded, color: c.onPrimaryContainer, size: 20),
                    const SizedBox(width: 6),
                    Text(
                      tr('ocr_preview_continue'),
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: c.onPrimaryContainer),
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
}
