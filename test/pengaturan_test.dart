import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fairsplit/core/theme/app_colors.dart';
import 'package:fairsplit/features/pengaturan/screens/pengaturan_screen.dart';

import 'helpers/palette_test_wrapper.dart';

void main() {
  testWidgets('Kartu identitas app: judul + versi (bukan profil Marko)',
      (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      wrapWithPalette(
        PengaturanScreen(onShowTutorial: () {}),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Neobill'), findsOneWidget);
    // Kartu identitas + row "Tentang Aplikasi" sama-sama menampilkan versi.
    expect(find.text('v1.0.0 (Neo-Brutalist Edition)'), findsNWidgets(2));
    expect(find.text('Marko'), findsNothing);
    expect(find.text('marko@fairsplit.app'), findsNothing);
  });
}
