import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrLine {
  final String text;
  final Rect boundingBox;
  OcrLine(this.text, this.boundingBox);
}

class OcrBlock {
  final String text;
  final Rect boundingBox;
  final List<OcrLine> lines;
  OcrBlock(this.text, this.boundingBox, this.lines);
}

class OcrResult {
  final String text;
  final List<OcrBlock> blocks;
  OcrResult(this.text, this.blocks);
}

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
    } on PlatformException catch (e) {
      throw Exception('MODULE_MLKIT_UNAVAILABLE: ${e.message}');
    } finally {
      await recognizer.close();
    }
  }

  static Future<OcrResult> recognizeWithBoxes(String path) async {
    debugPrint('OCR_RECOGNIZE_BOXES starting path=$path');
    final input = InputImage.fromFilePath(path);
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final result = await recognizer.processImage(input);
      final blocks = result.blocks.map((b) {
        final lines = b.lines.map((l) {
          return OcrLine(l.text, l.boundingBox);
        }).toList();
        return OcrBlock(b.text, b.boundingBox, lines);
      }).toList();
      debugPrint('OCR_RECOGNIZE_BOXES done blocks=${blocks.length}');
      return OcrResult(result.text, blocks);
    } on PlatformException catch (e) {
      throw Exception('MODULE_MLKIT_UNAVAILABLE: ${e.message}');
    } finally {
      await recognizer.close();
    }
  }
}
