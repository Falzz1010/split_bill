import 'package:flutter/material.dart';

class PaletteData {
  const PaletteData({
    required this.background,
    required this.surfaceContainerLowest,
    required this.surfaceContainerLow,
    required this.surfaceContainer,
    required this.surfaceContainerHigh,
    required this.surfaceContainerHighest,
    required this.surfaceVariant,
    required this.borderBlack,
    required this.onSurface,
    required this.onSurfaceVariant,
    required this.outline,
    required this.outlineVariant,
    required this.primary,
    required this.primaryContainer,
    required this.primaryFixed,
    required this.onPrimaryContainer,
    required this.secondary,
    required this.secondaryContainer,
    required this.onSecondaryContainer,
    required this.error,
    required this.errorContainer,
  });

  final Color background;
  final Color surfaceContainerLowest;
  final Color surfaceContainerLow;
  final Color surfaceContainer;
  final Color surfaceContainerHigh;
  final Color surfaceContainerHighest;
  final Color surfaceVariant;
  final Color borderBlack;
  final Color onSurface;
  final Color onSurfaceVariant;
  final Color outline;
  final Color outlineVariant;
  final Color primary;
  final Color primaryContainer;
  final Color primaryFixed;
  final Color onPrimaryContainer;
  final Color secondary;
  final Color secondaryContainer;
  final Color onSecondaryContainer;
  final Color error;
  final Color errorContainer;
}

/// InheritedWidget yang membungkus widget tree dan menyediakan [PaletteData]
/// aktif berdasarkan dark mode. Menggantikan [AppPalette.current] mutable
/// sehingga state palette hidup di scope widget, bukan di static field.
class PaletteScope extends InheritedWidget {
  const PaletteScope({
    super.key,
    required this.palette,
    required super.child,
  });

  final PaletteData palette;

  /// Ambil palette dari context terdekat — aman dipanggil dari mana saja
  /// di dalam widget tree yang dibungkus [PaletteScope].
  static PaletteData of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<PaletteScope>();
    assert(scope != null, 'No PaletteScope found in context');
    return scope!.palette;
  }

  @override
  bool updateShouldNotify(PaletteScope oldWidget) => palette != oldWidget.palette;
}

class AppPalette {
  // Fallback untuk kode legacy yang belum punya BuildContext.
  // Hanya dipakai oleh AppColors.getters (static) — kode baru sebaiknya
  // memakai PaletteScope.of(context) supaya reaktif.
  static PaletteData current = _light;

  static const _light = PaletteData(
    background: Color(0xFFFAF6EE),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFFDF3E0),
    surfaceContainer: Color(0xFFF7EDDB),
    surfaceContainerHigh: Color(0xFFF1E7D5),
    surfaceContainerHighest: Color(0xFFEBE1D0),
    surfaceVariant: Color(0xFFEBE1D0),
    borderBlack: Color(0xFF1F1B10),
    onSurface: Color(0xFF1F1B10),
    onSurfaceVariant: Color(0xFF4E4632),
    outline: Color(0xFF80765F),
    outlineVariant: Color(0xFFD1C5AB),
    primary: Color(0xFF735C00),
    primaryContainer: Color(0xFFFFCD00),
    primaryFixed: Color(0xFFFFE089),
    onPrimaryContainer: Color(0xFF1F1B10),
    secondary: Color(0xFF006B5F),
    secondaryContainer: Color(0xFF62FAE3),
    onSecondaryContainer: Color(0xFF00201C),
    error: Color(0xFFBA1A1A),
    errorContainer: Color(0xFFFFDAD6),
  );

  static const _dark = PaletteData(
    background: Color(0xFF14130E),
    surfaceContainerLowest: Color(0xFF201E17),
    surfaceContainerLow: Color(0xFF27241C),
    surfaceContainer: Color(0xFF2E2A20),
    surfaceContainerHigh: Color(0xFF353026),
    surfaceContainerHighest: Color(0xFF3C372C),
    surfaceVariant: Color(0xFF353026),
    borderBlack: Color(0xFFEDE6D5),
    onSurface: Color(0xFFF4EFE3),
    onSurfaceVariant: Color(0xFFCFC8B5),
    outline: Color(0xFF9C937F),
    outlineVariant: Color(0xFF4A4538),
    primary: Color(0xFFF0C100),
    primaryContainer: Color(0xFFFFCD00),
    primaryFixed: Color(0xFFFFE089),
    onPrimaryContainer: Color(0xFF1F1B10),
    secondary: Color(0xFF3CDDC7),
    secondaryContainer: Color(0xFF62FAE3),
    onSecondaryContainer: Color(0xFF00302A),
    error: Color(0xFFFFB4AB),
    errorContainer: Color(0xFF4A1E1C),
  );

  /// Update fallback [current] untuk kode legacy + widget yang
  /// tidak punya context (mis. `AppColors.primaryContainer`).
  static void applyDark(bool dark) {
    current = dark ? _dark : _light;
  }

  /// Palet untuk mode tertentu — dipakai AppTheme agar tema konsisten dengan
  /// mode tanpa bergantung pada mutasi global [current].
  static PaletteData paletteFor(bool dark) => dark ? _dark : _light;
}

/// Extension pada [BuildContext] untuk mengakses palette secara reaktif.
/// Contoh: `final c = context.palette;` → `c.primaryContainer`.
extension BuildContextPalette on BuildContext {
  PaletteData get palette => PaletteScope.of(this);
}

/// AppColors defining the Soft Neo-Brutalist Palette for FairSplit.
/// Colors resolve dynamically so dark mode can switch the palette at runtime.
///
/// Gunakan `context.palette.xxx` untuk kode baru (reaktif via InheritedWidget).
/// `AppColors.xxx` statis tetap tersedia untuk backward-compat.
class AppColors {
  // Surface & Background
  static Color get background => AppPalette.current.background;
  static Color get surfaceContainerLowest =>
      AppPalette.current.surfaceContainerLowest;
  static Color get surfaceContainerLow =>
      AppPalette.current.surfaceContainerLow;
  static Color get surfaceContainer => AppPalette.current.surfaceContainer;
  static Color get surfaceContainerHigh =>
      AppPalette.current.surfaceContainerHigh;
  static Color get surfaceContainerHighest =>
      AppPalette.current.surfaceContainerHighest;
  static Color get surfaceVariant => AppPalette.current.surfaceVariant;

  // Ink & Borders
  static Color get borderBlack => AppPalette.current.borderBlack;
  static Color get onSurface => AppPalette.current.onSurface;
  static Color get onSurfaceVariant => AppPalette.current.onSurfaceVariant;
  static Color get outline => AppPalette.current.outline;
  static Color get outlineVariant => AppPalette.current.outlineVariant;

  // Vibrant Accents (Neo-Brutalist Palette)
  static Color get primaryContainer => AppPalette.current.primaryContainer;
  static Color get primary => AppPalette.current.primary;
  static Color get primaryFixed => AppPalette.current.primaryFixed;
  static Color get onPrimaryContainer => AppPalette.current.onPrimaryContainer;

  static Color get secondaryContainer => AppPalette.current.secondaryContainer;
  static Color get secondary => AppPalette.current.secondary;
  static Color get onSecondaryContainer =>
      AppPalette.current.onSecondaryContainer;

  static const Color tertiaryContainer = Color(0xFF00E8FD);
  static const Color tertiaryFixedDim = Color(0xFF00DBEE);

  static Color get errorContainer => AppPalette.current.errorContainer;
  static Color get error => AppPalette.current.error;

  // Extra Semantic Accents
  static const Color accentGreen = Color(0xFF22C55E);
  static const Color accentOrange = Color(0xFFFF7A59);
  static const Color accentLavender = Color(0xFFA5B4FC);
  static const Color accentPurple = Color(0xFFC084FC);

  /// Teks/ikon di atas warna aksen terang → hitam, di atas gelap → putih.
  static Color onAccent(Color bg) =>
      bg.computeLuminance() > 0.5 ? Colors.black : Colors.white;

  /// Parse `accentColorHex` anggota ('#RRGGBB' / 'RRGGBB' / '#AARRGGBB').
  /// Hex rusak/kosong tidak boleh membuat UI crash → jatuh ke [fallback].
  static Color fromHex(String? hex, {Color? fallback}) {
    final raw = (hex ?? '').replaceAll('#', '').trim();
    final value = int.tryParse(raw.length == 6 ? 'FF$raw' : raw, radix: 16);
    if (value == null || (raw.length != 6 && raw.length != 8)) {
      return fallback ?? primaryContainer;
    }
    return Color(value);
  }

  // Shadows & Borders
  static const double borderWidth = 2.5;
  static const Offset shadowOffset = Offset(3.0, 3.0);
}
