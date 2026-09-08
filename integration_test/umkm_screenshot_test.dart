import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fairsplit/main.dart' as app;
import 'package:fairsplit/core/services/gemini_service.dart';
import 'package:fairsplit/core/services/inventory_service.dart';
import 'package:fairsplit/core/state/transaksi_umkm_store.dart';
import 'package:fairsplit/core/utils/receipt_parser.dart';
import 'package:fairsplit/features/ocr_scanner/screens/ocr_annotated_screen.dart';
import 'package:fairsplit/features/ocr_scanner/services/ocr_service.dart';
import 'package:fairsplit/features/umkm/screens/umkm_transaksi_list_screen.dart';

/// Screenshot capture untuk layar-layar UMKM (presentasi).
/// Jalankan: flutter drive --driver=test_driver/integration_test.dart \
///   --target=integration_test/umkm_screenshot_test.dart -d emulator-5554
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  /// Tunggu sampai [finder] ada di tree (IndexedStack menyimpan semua tab
  /// offstage, jadi eksistensi di tree = screen sudah dibangun).
  Future<void> waitFor(WidgetTester tester, Finder finder,
      {int tries = 60}) async {
    for (var i = 0; i < tries; i++) {
      await tester.pump(const Duration(milliseconds: 250));
      if (tester.any(finder)) return;
    }
    throw StateError('Tidak menemukan target dalam waktu tunggu');
  }

  /// Indeks IndexedStack saat ini (= tab aktif di Mode UMKM).
  int currentTab(WidgetTester tester) {
    final stack = tester.widget<IndexedStack>(find.byType(IndexedStack));
    return stack.index ?? 0;
  }

  /// Buka drawer lewat handle tepi kiri (self-healing: retry bila meleset).
  Future<void> openDrawer(WidgetTester tester) async {
    for (var attempt = 0; attempt < 3; attempt++) {
      await tester.pump(const Duration(milliseconds: 300));
      if (tester.any(find.byType(Drawer))) return; // sudah terbuka
      if (!tester.any(find.byIcon(Icons.menu_rounded))) {
        await tester.pump(const Duration(milliseconds: 500));
        continue; // drawer sedang menutup, tunggu sebentar
      }
      await tester.tap(find.byIcon(Icons.menu_rounded), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 700));
      if (tester.any(find.byType(Drawer))) return;
    }
    throw StateError('Gagal membuka drawer');
  }

  /// Pilih tab drawer sesuai label, dengan verifikasi indeks tab aktif.
  Future<void> goToTab(WidgetTester tester, String label, int expectedIndex) async {
    for (var attempt = 0; attempt < 3; attempt++) {
      await openDrawer(tester);
      final item = find.descendant(
        of: find.byType(Drawer),
        matching: find.text(label),
      );
      if (tester.any(item)) {
        await tester.tap(item);
        await tester.pump(const Duration(milliseconds: 700));
        await tester.pump(const Duration(milliseconds: 400));
        if (currentTab(tester) == expectedIndex) return;
      }
    }
    throw StateError('Gagal pindah ke tab: $label');
  }

  bool surfaceConverted = false;

  Future<void> capture(WidgetTester tester, String name) async {
    if (!surfaceConverted) {
      // Android: konversi Flutter surface ke image view agar takeScreenshot
      // menangkap konten Flutter (harus dipanggil sekali sebelum screenshot).
      await binding.convertFlutterSurfaceToImage();
      await tester.pump(const Duration(milliseconds: 500));
      surfaceConverted = true;
    }
    await tester.pump(const Duration(milliseconds: 500));
    await binding.takeScreenshot(name);
  }

  testWidgets('capture UMKM screens', (tester) async {
    // Mulai langsung dalam Mode UMKM dengan data demo ter-seed.
    SharedPreferences.setMockInitialValues({
      'settings_seen_tutorial_version': '2',
      'settings_seen_scan_tutorial': '1',
      'settings_seen_onboarding': true,
      'settings_app_mode': 1, // AppMode.umkm
      'settings_language': 'id',
      'settings_currency': 'IDR',
      'settings_dark_mode': false,
      'settings_use_ai_enhancement': false,
    });

    GeminiService.instance.demoMode = true;
    await TransaksiUmkmStore.instance.loadDemo();
    await InventoryService.instance.loadDemo();

    app.main();

    // Tab awal UMKM = Riwayat Transaksi.
    await waitFor(tester, find.text('Riwayat Transaksi'));

    // Tutup tooltip sidebar bila masih tampil.
    if (tester.any(find.text('Geser dari sini untuk buka menu'))) {
      await tester.tap(find.text('Geser dari sini untuk buka menu'));
      await tester.pump(const Duration(milliseconds: 500));
    }

    // 1. Riwayat Transaksi
    await capture(tester, 'umkm-01-riwayat');

    // 2. Scanner (buka via drawer → item 'Scan'; overlay full-screen)
    await openDrawer(tester);
    await tester.tap(
      find.descendant(of: find.byType(Drawer), matching: find.text('Scan')),
    );
    await tester.pump(const Duration(milliseconds: 900));
    await waitFor(tester, find.byIcon(Icons.camera_alt_rounded));
    await capture(tester, 'umkm-02-scanner');
    // Tutup scanner (tombol close di kiri atas)
    await tester.tap(find.byIcon(Icons.close));
    await tester.pump(const Duration(milliseconds: 700));
    await waitFor(tester, find.text('Riwayat Transaksi'));

    // 3. Drawer terbuka (di layar Riwayat)
    await openDrawer(tester);
    await waitFor(
      tester,
      find.descendant(of: find.byType(Drawer), matching: find.text('Omzet')),
    );
    await capture(tester, 'umkm-03-drawer');
    // Tutup drawer dengan memilih tab yang sama (Riwayat)
    await tester.tap(
      find.descendant(of: find.byType(Drawer), matching: find.text('Riwayat')),
    );
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump(const Duration(milliseconds: 400));

    // 4. Dashboard Omzet
    await goToTab(tester, 'Omzet', 1);
    await tester.pump(const Duration(seconds: 2)); // tunggu briefing pagi (demo)
    await capture(tester, 'umkm-04-dashboard');

    // 5. Kasir Dialog (dari tombol Test di dashboard)
    await waitFor(tester, find.text('Test'));
    await tester.tap(find.text('Test'));
    await waitFor(tester, find.text('Metode Bayar'));
    await capture(tester, 'umkm-05-kasir');

    // Tutup bottom sheet (modal bisa full-screen → pop route langsung).
    await tester.binding.handlePopRoute();
    await tester.pump(const Duration(milliseconds: 700));

    // 6. Laporan Shift
    await goToTab(tester, 'Laporan', 3);
    await capture(tester, 'umkm-06-laporan');

    // 7. Inventaris (Stok) — tab Semua Item
    await goToTab(tester, 'Stok', 4);
    await capture(tester, 'umkm-07-stok');

    // 8. Inventaris — tab Stok Rendah
    await tester.tap(find.widgetWithText(Tab, 'Stok Rendah'));
    await tester.pump(const Duration(milliseconds: 700));
    await capture(tester, 'umkm-08-stok-rendah');

    // 9. Insight Bisnis (AI)
    await goToTab(tester, 'Insight', 5);
    await tester.pump(const Duration(seconds: 2)); // tunggu hasil AI demo
    await capture(tester, 'umkm-09-insight');

    // 10. Pengaturan (Mode UMKM) — label drawer-nya 'Settings' di l10n.
    await goToTab(tester, 'Settings', 6);
    await capture(tester, 'umkm-10-pengaturan');

    // 11. Detail Transaksi (buka kartu transaksi pertama di Riwayat)
    await goToTab(tester, 'Riwayat', 0);
    await waitFor(
      tester,
      find.descendant(
        of: find.byType(UmkmTransaksiListScreen),
        matching: find.text('Kedai Kopi Nusantara'),
      ),
    );
    final firstCard = find
        .descendant(
          of: find.byType(UmkmTransaksiListScreen),
          matching: find.text('Kedai Kopi Nusantara'),
        )
        .first;
    await tester.tap(firstCard);
    await tester.pump(const Duration(milliseconds: 700));
    await waitFor(tester, find.text('Metode Pembayaran'));
    await capture(tester, 'umkm-11-detail-transaksi');
    // Kembali ke Riwayat (agar test berakhir di state normal)
    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pump(const Duration(milliseconds: 700));

    // 12. Pratinjau hasil OCR (scan simulasi → layar preview teks)
    await openDrawer(tester);
    await tester.tap(
      find.descendant(of: find.byType(Drawer), matching: find.text('Scan')),
    );
    await tester.pump(const Duration(milliseconds: 900));
    await waitFor(tester, find.byIcon(Icons.camera_alt_rounded));
    await tester.tap(find.byIcon(Icons.camera_alt_rounded)); // shutter → simulasi
    await waitFor(tester, find.text('Lanjutkan'));
    await capture(tester, 'umkm-12-ocr-preview');
    // Lanjutkan → KasirDialog terbuka dari hasil scan; tutup lagi.
    await tester.tap(find.text('Lanjutkan'));
    await waitFor(tester, find.text('Metode Bayar'));
    await tester.binding.handlePopRoute();
    await tester.pump(const Duration(milliseconds: 700));

    // 13. Demo Mode (dari Pengaturan UMKM)
    await goToTab(tester, 'Settings', 6);
    await tester.ensureVisible(find.text('Demo Mode'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Demo Mode'));
    await waitFor(tester, find.text('Mulai Demo'));
    await capture(tester, 'umkm-13-demo-mode');
    await tester.binding.handlePopRoute();
    await tester.pump(const Duration(milliseconds: 700));

    // 14. Pratinjau OCR Annotated (gambar struk + kotak label) — jalur
    // nyata: fixture struk → ML Kit (dengan bounding box) → layar label.
    try {
      final bytes =
          (await rootBundle.load('integration_test/fixtures/receipt.png'))
              .buffer
              .asUint8List();
      final file = File('${Directory.systemTemp.path}/receipt_fixture.png');
      await file.writeAsBytes(bytes);
      final ocrResult = await OcrService.recognizeWithBoxes(file.path);
      final parsed = ReceiptParser.parseText(ocrResult.text);
      // Konteks di dalam route (bukan MaterialApp) agar punya Navigator.
      final appCtx = tester.element(find.byType(Scaffold).first);
      // ignore: use_build_context_synchronously
      Navigator.of(appCtx).push(
        MaterialPageRoute(
          builder: (_) => OcrAnnotatedScreen(
            imageBytes: bytes,
            ocrResult: ocrResult,
            rawText: ocrResult.text,
            parsed: parsed,
            onConfirm: (_) {},
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 1000));
      await waitFor(tester, find.text('Hasil Scan OCR'));
      await tester.pump(const Duration(seconds: 1)); // decode gambar + label
      await capture(tester, 'umkm-14-ocr-annotated');
      await tester.binding.handlePopRoute();
      await tester.pump(const Duration(milliseconds: 700));
    } catch (e) {
      debugPrint('SKIP umkm-14-ocr-annotated (ML Kit tidak tersedia): $e');
    }
  });
}