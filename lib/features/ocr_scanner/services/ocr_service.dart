import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// OCR asli: Google ML Kit Text Recognition untuk gambar struk.
/// Dipakai layar scanner dan dipanggil langsung oleh integration test
/// (fixture gambar struk) untuk membuktikan jalur OCR nyata berfungsi.
class OcrService {
  static Future<String> recognizeText(String path) async {
    debugPrint('OCR_RECOGNIZE starting path=$path');
    final input = InputImage.fromFilePath(path);
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final result = await recognizer.processImage(input);
      debugPrint('OCR_RECOGNIZE done textLen=${result.text.length}');
      debugPrint('OCR_RAW_TEXT<<< ${result.text} >>>OCR_RAW_TEXT');
      return result.text;
    } finally {
      await recognizer.close();
    }
  }
}
