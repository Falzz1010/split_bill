import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fairsplit/core/utils/receipt_parser.dart';
import 'package:fairsplit/features/ocr_scanner/screens/ocr_result_preview_screen.dart';

void main() {
  Widget buildHarness({
    required String rawText,
    required void Function(ParsedReceiptResult) onConfirm,
    Uint8List? imageBytes,
  }) {
    final parsed = ReceiptParser.parseText(rawText);
    return MaterialApp(
      home: OcrResultPreviewScreen(
        rawText: rawText,
        parsed: parsed,
        onConfirm: onConfirm,
        imageBytes: imageBytes,
      ),
    );
  }

  const receiptText = '''
Kopi Kenangan Senopati
1x Kopi Kenangan Mantan Large 28.000
2x Roti Coklat Klasik 30.000
1x Avocado Coffee Special 34.000
1x Toast Smoked Beef Cheese 38.000
Subtotal 130.000
PPN 10% 13.000
Service Charge 7.000
Grand Total 150.000
''';

  testWidgets('preview menampilkan item hasil parse dari teks OCR', (tester) async {
    await tester.pumpWidget(buildHarness(rawText: receiptText, onConfirm: (_) {}));
    await tester.pumpAndSettle();

    // Header preview + jumlah item
    expect(find.textContaining('Hasil Scan OCR'), findsOneWidget);
    expect(find.text('Item: 4'), findsOneWidget);

    // Semua item hasil parse tampil di daftar
    expect(find.text('Kopi Kenangan Mantan Large'), findsOneWidget);
    expect(find.text('Roti Coklat Klasik'), findsOneWidget);
    expect(find.text('Avocado Coffee Special'), findsOneWidget);
    expect(find.text('Toast Smoked Beef Cheese'), findsOneWidget);

    // Subtotal dihitung dari item (termasuk qty 2x Roti Coklat):
    // 28.000 + 2x30.000 + 34.000 + 38.000 = 160.000
    expect(find.text('Rp 160.000'), findsOneWidget);
  });

  testWidgets('tombol Lanjutkan mengembalikan hasil yang sudah dikoreksi', (tester) async {
    ParsedReceiptResult? confirmed;
    await tester.pumpWidget(
      buildHarness(rawText: receiptText, onConfirm: (r) => confirmed = r),
    );
    await tester.pumpAndSettle();

    // Edit nama struk, lalu Lanjutkan
    await tester.enterText(find.byType(TextField).first, 'Kopi Kenangan Cabang Baru');
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Lanjutkan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lanjutkan'));
    await tester.pumpAndSettle();

    expect(confirmed, isNotNull);
    expect(confirmed!.merchantName, 'Kopi Kenangan Cabang Baru');
    expect(confirmed!.items.length, 4);
    expect(confirmed!.items.first.name, 'Kopi Kenangan Mantan Large');
    expect(confirmed!.items.first.quantity, 1);
    expect(confirmed!.items.first.price, 28000);
    expect(confirmed!.items[1].quantity, 2);
    // Subtotal dari item: 28.000 + 2x30.000 + 34.000 + 38.000 = 160.000
    expect(confirmed!.subtotal, 160000);
    expect(confirmed!.tax, 13000);
    expect(confirmed!.serviceCharge, 7000);
    // Total = subtotal item + pajak + service
    expect(confirmed!.totalAmount, 160000 + 13000 + 7000);
  });

  testWidgets('parse ulang setelah mengedit teks mentah memperbarui daftar item', (tester) async {
    await tester.pumpWidget(buildHarness(rawText: receiptText, onConfirm: (_) {}));
    await tester.pumpAndSettle();

    // Ganti teks mentah: hapus 1 item, lalu Parse Ulang
    final edited = '''
Kopi Kenangan Senopati
1x Kopi Kenangan Mantan Large 28.000
Subtotal 28.000
PPN 10% 2.800
Grand Total 30.800
''';
    await tester.enterText(find.byType(TextField).at(1), edited);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Parse Ulang'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Parse Ulang'));
    await tester.pumpAndSettle();

    expect(find.text('Item: 1'), findsOneWidget);
    expect(find.text('Kopi Kenangan Mantan Large'), findsOneWidget);
    expect(find.text('Roti Coklat Klasik'), findsNothing);
  });

  testWidgets('gambar hasil crop ditampilkan sebagai pratinjau', (tester) async {
    // PNG 4x4 putih yang valid (dibuat dengan PIL)
    final bytes = Uint8List.fromList([
      137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73, 72, 68, 82, 0, 0, 0, 4, 0, 0, 0, 4, 8, 2, 0, 0, 0, 38, 147, 9, 41, 0, 0, 0, 19, 73, 68, 65, 84, 120, 156, 99, 252, 255, 255, 63, 3, 12, 48, 193, 89, 120, 57, 0, 150, 110, 3, 5, 237, 152, 199, 212, 0, 0, 0, 0, 73, 69, 78, 68, 174, 66, 96, 130,
    ]);

    await tester.pumpWidget(
      buildHarness(rawText: receiptText, onConfirm: (_) {}, imageBytes: bytes),
    );
    await tester.pumpAndSettle();

    expect(find.text('Gambar Hasil Scan'), findsOneWidget);
    expect(find.text('Ketuk untuk perbesar'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
  });
}
