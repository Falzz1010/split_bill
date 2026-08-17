import 'package:flutter_test/flutter_test.dart';
import 'package:fairsplit/core/utils/ocr_error.dart';

void main() {
  group('isMlKitModuleUnavailableError', () {
    test('mendeteksi error "optional module download" (kasus emulator tanpa GMS)', () {
      const error = 'PlatformException(TextRecognizerError, '
          'com.google.mlkit.common.MlKitException: '
          'Request for optional module download of ocr failed, null, null)';
      expect(isMlKitModuleUnavailableError(error), isTrue);
    });

    test('mendeteksi error "waiting for the requested ... module"', () {
      const error = 'PlatformException(TextRecognizerError, '
          'com.google.mlkit.common.MlKitException: '
          'Waiting for the requested text recognition module to be downloaded., null, null)';
      expect(isMlKitModuleUnavailableError(error), isTrue);
    });

    test('mendeteksi error "vision.ocr ... not available"', () {
      const error = 'PlatformException(TextRecognizerError, '
          'MlKitException: Requested feature [vision.ocr] is not available on this device, null, null)';
      expect(isMlKitModuleUnavailableError(error), isTrue);
    });

    test('tidak mendeteksi error OCR biasa (gagal baca teks)', () {
      const error = 'PlatformException(TextRecognizerError, '
          'com.google.mlkit.common.MlKitException: '
          'Failed to detect the text from image., null, null)';
      expect(isMlKitModuleUnavailableError(error), isFalse);
    });

    test('tidak mendeteksi error non-OCR', () {
      expect(isMlKitModuleUnavailableError('File not found'), isFalse);
    });
  });

  group('friendlyOcrError', () {
    test('mengembalikan pesan khusus saat modul ML Kit tidak tersedia', () {
      final msg = friendlyOcrError('MlKitException: module download of ocr failed');
      expect(msg, contains('Modul OCR'));
      expect(msg, contains('Google Play Services'));
    });

    test('mengembalikan pesan umum untuk error lainnya', () {
      final msg = friendlyOcrError('Failed to detect the text from image');
      expect(msg, contains('Gagal membaca struk'));
    });
  });
}
