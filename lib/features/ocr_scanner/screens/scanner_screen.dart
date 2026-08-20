import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/utils/app_l10n.dart';
import '../../../core/utils/currency_rates.dart';
import '../../../core/utils/ocr_error.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/neo_lottie_loader.dart';
import '../../../core/utils/receipt_parser.dart';
import '../services/ocr_service.dart';
import 'ocr_result_preview_screen.dart';

class ScannerScreen extends StatefulWidget {
  final VoidCallback onClose;
  final Function(ParsedReceiptResult)? onScanWithResult;
  final VoidCallback onScanComplete;

  const ScannerScreen({
    super.key,
    required this.onClose,
    required this.onScanComplete,
    this.onScanWithResult,
  });

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isFlashOn = false;
  bool _isScanning = false;
  bool _cameraError = false;
  CameraController? _controller;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _initCamera();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) setState(() => _cameraError = true);
        return;
      }
      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(back, ResolutionPreset.high, enableAudio: false);
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _cameraError = false;
      });
    } catch (_) {
      if (mounted) setState(() => _cameraError = true);
    }
  }

  void _toggleFlash() {
    setState(() => _isFlashOn = !_isFlashOn);
    _controller?.setFlashMode(_isFlashOn ? FlashMode.torch : FlashMode.off);
  }

  /// OCR asli: foto dari kamera -> crop ke frame scan + naikkan kontras
  /// -> Google ML Kit -> parser struk.
  Future<void> _scanCamera() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      _simulateScan();
      return;
    }
    setState(() => _isScanning = true);
    try {
      final picture = await controller.takePicture();
      final (text, previewBytes) = await _recognizeCropped(picture.path);
      _finishWithText(text, previewBytes);
    } catch (e, st) {
      debugPrint('OCR_CAMERA_ERROR: $e\n$st');
      if (!mounted) return;
      // Modul ML Kit tidak tersedia → retry tidak akan membantu,
      // langsung tampilkan pesan yang jelas.
      if (isMlKitModuleUnavailableError(e)) {
        setState(() => _isScanning = false);
        _showError(friendlyOcrError(e));
        return;
      }
      try {
        final picture = await controller.takePicture();
        await _retryRecognizePath(picture.path);
      } catch (e2, st2) {
        debugPrint('OCR_CAMERA_RETRY_ERROR: $e2\n$st2');
        if (mounted) {
          setState(() => _isScanning = false);
          _showError(friendlyOcrError(e2));
        }
      }
    }
  }

  /// Crop foto ke area frame scan (kotak panduan) lalu OCR dari hasil crop.
  /// Mengembalikan (teks OCR, bytes PNG hasil crop) agar bisa ditampilkan
  /// sebagai pratinjau. Gagal crop → fallback OCR dari file asli tanpa gambar.
  Future<(String, Uint8List?)> _recognizeCropped(String path) async {
    ui.Image? cropped;
    try {
      cropped = await _cropToScanFrame(path);
      if (cropped != null) {
        Uint8List? png;
        try {
          final pngData = await cropped.toByteData(format: ui.ImageByteFormat.png);
          png = pngData?.buffer.asUint8List();
        } catch (_) {}
        final data = await cropped.toByteData(format: ui.ImageByteFormat.rawRgba);
        if (data != null) {
          final input = InputImage.fromBitmap(
            bitmap: data.buffer.asUint8List(),
            width: cropped.width,
            height: cropped.height,
          );
          final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
          try {
            final result = await recognizer.processImage(input);
            debugPrint('OCR_RECOGNIZE_CROP done ${cropped.width}x${cropped.height} textLen=${result.text.length}');
            debugPrint('OCR_RAW_TEXT<<< ${result.text} >>>OCR_RAW_TEXT');
            return (result.text, png);
          } finally {
            await recognizer.close();
          }
        }
      }
      return (await _recognizeText(path), null);
    } catch (e, st) {
      debugPrint('OCR_CROP_RECOGNIZE_ERROR: $e\n$st');
      return (await _recognizeText(path), null);
    } finally {
      cropped?.dispose();
    }
  }

  /// Memotong area frame scan & menaikkan kontras (membantu struk thermal
  /// yang kontrasnya rendah). Mengembalikan null bila gagal.
  Future<ui.Image?> _cropToScanFrame(String path) async {
    // Ukuran layar diambil sebelum await apa pun (lint use_build_context).
    final screenSize = MediaQuery.of(context).size;
    try {
      final bytes = await File(path).readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      var image = frame.image;
      final origW = image.width.toDouble();
      final origH = image.height.toDouble();
      if (origW <= 0 || origH <= 0) return null;

      // Pastikan gambar tegak (portrait). Bila JPEG mentah masih landscape
      // (mis. EXIF tidak diterapkan decoder), putar 90° searah jarum jam.
      final pW = _controller?.value.previewSize?.width ?? origH;
      final pH = _controller?.value.previewSize?.height ?? origW;
      final portraitExpected = pH > pW;
      final decodedLandscape = origW > origH && (origW / origH) > 1.1;
      if (decodedLandscape && portraitExpected) {
        final recorder = ui.PictureRecorder();
        Canvas(recorder)
          ..translate(origH, 0)
          ..rotate(math.pi / 2)
          ..drawImage(image, Offset.zero, Paint());
        final rotated = await recorder.endRecording().toImage(origH.round(), origW.round());
        image.dispose();
        image = rotated;
      }
      final imgW = image.width.toDouble();
      final imgH = image.height.toDouble();

      // Posisi frame scan di layar — harus sinkron dengan overlay di build().
      final guide = Rect.fromLTWH(
        screenSize.width * 0.11,
        screenSize.height * 0.24,
        screenSize.width * 0.78,
        screenSize.height * 0.52,
      );

      // Transform layar -> piksel gambar, memperhitungkan FittedBox cover
      // dan rasio preview vs gambar hasil jepret.
      final k = math.max(screenSize.width / pH, screenSize.height / pW);
      final offX = math.max(0.0, (pH * k - screenSize.width) / 2);
      final offY = math.max(0.0, (pW * k - screenSize.height) / 2);
      double toImgX(double sx) => ((sx + offX) / k) * (imgW / pH);
      double toImgY(double sy) => ((sy + offY) / k) * (imgH / pW);

      var crop = Rect.fromLTRB(
        toImgX(guide.left),
        toImgY(guide.top),
        toImgX(guide.right),
        toImgY(guide.bottom),
      );
      // Perluas sedikit & jaga dalam batas gambar.
      crop = crop.inflate(20).intersect(Rect.fromLTWH(0, 0, imgW, imgH));
      if (crop.width < 48 || crop.height < 48) return null;

      // Gambar ulang hasil crop dengan filter kontras + kecerahan.
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final paint = Paint()
        ..colorFilter = const ui.ColorFilter.matrix(<double>[
          1.35, 0, 0, 0, 8, //
          0, 1.35, 0, 0, 8, //
          0, 0, 1.35, 0, 8, //
          0, 0, 0, 1, 0, //
        ]);
      canvas.drawImageRect(
        image,
        crop,
        Rect.fromLTWH(0, 0, crop.width, crop.height),
        paint,
      );
      final picture = recorder.endRecording();
      final cropped = await picture.toImage(crop.width.round(), crop.height.round());
      image.dispose();
      debugPrint('OCR_CROP done ${crop.width.round()}x${crop.height.round()}');
      return cropped;
    } catch (e, st) {
      debugPrint('OCR_CROP_ERROR: $e\n$st');
      return null;
    }
  }

  /// Coba OCR sekali lagi pada file yang sama untuk kegagalan transien
  /// (mis. model ML Kit gagal dimuat saat itu). Tetap gagal → pesan jelas.
  Future<void> _retryRecognizePath(String path, {Uint8List? previewBytes}) async {
    if (!mounted) return;
    setState(() => _isScanning = true);
    try {
      final text = await _recognizeText(path);
      _finishWithText(text, previewBytes);
    } catch (e, st) {
      debugPrint('OCR_RETRY_ERROR: $e\n$st');
      if (mounted) {
        setState(() => _isScanning = false);
        _showError(friendlyOcrError(e));
      }
    }
  }

  /// OCR dari gambar yang dipilih dari galeri.
  Future<void> _scanFromGallery() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 90,
    );
    if (picked == null) return;
    final bytes = await picked.length();
    debugPrint('OCR_GALLERY_PICKED path=${picked.path} bytes=$bytes');
    setState(() => _isScanning = true);
    // Baca bytes gambar untuk pratinjau di layar preview.
    Uint8List? previewBytes;
    try {
      previewBytes = await File(picked.path).readAsBytes();
    } catch (_) {}
    try {
      final text = await _recognizeText(picked.path);
      _finishWithText(text, previewBytes);
    } catch (e, st) {
      debugPrint('OCR_GALLERY_ERROR: $e\n$st');
      // Modul ML Kit tidak tersedia → retry tidak akan membantu,
      // langsung tampilkan pesan yang jelas.
      if (isMlKitModuleUnavailableError(e)) {
        if (mounted) {
          setState(() => _isScanning = false);
          _showError(friendlyOcrError(e));
        }
        return;
      }
      await _retryRecognizePath(picked.path, previewBytes: previewBytes);
    }
  }

  Future<String> _recognizeText(String path) => OcrService.recognizeText(path);

  /// Menampilkan layar preview hasil OCR agar bisa dikoreksi sebelum dipakai.
  void _finishWithText(String rawText, [Uint8List? previewBytes]) {
    if (!mounted) return;
    setState(() => _isScanning = false);
    final currency = CurrencyRatesService.detectCurrency(rawText) ?? 'IDR';
    final parsed = ReceiptParser.parseText(rawText, currency: currency);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OcrResultPreviewScreen(
          rawText: rawText,
          parsed: parsed,
          imageBytes: previewBytes,
          onConfirm: (confirmed) {
            Navigator.of(context).pop();
            if (widget.onScanWithResult != null) {
              widget.onScanWithResult!(confirmed);
            } else {
              widget.onScanComplete();
            }
          },
        ),
      ),
    );
  }

  void _simulateScan() {
    setState(() => _isScanning = true);

    Future.delayed(const Duration(milliseconds: 1600), () {
      if (mounted) {
        setState(() {
          _isScanning = false;
        });

        // Contoh simulasi teks mentah OCR dari foto struk nyata
        const simulatedOcrText = '''
Kopi Kenangan Senopati
1x Kopi Kenangan Mantan Large 28.000
2x Roti Coklat Klasik 30.000
1x Avocado Coffee Special 34.000
1x Toast Smoked Beef Cheese 38.000
Subtotal 130.000
PPN 10% 13.000
Service Charge 7.000
Grand Total 150.000
''';

        _finishWithText(simulatedOcrText);
      }
    });
  }

  void _showError(String message) {
    final c = context.palette;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: c.background)),
        backgroundColor: c.onSurface,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final cameraReady = _controller != null && _controller!.value.isInitialized;

    return Scaffold(
      backgroundColor: c.borderBlack,
      body: Stack(
        children: [
          // Live Camera Feed (OCR asli)
          if (cameraReady)
            Positioned.fill(
              child: ClipRect(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _controller!.value.previewSize!.height,
                    height: _controller!.value.previewSize!.width,
                    child: CameraPreview(_controller!),
                  ),
                ),
              ),
            )
          else if (_cameraError)
            Positioned.fill(
              child: Container(
                color: const Color(0xFF2C271B),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.no_photography_rounded, size: 96, color: Colors.white54),
                    const SizedBox(height: 12),
                    Text(
                      tr('scan_camera_error'),
                      style: const TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            )
          else
            // Fallback Loading (kamera masih inisialisasi)
            Positioned.fill(
              child: Container(
                color: const Color(0xFF2C271B),
                child: Opacity(
                  opacity: 0.4,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_outlined, size: 120, color: Colors.white54),
                        const SizedBox(height: 12),
                        Text(
                          tr('scan_simulate'),
                          style: const TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Scanning Target Frame Overlay
          Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.78,
              height: MediaQuery.of(context).size.height * 0.52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: c.primaryContainer, width: 3.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(120),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Animated Scanning Laser Line
                  AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return Positioned(
                        top: _animationController.value * (MediaQuery.of(context).size.height * 0.48),
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 3.5,
                          decoration: BoxDecoration(
                          color: c.primaryContainer,
                          boxShadow: [
                            BoxShadow(
                              color: c.primaryContainer.withAlpha(200),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // Loading Overlay State with Lottie Animation when scanning
          if (_isScanning)
            Positioned.fill(
              child: Container(
                color: Colors.black.withAlpha(190),
                child: Center(
                  child: NeoLottieLoader(
                    width: 100,
                    height: 100,
                    label: tr('scan_processing2'),
                  ),
                ),
              ),
            ),

          // Top Action Controls Bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: widget.onClose,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: c.surfaceContainerLowest,
                        shape: BoxShape.circle,
                        border: Border.all(color: c.borderBlack, width: 2),
                      ),
                      child: Icon(Icons.close, color: c.onSurface),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: c.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: c.borderBlack, width: 2),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.auto_awesome_rounded, size: 16, color: c.onPrimaryContainer),
                        SizedBox(width: 6),
                        Text(tr('scan_smart'), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: c.onPrimaryContainer)),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: cameraReady ? _toggleFlash : null,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _isFlashOn ? c.primaryContainer : c.surfaceContainerLowest,
                        shape: BoxShape.circle,
                        border: Border.all(color: c.borderBlack, width: 2),
                      ),
                      child: Icon(
                        _isFlashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                        color: _isFlashOn ? c.onPrimaryContainer : c.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Shutter Controls — di atas navbar sistem HP (bukan navbar app).
          Positioned(
            bottom: 40 + MediaQuery.of(context).padding.bottom,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Text(
                  tr('scan_place_guide'),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    GestureDetector(
                      onTap: _isScanning ? null : _scanFromGallery,
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: const Icon(Icons.photo_library_rounded, color: Colors.white),
                      ),
                    ),
                    GestureDetector(
                      onTap: _isScanning ? null : _scanCamera,
                      child: Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: c.primaryContainer,
                          border: Border.all(color: c.borderBlack, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: c.borderBlack,
                              offset: Offset(3, 3),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(Icons.camera_alt_rounded, size: 36, color: c.onPrimaryContainer),
                        ),
                      ),
                    ),
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: const Icon(Icons.tune_rounded, color: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
