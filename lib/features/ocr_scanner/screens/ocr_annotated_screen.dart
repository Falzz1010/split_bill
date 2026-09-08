import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../core/models/split_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/receipt_parser.dart';
import '../../../shared/widgets/neo_button.dart';
import '../services/ocr_service.dart';

class _LabelData {
  Rect rect;
  int? itemIndex;
  String text;
  _LabelData({required this.rect, this.itemIndex, this.text = ''});
}

class OcrAnnotatedScreen extends StatefulWidget {
  final Uint8List imageBytes;
  final OcrResult ocrResult;
  final String rawText;
  final ParsedReceiptResult parsed;
  final void Function(ParsedReceiptResult parsed) onConfirm;

  const OcrAnnotatedScreen({
    super.key,
    required this.imageBytes,
    required this.ocrResult,
    required this.rawText,
    required this.parsed,
    required this.onConfirm,
  });

  @override
  State<OcrAnnotatedScreen> createState() => _OcrAnnotatedScreenState();
}

class _OcrAnnotatedScreenState extends State<OcrAnnotatedScreen> {
  late List<ReceiptItem> _items;
  late String _merchantName;
  late TextEditingController _merchantController;
  ui.Image? _decodedImage;
  bool _imageDecoding = true;
  late List<_LabelData> _labels;
  final GlobalKey _imageKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _items = List.of(widget.parsed.items);
    _merchantName = widget.parsed.merchantName;
    _merchantController = TextEditingController(text: _merchantName);
    _labels = [];
    _decodeImage();
    _buildLabelsFromOcr();
  }

  @override
  void dispose() {
    _merchantController.dispose();
    super.dispose();
  }

  Future<void> _decodeImage() async {
    try {
      final codec = await ui.instantiateImageCodec(widget.imageBytes);
      final frame = await codec.getNextFrame();
      if (mounted) setState(() { _decodedImage = frame.image; _imageDecoding = false; });
    } catch (_) {
      if (mounted) setState(() => _imageDecoding = false);
    }
  }

  void _buildLabelsFromOcr() {
    final allLines = widget.ocrResult.blocks.expand((b) => b.lines).toList();
    _labels = [];
    final matchedLines = <int>{};
    for (var i = 0; i < _items.length; i++) {
      final nameLower = _items[i].name.toLowerCase();
      for (var j = 0; j < allLines.length; j++) {
        if (matchedLines.contains(j)) continue;
        final lineText = allLines[j].text.toLowerCase();
        if (lineText.contains(nameLower) || nameLower.contains(lineText)) {
          _labels.add(_LabelData(rect: allLines[j].boundingBox, itemIndex: i, text: allLines[j].text));
          matchedLines.add(j);
          break;
        }
      }
    }
    for (var j = 0; j < allLines.length; j++) {
      if (matchedLines.contains(j)) continue;
      final line = allLines[j];
      if (line.boundingBox.width < 20 || line.boundingBox.height < 10) continue;
      _labels.add(_LabelData(rect: line.boundingBox, itemIndex: null, text: line.text));
    }
  }

  String _fmt(double v) => formatCurrency(v);

  void _editItem(int index) async {
    final result = await _showItemEditor(item: _items[index]);
    if (result != null) setState(() => _items[index] = result);
  }

  void _removeItem(int index) {
    _labels.removeWhere((l) => l.itemIndex == index);
    for (final l in _labels) {
      if (l.itemIndex != null && l.itemIndex! > index) l.itemIndex = l.itemIndex! - 1;
    }
    setState(() => _items.removeAt(index));
  }

  void _addItem({Offset? tapPosition}) async {
    final result = await _showItemEditor();
    if (result != null) {
      final idx = _items.length;
      setState(() {
        _items.add(result);
        if (tapPosition != null) {
          _labels.add(_LabelData(
            rect: Rect.fromLTWH(tapPosition.dx - 60, tapPosition.dy - 12, 120, 24),
            itemIndex: idx, text: result.name,
          ));
        } else {
          _labels.add(_LabelData(rect: Rect.zero, itemIndex: idx, text: result.name));
        }
      });
    }
  }

  void _deleteLabel(int labelIdx) {
    final label = _labels[labelIdx];
    if (label.itemIndex != null && label.itemIndex! < _items.length) {
      _showDeleteLabelDialog(labelIdx);
    } else {
      setState(() => _labels.removeAt(labelIdx));
    }
  }

  void _showDeleteLabelDialog(int labelIdx) {
    final label = _labels[labelIdx];
    final itemName = label.itemIndex != null && label.itemIndex! < _items.length
        ? _items[label.itemIndex!].name : label.text;
    showDialog(
      context: context,
      builder: (ctx) {
        final c = ctx.palette;
        return AlertDialog(
          backgroundColor: c.surfaceContainerLowest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: c.borderBlack, width: 2),
          ),
          title: const Text('Hapus Label', style: TextStyle(fontWeight: FontWeight.w800)),
          content: Text('Hapus label "$itemName" dari gambar?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                setState(() => _labels.removeAt(labelIdx));
              },
              child: Text('Label Saja', style: TextStyle(color: c.error, fontWeight: FontWeight.bold)),
            ),
            if (label.itemIndex != null && label.itemIndex! < _items.length)
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  final idx = label.itemIndex!;
                  _removeItem(idx);
                },
                child: Text('Label + Item', style: TextStyle(color: c.error, fontWeight: FontWeight.w900)),
              ),
          ],
        );
      },
    );
  }

  void _onImageTap(TapDownDetails details) {
    final box = _imageKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final localPos = box.globalToLocal(details.globalPosition);
    for (final label in _labels) {
      if (label.rect.contains(localPos)) return;
    }
    _addItem(tapPosition: localPos);
  }

  void _confirm() {
    final subtotal = _items.fold(0.0, (s, i) => s + (i.price * i.quantity));
    widget.onConfirm(ParsedReceiptResult(
      merchantName: _merchantName.isEmpty ? 'Struk Baru' : _merchantName,
      subtotal: subtotal,
      tax: widget.parsed.tax,
      serviceCharge: widget.parsed.serviceCharge,
      totalAmount: subtotal + widget.parsed.tax + widget.parsed.serviceCharge,
      items: _items,
    ));
  }

  Future<ReceiptItem?> _showItemEditor({ReceiptItem? item}) async {
    final nameCtrl = TextEditingController(text: item?.name ?? '');
    final priceCtrl = TextEditingController(text: item == null ? '' : item.price.toStringAsFixed(0));
    final qtyCtrl = TextEditingController(text: item == null ? '1' : item.quantity.toString());
    return showDialog<ReceiptItem>(
      context: context,
      builder: (ctx) {
        final c = ctx.palette;
        return AlertDialog(
          backgroundColor: c.surfaceContainerLowest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: c.borderBlack, width: 2),
          ),
          title: Text(item == null ? 'Tambah Item' : 'Edit Item',
              style: const TextStyle(fontWeight: FontWeight.w800)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, autofocus: true,
                  decoration: InputDecoration(labelText: 'Nama Item', filled: true, fillColor: Colors.white,
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: c.borderBlack, width: 1.5))),
                ),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: TextField(controller: priceCtrl, keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: 'Harga (Rp)', filled: true, fillColor: Colors.white,
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: c.borderBlack, width: 1.5))),
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: TextField(controller: qtyCtrl, keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: 'Qty', filled: true, fillColor: Colors.white,
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: c.borderBlack, width: 1.5))),
                  )),
                ]),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal', style: TextStyle(fontWeight: FontWeight.bold))),
            NeoButton(
              onTap: () {
                final name = nameCtrl.text.trim();
                final price = double.tryParse(priceCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
                final qty = int.tryParse(qtyCtrl.text.trim()) ?? 1;
                if (name.isEmpty || price <= 0) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: const Text('Nama & harga harus diisi'), backgroundColor: c.error));
                  return;
                }
                Navigator.pop(ctx, ReceiptItem(
                  id: item?.id ?? 'item_${DateTime.now().millisecondsSinceEpoch}',
                  name: name, price: price, quantity: qty < 1 ? 1 : qty,
                  assignedMemberIds: item?.assignedMemberIds ?? [],
                ));
              },
              backgroundColor: c.primaryContainer,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: const Text('OK', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBboxOverlay(double scale, Color c) {
    final colors = [Colors.green, Colors.blue, Colors.orange, Colors.purple, Colors.teal];
    return Stack(
      children: [
        ...List.generate(_labels.length, (i) {
          final label = _labels[i];
          final r = label.rect;
          if (r == Rect.zero) return const SizedBox.shrink();
          final isItem = label.itemIndex != null;
          final color = isItem ? colors[i % colors.length] : Colors.red.shade400;
          return Positioned(
            left: r.left * scale, top: r.top * scale,
            width: r.width * scale, height: r.height * scale,
            child: GestureDetector(
              onTap: isItem && label.itemIndex! < _items.length ? () => _editItem(label.itemIndex!) : null,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: color.withAlpha(220), width: 2),
                  borderRadius: BorderRadius.circular(3),
                  color: color.withAlpha(25),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: 0, left: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 0),
                        decoration: BoxDecoration(
                          color: color, borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(2), bottomRight: Radius.circular(4)),
                        ),
                        child: Text(
                          isItem && label.itemIndex! < _items.length
                              ? '${_items[label.itemIndex!].name} ${_fmt(_items[label.itemIndex!].price)}'
                              : label.text,
                          style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    Positioned(
                      top: -4, right: -4,
                      child: GestureDetector(
                        onTap: () => _deleteLabel(i),
                        child: Container(
                          width: 18, height: 18,
                          decoration: BoxDecoration(
                            color: Colors.red, shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                          child: const Icon(Icons.close, size: 10, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final imgW = _decodedImage?.width.toDouble() ?? 300;
    final imgH = _decodedImage?.height.toDouble() ?? 400;

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(color: c.surfaceContainerLowest, shape: BoxShape.circle,
                        border: Border.all(color: c.borderBlack, width: 2)),
                      child: Icon(Icons.close, color: c.onSurface),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Hasil Scan OCR',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                        Text('${_items.length} item, ${_labels.length} label',
                            style: TextStyle(fontSize: 12, color: c.onSurfaceVariant)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Divider(color: c.borderBlack, height: 1, thickness: 2),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Gambar Struk', style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        key: _imageKey,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.black, borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: c.borderBlack, width: 1.5),
                        ),
                        child: _imageDecoding
                            ? const Padding(padding: EdgeInsets.all(40),
                                child: Center(child: CircularProgressIndicator()))
                            : LayoutBuilder(
                                builder: (context, constraints) {
                                  final displayW = constraints.maxWidth;
                                  final scale = displayW / imgW;
                                  final displayH = imgH * scale;
                                  return GestureDetector(
                                    onTapDown: _onImageTap,
                                    child: SizedBox(
                                      width: displayW, height: displayH,
                                      child: Stack(
                                        children: [
                                          Positioned.fill(
                                            child: Image.memory(widget.imageBytes, fit: BoxFit.fill)),
                                          _buildBboxOverlay(scale, c.primary),
                                          Positioned(
                                            top: 4, right: 4,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.black54, borderRadius: BorderRadius.circular(8)),
                                              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                                                Icon(Icons.add_circle_outline, size: 10, color: Colors.white70),
                                                SizedBox(width: 4),
                                                Text('Tap area kosong = tambah label',
                                                    style: TextStyle(color: Colors.white70, fontSize: 8)),
                                              ]),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.info_outline, size: 10, color: c.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text('Tap label = edit, X = hapus, tap kosong = tambah',
                            style: TextStyle(fontSize: 10, color: c.onSurfaceVariant)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text('Nama Toko', style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _merchantController,
                      onChanged: (v) => _merchantName = v,
                      decoration: InputDecoration(
                        hintText: 'Nama toko / merchant', filled: true, fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: c.borderBlack, width: 2)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: c.secondary, width: 2.5)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Item (${_items.length})', style: Theme.of(context).textTheme.labelLarge),
                        GestureDetector(
                          onTap: () => _addItem(),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: c.primaryContainer, borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: c.borderBlack, width: 1.5)),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              Icon(Icons.add_rounded, size: 14, color: c.borderBlack),
                              const SizedBox(width: 4),
                              const Text('Tambah', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                            ]),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_items.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16), width: double.infinity,
                        decoration: BoxDecoration(color: c.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(14), border: Border.all(color: c.outlineVariant)),
                        child: const Text('Belum ada item. Tap gambar atau tombol "Tambah".',
                            style: TextStyle(fontSize: 12)),
                      )
                    else
                      ..._items.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final item = entry.value;
                        final hasLabel = _labels.any((l) => l.itemIndex == idx);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: GestureDetector(
                            onTap: () => _editItem(idx),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: hasLabel ? c.primaryContainer.withAlpha(40) : c.surfaceContainerLowest,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: hasLabel ? c.primary : c.borderBlack,
                                  width: hasLabel ? 2 : 1.5)),
                              child: Row(
                                children: [
                                  Container(
                                    width: 24, height: 24,
                                    decoration: BoxDecoration(
                                      color: hasLabel ? Colors.green : c.outlineVariant, shape: BoxShape.circle),
                                    child: Icon(hasLabel ? Icons.check : Icons.edit_rounded,
                                        size: 14, color: Colors.white)),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(item.name,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                            maxLines: 1, overflow: TextOverflow.ellipsis),
                                        Text('${item.quantity}x \u2022 ${_fmt(item.price)}',
                                            style: TextStyle(fontSize: 11, color: c.onSurfaceVariant)),
                                      ],
                                    ),
                                  ),
                                  Text(_fmt(item.price * item.quantity),
                                      style: TextStyle(fontWeight: FontWeight.w800, color: c.primary, fontSize: 13)),
                                  const SizedBox(width: 4),
                                  GestureDetector(
                                    onTap: () => _editItem(idx),
                                    child: Padding(
                                      padding: const EdgeInsets.all(4),
                                      child: Icon(Icons.edit_rounded, size: 16, color: c.onSurfaceVariant))),
                                  GestureDetector(
                                    onTap: () => _removeItem(idx),
                                    child: Padding(
                                      padding: const EdgeInsets.all(4),
                                      child: Icon(Icons.delete_outline, size: 16, color: c.error))),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    if (_items.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: c.secondaryContainer.withAlpha(70), borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: c.borderBlack, width: 1.5)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Subtotal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            Text(_fmt(_items.fold(0.0, (s, i) => s + (i.price * i.quantity))),
                                style: TextStyle(fontWeight: FontWeight.w800, color: c.primary, fontSize: 14)),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
              child: NeoButton(
                onTap: _items.isEmpty ? () {} : _confirm,
                width: double.infinity,
                backgroundColor: _items.isEmpty ? c.outlineVariant : c.primaryContainer,
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_rounded,
                        color: _items.isEmpty ? c.onSurfaceVariant : c.onPrimaryContainer, size: 20),
                    const SizedBox(width: 6),
                    Text('Lanjutkan (${_items.length} item)',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16,
                            color: _items.isEmpty ? c.onSurfaceVariant : c.onPrimaryContainer)),
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
