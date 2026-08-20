import 'package:flutter/material.dart';
import 'package:fairsplit/core/theme/app_colors.dart';

/// Wraps a widget tree with [PaletteScope] so tests can access
/// `context.palette` without crashing.
Widget wrapWithPalette(Widget child, {bool dark = false}) {
  return PaletteScope(
    palette: AppPalette.paletteFor(dark),
    child: MaterialApp(home: child),
  );
}
