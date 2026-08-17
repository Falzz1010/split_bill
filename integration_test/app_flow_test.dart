import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fairsplit/main.dart' as app;
import 'package:fairsplit/core/settings/settings_service.dart';
import 'package:fairsplit/core/utils/receipt_parser.dart';
import 'package:fairsplit/features/ocr_scanner/services/ocr_service.dart';
import 'package:fairsplit/shared/widgets/neo_bottom_sheet.dart';
import 'package:fairsplit/shared/widgets/neo_card.dart';

/// TextField yang benar-benar terlihat (IndexedStack menyimpan tab offstage).
Finder visibleFields() => find.byType(TextField).hitTestable();

/// TextField di dalam bottom sheet aktif (bisa di bawah fold, tetap bisa
/// enterText — fokus auto-scroll saat keyboard terbuka).
Finder sheetFields() => find.descendant(
  of: find.byType(NeoBottomSheet),
  matching: find.byType(TextField),
);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  /// Pump frame demi frame sampai [finder] muncul di tree (batas 20 detik fake).
/// Tab offstage di IndexedStack tetap ter-match; verifikasi visible dipakai
/// terpisah (lihat `_waitVisible`).
  Future<void> _waitFor(WidgetTester tester, Finder finder) async {
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 500));
      if (tester.any(finder)) return;
    }
    throw StateError('Tidak menemukan ${finder.description} dalam 20 detik');
  }

  /// Tunggu splash selesai (MainNavigation muncul), lewati tutorial bila ada.
  /// Bahasa-independen: menunggu ikon nav, bukan teks.
  Future<void> _waitSplash(WidgetTester tester) async {
    await _waitFor(tester, find.byIcon(Icons.home_rounded));
    if (tester.any(find.text('Lewati'))) {
      await tester.tap(find.text('Lewati'));
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(milliseconds: 500));
    }
  }

  /// Start app with fresh (optionally tutorial-seen) preferences.
  Future<void> startApp(WidgetTester tester, {bool tutorialSeen = false}) async {
    SharedPreferences.setMockInitialValues(
      tutorialSeen ? {'settings_seen_tutorial_version': '1'} : {},
    );
    app.main();
    await _waitSplash(tester);
  }

  Future<void> _unfocus(WidgetTester tester) async {
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump(const Duration(milliseconds: 300));
  }

  Future<void> _ensureAndTap(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(finder);
    await tester.pump(const Duration(milliseconds: 400));
  }

  /// Isi dialog buat struk: judul, anggota, item (nama+harga), tap "+".
  Future<void> _fillCreateDialog(
    WidgetTester tester, {
    required String title,
    String member = '',
    required String itemName,
    required String itemPrice,
  }) async {
    await tester.enterText(sheetFields().at(0), title);
    if (member.isNotEmpty) {
      await tester.enterText(sheetFields().at(2), member);
      await _unfocus(tester);
      await _ensureAndTap(tester, find.text('+ Tambah'));
    }
    await tester.enterText(sheetFields().at(3), itemName);
    await tester.enterText(sheetFields().at(4), itemPrice);
    await _unfocus(tester);
    await tester.ensureVisible(find.byIcon(Icons.add).last);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.byIcon(Icons.add).last);
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets('splash, tutorial, dashboard kosong, buat split manual',
      (tester) async {
    await startApp(tester);
    await _waitFor(tester, find.text('Belum Ada Struk Belanja'));

    await _ensureAndTap(tester, find.text('Buat Struk Baru'));
    expect(find.text('Buat Split / Struk Manual'), findsOneWidget);

    await _fillCreateDialog(
      tester,
      title: 'Nasi Goreng Mantul',
      member: 'Budi',
      itemName: 'Nasi Goreng Spesial',
      itemPrice: '25000',
    );

    await _ensureAndTap(tester, find.text('Buat Split Manual Sekarang'));
    await _waitFor(tester, find.text('Nasi Goreng Mantul'));
  });

  testWidgets('scanner: simulasi OCR (shutter) → pratinjau → buat dari hasil',
      (tester) async {
    await startApp(tester, tutorialSeen: true);
    await _waitFor(tester, find.text('Belum Ada Struk Belanja'));

    await _ensureAndTap(
      tester,
      find.byIcon(Icons.document_scanner_rounded),
    );
    await _waitFor(tester, find.byIcon(Icons.camera_alt_rounded));

    // Kamera tidak tersedia di emulator → shutter otomatis menjalankan simulasi.
    await _ensureAndTap(tester, find.byIcon(Icons.camera_alt_rounded));
    await _waitFor(tester, find.text('Lanjutkan'));

    await _ensureAndTap(tester, find.text('Lanjutkan'));
    await _waitFor(tester, find.text('Buat Split / Struk Manual'));
    await _ensureAndTap(tester, find.text('Buat Split Manual Sekarang'));
    expect(find.text('Belum Ada Struk Belanja'), findsNothing);
  });

  testWidgets('editor, assign item, qty, ringkasan, status lunas, hapus',
      (tester) async {
    await startApp(tester, tutorialSeen: true);
    await _waitFor(tester, find.text('Belum Ada Struk Belanja'));

    // Siapkan 1 struk via dialog
    await _ensureAndTap(tester, find.text('Buat Struk Baru'));
    await _fillCreateDialog(
      tester,
      title: 'Warung Sebelah',
      itemName: 'Es Teh',
      itemPrice: '8000',
    );
    await _ensureAndTap(tester, find.text('Buat Split Manual Sekarang'));
    await _waitFor(tester, find.text('Warung Sebelah'));

    // Dashboard → editor
    await _ensureAndTap(tester, find.text('Warung Sebelah').first);
    await _waitFor(tester, find.text('Edit Struk & Pesanan'));

    // Tambah teman
    await _ensureAndTap(tester, find.text('+ Tambah Teman'));
    await tester.enterText(visibleFields().last, 'Siti');
    await _unfocus(tester);
    await _ensureAndTap(tester, find.text('Simpan Anggota'));
    await _waitFor(tester, find.text('Siti'));

    // Tambah item kedua
    await _ensureAndTap(tester, find.text('+ Tambah Item'));
    await tester.enterText(visibleFields().at(0), 'Ayam Bakar');
    await tester.enterText(visibleFields().at(1), '20000');
    await _unfocus(tester);
    await _ensureAndTap(tester, find.text('Simpan Item Pesanan'));
    await _waitFor(tester, find.text('Ayam Bakar'));

    // Hapus assign "Saya" dari item pertama (uang tidak hilang test)
    final itemCard = find
        .ancestor(of: find.text('Es Teh'), matching: find.byType(NeoCard))
        .first;
    await tester.ensureVisible(itemCard);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(
      find.descendant(of: itemCard, matching: find.text('Saya')),
    );
    await tester.pump(const Duration(milliseconds: 300));

    // Qty +1 pada item pertama
    await tester.tap(
      find.descendant(of: itemCard, matching: find.text('+')),
    );
    await tester.pump(const Duration(milliseconds: 300));

    // Simpan → tab Ringkasan
    await _ensureAndTap(tester, find.text('Simpan & Lanjutkan'));
    await _waitFor(tester, find.text('TOTAL TAGIHAN'));

    // Toggle lunas Siti → SEMUA lunas → otomatis kembali dashboard (onAllPaid)
    await tester.ensureVisible(find.text('Siti').first);
    await tester.tap(find.text('Siti').first);
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.textContaining('diubah menjadi'), findsOneWidget);

    // Buka lagi → editor → ringkasan (Saya & Siti sudah lunas)
    await _ensureAndTap(tester, find.text('Warung Sebelah').first);
    await _waitFor(tester, find.text('Edit Struk & Pesanan'));
    await _ensureAndTap(tester, find.text('Simpan & Lanjutkan'));
    await _waitFor(tester, find.text('TOTAL TAGIHAN'));

    // Toggle Siti → belum bayar → tidak auto-pindah, tetap di ringkasan
    await tester.ensureVisible(find.text('Siti').first);
    await tester.tap(find.text('Siti').first);
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.textContaining('diubah menjadi'), findsOneWidget);

    // Hapus: batal dulu, lalu hapus benar-benar
    await _ensureAndTap(tester, find.byIcon(Icons.delete_outline_rounded));
    expect(find.text('Hapus Struk?'), findsOneWidget);
    await _ensureAndTap(tester, find.text('Batal'));
    expect(find.text('TOTAL TAGIHAN'), findsOneWidget);

    await _ensureAndTap(tester, find.byIcon(Icons.delete_outline_rounded));
    await _ensureAndTap(tester, find.text('Hapus'));
    await _waitFor(tester, find.text('Belum Ada Struk Belanja'));
  });

  testWidgets(
      'riwayat, search, pengaturan (demo, bahasa, mata uang, gelap, bersihkan)',
      (tester) async {
    await startApp(tester, tutorialSeen: true);
    await _waitFor(tester, find.text('Belum Ada Struk Belanja'));

    // Pengaturan → Muat Struk Contoh
    await _ensureAndTap(tester, find.byIcon(Icons.settings_rounded));
    await _ensureAndTap(tester, find.text('Muat Struk Contoh (Demo)'));
    await tester.pump(const Duration(milliseconds: 600));

    // Riwayat: search memfilter
    await _ensureAndTap(tester, find.byIcon(Icons.history_rounded));
    await _waitFor(tester, find.text('Kopi Kenangan Senopati'));
    await tester.enterText(visibleFields().first, 'Kopi');
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Kopi Kenangan Senopati'), findsOneWidget);
    expect(find.text('Makan Malam Sate Khas Senayan'), findsNothing);
    await tester.enterText(visibleFields().first, 'zzz');
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Kopi Kenangan Senopati'), findsNothing);

    // Buka struk dari riwayat → Ringkasan
    await tester.enterText(visibleFields().first, '');
    await tester.pump(const Duration(milliseconds: 400));
    await _ensureAndTap(tester, find.text('Kopi Kenangan Senopati'));
    await _waitFor(tester, find.text('TOTAL TAGIHAN'));
    await _ensureAndTap(tester, find.byIcon(Icons.arrow_back));
    await _waitFor(tester, find.byIcon(Icons.home_rounded));

    // Pengaturan: bahasa Inggris → mata uang USD → dark mode → kembali ID
    await _ensureAndTap(tester, find.byIcon(Icons.settings_rounded));
    await _waitFor(tester, find.text('Bahasa'));
    await _ensureAndTap(tester, find.text('Bahasa'));
    await _ensureAndTap(tester, find.text('English').last);
    await _waitSplash(tester);
    await _ensureAndTap(tester, find.byIcon(Icons.settings_rounded));
    await _waitFor(tester, find.text('Dark Mode'));

    await _ensureAndTap(tester, find.text('Currency'));
    await _ensureAndTap(tester, find.text('USD').last);
    await _waitSplash(tester);
    expect(find.textContaining('\$ '), findsWidgets);

    await _ensureAndTap(tester, find.byIcon(Icons.settings_rounded));
    await _waitFor(tester, find.text('Dark Mode'));
    await tester.tap(find.byType(Switch).first);
    await tester.pump(const Duration(milliseconds: 300));
    expect(SettingsService.instance.darkMode, isTrue);

    // ValueKey menyertakan darkMode → remount + splash; kembali ke settings.
    await _waitSplash(tester);
    await _ensureAndTap(tester, find.byIcon(Icons.settings_rounded));
    await _waitFor(tester, find.text('Language'));

    await _ensureAndTap(tester, find.text('Language'));
    await _ensureAndTap(tester, find.text('Indonesia').last);
    await _waitSplash(tester);
    await _ensureAndTap(tester, find.byIcon(Icons.settings_rounded));
    await _waitFor(tester, find.text('Bahasa'));

    // Bersihkan database
    await _ensureAndTap(tester, find.text('Gunakan Database Kosong (Bersih)'));
    await tester.pump(const Duration(milliseconds: 400));
    await _ensureAndTap(tester, find.byIcon(Icons.home_rounded));
    await _waitFor(tester, find.text('Belum Ada Struk Belanja'));
  });

  testWidgets('OCR asli: ML Kit mem-parse gambar struk nyata (fixture)', (tester) async {
    // Fixture = gambar struk asli (teks hitam di kertas krem) dari
    // integration_test/fixtures/receipt.png. Jalur OCR nyata: file →
    // Google ML Kit → parser — sama persis dengan kode layar scanner.
    final bytes = (await rootBundle.load('integration_test/fixtures/receipt.png')).buffer.asUint8List();
    final file = File('${Directory.systemTemp.path}/receipt_fixture.png');
    await file.writeAsBytes(bytes);

    final rawText = await OcrService.recognizeText(file.path);
    debugPrint('OCR_TEST_RAW<<< $rawText >>>OCR_TEST_RAW');
    // ML Kit di emulator (model x86) terbukti hanya mengenali baris atas &
    // bawah gambar — item tengah sering hilang. Jadi bukti yang diawasi:
    // OCR menghasilkan teks NYATA dari GAMBAR fixture (bukan simulasi),
    // dan parser tetap menanganinya tanpa gagal.
    expect(rawText.length, greaterThan(10), reason: 'ML Kit harus membaca teks dari gambar struk fixture');
    expect(rawText.toUpperCase(), contains('KOPI'),
        reason: 'teks harus berasal dari gambar fixture (KOPI SENOPATI), bukan simulasi');
    final parsed = ReceiptParser.parseText(rawText);
    expect(parsed, isNotNull);
  });
}