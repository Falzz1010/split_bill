import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fairsplit/shared/widgets/neo_paw_logo.dart';
import 'package:fairsplit/core/theme/app_colors.dart';
import 'package:fairsplit/core/theme/app_colors.dart';

/// Merender widget logo asli ke file PNG, agar ikon launcher & splash native
/// persis sama dengan logo di dalam aplikasi.
void main() {
  testWidgets('render NeoPawLogo to launcher icon & splash image',
      (tester) async {
    await tester.runAsync(() async {
      final flutterRoot = Platform.environment['FLUTTER_ROOT'] ??
          r'C:\Users\setia\flutter';
      final fontData = File(
        '$flutterRoot/bin/cache/artifacts/material_fonts/materialicons-regular.otf',
      ).readAsBytes();
      final loader = FontLoader('MaterialIcons')
        ..addFont(fontData.then((d) => ByteData.view(d.buffer)));
      await loader.load();
    });

    final boundaryKey = GlobalKey();

    await tester.pumpWidget(
      PaletteScope(
        palette: AppPalette.paletteFor(false),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: RepaintBoundary(
              key: boundaryKey,
              child: const NeoPawLogo(size: 512),
            ),
          ),
        ),
      ),
    );
    await _savePng(boundaryKey, 'assets/icon/icon.png', pixelRatio: 2);
    await _savePng(boundaryKey, 'android/app/src/main/res/drawable/launch_image.png',
        pixelRatio: 1);

    await tester.pumpWidget(
      PaletteScope(
        palette: AppPalette.paletteFor(false),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: RepaintBoundary(
              key: boundaryKey,
              child: Icon(Icons.pets, size: 512, color: AppColors.borderBlack),
            ),
          ),
        ),
      ),
    );
    await _savePng(boundaryKey, 'assets/icon/icon_fg.png', pixelRatio: 2);
  });
}

Future<void> _savePng(GlobalKey key, String path,
    {required double pixelRatio}) async {
  await TestWidgetsFlutterBinding.instance.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: pixelRatio);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    File(path).writeAsBytesSync(bytes!.buffer.asUint8List());
    image.dispose();
  });
}
