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

/// Memetaka error OCR ke pesan ramah pengguna: pesan khusus saat modul
/// ML Kit tidak tersedia, pesan khusus saat fallback Gemini gagal (key kosong
/// vs API error), pesan umum saat gagal baca struk biasa.
/// ponytail: friendlyOcrError error mapping is minimal;
/// known ceiling: new Gemini error codes may require expansion
String friendlyOcrError(Object error) {
  final raw = error.toString();
  if (raw.contains('GEMINI_NO_KEY')) return tr('scan_gemini_no_key');
  if (raw.contains('GEMINI_FAIL')) return tr('scan_gemini_fail');
  if (raw.contains('MODULE_MLKIT_UNAVAILABLE')) {
    return tr('scan_mlkit_unavailable');
  }
  if (isMlKitModuleUnavailableError(error)) {
    return tr('scan_mlkit_unavailable');
  }
  return tr('scan_failed');
}
