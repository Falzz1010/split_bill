import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fairsplit/main.dart';
import 'package:fairsplit/features/onboarding/widgets/feature_tutorial_overlay.dart';

void main() {
  testWidgets('Tutorial overlay animates in smoothly', (WidgetTester tester) async {
    final targetKey = GlobalKey();

    await tester.pumpWidget(
      MaterialApp(
        home: Stack(
          children: [
            Positioned(
              left: 0,
              top: 0,
              child: SizedBox(
                key: targetKey,
                width: 120,
                height: 120,
                child: const ColoredBox(color: Colors.red),
              ),
            ),
            FeatureTutorialOverlay(
              steps: [
                FeatureTutorialStep(
                  key: targetKey,
                  titleKey: 'tut2_scan_title',
                  descKey: 'tut2_scan_desc',
                ),
              ],
              onFinish: () {},
            ),
          ],
        ),
      ),
    );
    await tester.pump(); // frame layout awal

    final fade = find.descendant(
      of: find.byType(FeatureTutorialOverlay),
      matching: find.byType(FadeTransition),
    );

    // Fase delay 450ms: overlay masih transparan.
    expect(tester.widget<FadeTransition>(fade).opacity.value, 0);

    // Lewati delay (450ms) lalu beri satu frame → animasi berjalan sebagian
    // (fade-in halus).
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 100));
    final mid = tester.widget<FadeTransition>(fade).opacity.value;
    expect(mid, greaterThan(0));
    expect(mid, lessThan(1));

    // Selesai → overlay tampil penuh.
    await tester.pump(const Duration(milliseconds: 600));
    expect(tester.widget<FadeTransition>(fade).opacity.value, 1);
  });

  testWidgets('App renders smoke test', (WidgetTester tester) async {
    // Mock SharedPreferences agar SettingsService tidak menggantung di test.
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const FairSplitApp());
    // Splash screen menampilkan selama 3.6 detik sebelum navigasi
    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(seconds: 1));

    // Pengguna baru melihat tutorial langsung di dalam app: langkah pertama
    // menjelaskan tombol kamera (Scan Struk).
    expect(find.text('Scan Struk'), findsOneWidget);

    // Geser lewat 4 langkah tutorial berikutnya.
    for (var i = 0; i < 4; i++) {
      await tester.tap(find.text('Selanjutnya'));
      await tester.pumpAndSettle();
    }

    // Langkah terakhir: tab Pengaturan, tombol "Selesai".
    expect(find.text('Atur mata uang, bahasa, dan mode gelap lewat tab ini.'), findsOneWidget);
    await tester.tap(find.text('Selesai'));
    await tester.pumpAndSettle();

    expect(find.text('Hi, Marko'), findsOneWidget);
  });
}
