import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme => _buildTheme(dark: false);

  static ThemeData get darkTheme => _buildTheme(dark: true);

  static ThemeData _buildTheme({required bool dark}) {
    // Warna diambil langsung dari palet mode ini, bukan dari AppColors statis
    // yang bisa berubah-ubah oleh applyDark() — tema jadi deterministik.
    final palette = AppPalette.paletteFor(dark);
    return ThemeData(
      useMaterial3: true,
      brightness: dark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: palette.background,
      colorScheme: ColorScheme(
        brightness: dark ? Brightness.dark : Brightness.light,
        primary: palette.primary,
        onPrimary: palette.background,
        secondary: palette.secondary,
        onSecondary: palette.background,
        error: palette.error,
        onError: palette.background,
        surface: palette.background,
        onSurface: palette.onSurface,
        outline: palette.outline,
        outlineVariant: palette.outlineVariant,
        surfaceContainerLowest: palette.surfaceContainerLowest,
        surfaceContainerLow: palette.surfaceContainerLow,
        surfaceContainer: palette.surfaceContainer,
        surfaceContainerHigh: palette.surfaceContainerHigh,
        surfaceContainerHighest: palette.surfaceContainerHighest,
      ),
      textTheme: TextTheme(
        // Headlines using Outfit
        headlineLarge: GoogleFonts.outfit(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: palette.onSurface,
          height: 1.1,
          letterSpacing: -0.02,
        ),
        headlineMedium: GoogleFonts.outfit(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: palette.onSurface,
          height: 1.2,
        ),
        headlineSmall: GoogleFonts.outfit(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: palette.onSurface,
          height: 1.2,
        ),
        // Body using Plus Jakarta Sans
        bodyLarge: GoogleFonts.plusJakartaSans(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: palette.onSurface,
          height: 1.5,
        ),
        bodyMedium: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: palette.onSurface,
          height: 1.5,
        ),
        bodySmall: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: palette.onSurfaceVariant,
          height: 1.5,
        ),
        labelLarge: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: palette.onSurface,
        ),
        labelMedium: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: palette.onSurface,
        ),
        labelSmall: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: palette.onSurfaceVariant,
        ),
      ),
    );
  }
}
