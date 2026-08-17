/// Utilitas untuk memetakan error OCR (ML Kit) ke pesan yang ramah pengguna.
library;

import 'app_l10n.dart';

/// True bila error menunjukkan modul OCR ML Kit tidak tersedia di perangkat
/// (mis. gagal di-download karena tanpa internet / Google Play Services).
bool isMlKitModuleUnavailableError(Object error) {
  final raw = error.toString().toLowerCase();
  const keywords = [
    'module download',
    'optional module',
    'vision.ocr',
    'requested feature',
    'not available',
    'not supported',
    'download failed',
    'play services',
    'waiting for the requested',
  ];
  return keywords.any(raw.contains);
}

/// Memetakan error OCR ke pesan ramah pengguna: pesan khusus saat modul
/// ML Kit tidak tersedia, pesan umum saat gagal baca struk biasa.
String friendlyOcrError(Object error) =>
    isMlKitModuleUnavailableError(error) ? tr('scan_mlkit_unavailable') : tr('scan_failed');
