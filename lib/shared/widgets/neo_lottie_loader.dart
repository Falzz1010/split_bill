import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../core/theme/app_colors.dart';

class NeoLottieLoader extends StatelessWidget {
  final String? lottieUrl;
  final double width;
  final double height;
  final String label;

  const NeoLottieLoader({
    super.key,
    this.lottieUrl,
    this.width = 120,
    this.height = 120,
    this.label = 'Memuat animasi Lottie...',
  });

  // Popular high quality free Lottie Animation JSON URLs for OCR / Receipt / Loading
  static const String defaultScanLoadingUrl = 'https://assets5.lottiefiles.com/packages/lf20_t9gkkhz4.json';
  static const String successCompletedUrl = 'https://assets9.lottiefiles.com/packages/lf20_jbrw3hcz.json';

  @override
  Widget build(BuildContext context) {
    final targetUrl = lottieUrl ?? defaultScanLoadingUrl;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: width + 24,
          height: height + 24,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primaryContainer,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.borderBlack, width: AppColors.borderWidth),
            boxShadow: [
              BoxShadow(
                color: AppColors.borderBlack,
                offset: Offset(3.5, 3.5),
              ),
            ],
          ),
          child: Lottie.network(
            targetUrl,
            width: width,
            height: height,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              // Fallback Animated Neo Indicator if offline or network fails
              return Center(
                child: SizedBox(
                  width: width * 0.5,
                  height: height * 0.5,
                  child: CircularProgressIndicator(
                    strokeWidth: 4,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.borderBlack),
                  ),
                ),
              );
            },
          ),
        ),
        if (label.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
          ),
        ],
      ],
    );
  }
}
