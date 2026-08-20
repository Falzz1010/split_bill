import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/settings/settings_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_colors.dart';
import 'core/utils/currency_rates.dart';
import 'features/splash/screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  await SettingsService.instance.load();
  await CurrencyRatesService.instance.load();
  // Auto-update kurs hari ini di latar belakang (tidak menunda startup).
  unawaited(CurrencyRatesService.instance.refreshIfStale());
  AppPalette.applyDark(SettingsService.instance.darkMode);
  runApp(const FairSplitApp());
}

class FairSplitApp extends StatelessWidget {
  const FairSplitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SettingsService.instance,
      builder: (context, _) {
        final settings = SettingsService.instance;
        final palette = AppPalette.paletteFor(settings.darkMode);
        // Legacy fallback untuk kode yang belum pakai PaletteScope.
        AppPalette.applyDark(settings.darkMode);
        return PaletteScope(
          palette: palette,
          child: MaterialApp(
            key: ValueKey('${settings.darkMode}-${settings.language}-${settings.currency}'),
            title: 'Neobill — Split Bill',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: settings.darkMode ? ThemeMode.dark : ThemeMode.light,
            home: const SplashScreen(),
          ),
        );
      },
    );
  }
}
