import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fairsplit/main.dart' as app;
import 'package:fairsplit/core/services/gemini_service.dart';
import 'package:fairsplit/core/state/split_store.dart';

/// Screenshot capture untuk layar-layar Split Bill (mode personal).
/// Jalankan: flutter drive --driver=test_driver/integration_test.dart \
///   --target=integration_test/splitbill_screenshot_test.dart -d emulator-5554
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

  /// Indeks IndexedStack saat ini (= tab aktif di mode personal).
  int currentTab(WidgetTester tester) {
    final stack = tester.widget<IndexedStack>(find.byType(IndexedStack));
    return stack.index ?? 0;
  }

  /// Pindah tab bottom nav (personal: 0 Home, 1 Riwayat, 2 Ringkasan,
  /// 3 Pengaturan) dengan verifikasi indeks tab aktif.
  Future<void> goToTab(WidgetTester tester, IconData icon, int expectedIndex) async {
    for (var attempt = 0; attempt < 3; attempt++) {
      await tester.pump(const Duration(milliseconds: 300));
      final nav = find.byIcon(icon);
      if (tester.any(nav)) {
        await tester.tap(nav, warnIfMissed: false);
        await tester.pump(const Duration(milliseconds: 700));
        await tester.pump(const Duration(milliseconds: 400));
        if (currentTab(tester) == expectedIndex) return;
      }
    }
    throw StateError('Gagal pindah ke tab (icon ${icon.codePoint})');
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

  testWidgets('capture split bill screens', (tester) async {
    // Mulai dalam mode personal dengan data demo ter-seed.
    SharedPreferences.setMockInitialValues({
      'settings_seen_tutorial_version': '2',
      'settings_seen_scan_tutorial': '1',
      'settings_seen_onboarding': true,
      'settings_app_mode': 0, // AppMode.personal
      'settings_language': 'id',
      'settings_currency': 'IDR',
      'settings_dark_mode': false,
      'settings_use_ai_enhancement': false,
    });

    GeminiService.instance.demoMode = true;
    await SplitStore.instance.loadDemo();

    app.main();

    // 0. Splash screen (animasi ±4.2 detik; tangkap saat judul sudah tampil)
    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pump(const Duration(milliseconds: 1200));
    await capture(tester, 'split-00-splash');

    // Dashboard dengan data demo (featured split 'Kopi Kenangan Senopati').
    await waitFor(tester, find.text('Kopi Kenangan Senopati'));
    await tester.pump(const Duration(milliseconds: 600));

    // 1. Dashboard
    await capture(tester, 'split-01-dashboard');

    // 2. Dialog Buat Struk / Split Manual
    await tester.tap(find.text('Buat Baru'));
    await waitFor(tester, find.text('Buat Split / Struk Manual'));
    await capture(tester, 'split-02-buat-struk');
    // Tutup dialog (modal bottom sheet → pop route langsung).
    await tester.binding.handlePopRoute();
    await tester.pump(const Duration(milliseconds: 700));

    // 3. Editor Struk & Pesanan (buka dari kartu featured)
    await tester.ensureVisible(find.text('Lihat & Edit Rincian Split'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Lihat & Edit Rincian Split'));
    await waitFor(tester, find.text('Edit Struk & Pesanan'));
    await capture(tester, 'split-03-editor');

    // 4. Ringkasan (dari editor → Simpan & Lanjutkan)
    await tester.ensureVisible(find.text('Simpan & Lanjutkan'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Simpan & Lanjutkan'));
    await waitFor(tester, find.text('TOTAL TAGIHAN'));
    if (currentTab(tester) != 2) {
      throw StateError('Ringkasan tidak terbuka (tab=${currentTab(tester)})');
    }
    await capture(tester, 'split-04-ringkasan');

    // Kembali ke dashboard (tombol back di Ringkasan)
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pump(const Duration(milliseconds: 700));
    if (currentTab(tester) != 0) {
      throw StateError('Kembali ke dashboard gagal (tab=${currentTab(tester)})');
    }

    // 5. Riwayat
    await goToTab(tester, Icons.history_rounded, 1);
    await waitFor(tester, find.text('Kopi Kenangan Senopati'));
    await capture(tester, 'split-05-riwayat');

    // 6. Pengaturan
    await goToTab(tester, Icons.settings_rounded, 3);
    await waitFor(tester, find.text('Bahasa'));
    await capture(tester, 'split-06-pengaturan');

    // 7. Onboarding / Pengenalan App (dari Pengaturan)
    await tester.ensureVisible(find.text('Lihat Pengenalan (Onboarding)'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Lihat Pengenalan (Onboarding)'));
    await waitFor(tester, find.text('Selamat Datang di Neobill'));
    await capture(tester, 'split-07-onboarding');
    await tester.binding.handlePopRoute();
    await tester.pump(const Duration(milliseconds: 700));
  });
}