import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fairsplit/core/settings/settings_service.dart';
import 'package:fairsplit/core/theme/app_colors.dart';
import 'package:fairsplit/features/splash/screens/splash_screen.dart';
import 'package:fairsplit/features/onboarding/widgets/feature_tutorial_overlay.dart';

import 'helpers/palette_test_wrapper.dart';

void main() {
  testWidgets('Fresh install: tutorial tampil setelah splash selesai',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await SettingsService.instance.load();
    expect(SettingsService.instance.tutorialNeeded, isTrue,
        reason: 'user baru belum pernah melihat tutorial');

    await tester.pumpWidget(wrapWithPalette(const SplashScreen()));
    await tester.pump(const Duration(milliseconds: 4300));
    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.byType(FeatureTutorialOverlay), findsOneWidget,
        reason: 'tutorial harus muncul untuk pengguna baru');
  });

  testWidgets('Pengguna lama: tutorial tidak tampil', (tester) async {
    SharedPreferences.setMockInitialValues({
      'settings_seen_tutorial_version': SettingsService.kTutorialVersion,
    });
    await SettingsService.instance.load();
    expect(SettingsService.instance.tutorialNeeded, isFalse);

    await tester.pumpWidget(wrapWithPalette(const SplashScreen()));
    await tester.pump(const Duration(milliseconds: 4300));
    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.byType(FeatureTutorialOverlay), findsNothing);
  });
}