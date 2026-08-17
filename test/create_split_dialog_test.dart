import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fairsplit/core/models/split_model.dart';
import 'package:fairsplit/features/bill_editor/screens/create_split_dialog.dart';

void main() {
  Finder fieldWithHint(String hint) => find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.hintText == hint,
      );

  Widget buildHarness(Function(SplitBill) onCreateSplit) {
    return MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => CreateSplitDialog(onCreateSplit: onCreateSplit),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('tombol + menambahkan item ke daftar', (tester) async {
    await tester.pumpWidget(buildHarness((_) {}));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.enterText(fieldWithHint('Nama Menu (misal: Nasi Goreng)'), 'Nasi Goreng');
    await tester.enterText(fieldWithHint('Harga (35000)'), '35000');
    // Konten dialog bisa di-scroll, jadi pastikan tombol + terlihat dulu
    await tester.ensureVisible(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(find.text('Nasi Goreng'), findsOneWidget);
    expect(find.text('Rp 35.000'), findsNWidgets(2));
    expect(find.textContaining('Subtotal'), findsOneWidget);
  });

  testWidgets('CTA otomatis menyertakan input yang belum ditekan tombol +', (tester) async {
    SplitBill? created;
    await tester.pumpWidget(buildHarness((split) => created = split));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.enterText(fieldWithHint('Nama Menu (misal: Nasi Goreng)'), 'Es Teh Manis');
    await tester.enterText(fieldWithHint('Harga (35000)'), '12000');

    await tester.ensureVisible(find.text('Buat Split Manual Sekarang'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Buat Split Manual Sekarang'));
    await tester.pumpAndSettle();

    expect(created, isNotNull);
    expect(created!.items.length, 1);
    expect(created!.items.first.name, 'Es Teh Manis');
    expect(created!.items.first.price, 12000);
    // Konsisten dengan editor: PPN 11% + Service 10% dari subtotal.
    expect(created!.subtotal, 12000);
    expect(created!.tax, 1320); // 11%
    expect(created!.serviceCharge, 1200); // 10%
    expect(created!.totalAmount, 14520);
  });

  testWidgets('hasil onCreateSplit memuat semua item yang diinput', (tester) async {
    SplitBill? created;
    await tester.pumpWidget(buildHarness((split) => created = split));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.enterText(fieldWithHint('Nama Menu (misal: Nasi Goreng)'), 'Nasi Goreng');
    await tester.enterText(fieldWithHint('Harga (35000)'), '35000');
    // Konten dialog bisa di-scroll, jadi pastikan tombol + terlihat dulu
    await tester.ensureVisible(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    await tester.enterText(fieldWithHint('Nama Menu (misal: Nasi Goreng)'), 'Es Teh Manis');
    await tester.enterText(fieldWithHint('Harga (35000)'), '12000');

    await tester.ensureVisible(find.text('Buat Split Manual Sekarang'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Buat Split Manual Sekarang'));
    await tester.pumpAndSettle();

    expect(created, isNotNull);
    expect(created!.items.length, 2);
    expect(created!.items.first.name, 'Nasi Goreng');
    expect(created!.items.first.price, 35000);
    expect(created!.items.last.name, 'Es Teh Manis');
    expect(created!.items.last.price, 12000);
  });
}