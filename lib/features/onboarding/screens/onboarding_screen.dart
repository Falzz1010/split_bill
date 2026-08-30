import 'package:flutter/material.dart';
import '../../../core/settings/settings_service.dart';
import '../../../core/utils/app_l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/neo_button.dart';
import '../../../shared/widgets/neo_card.dart';
import '../../../shared/widgets/neo_paw_logo.dart';
import '../../../main_navigation.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final TextEditingController _apiKeyController = TextEditingController();

  static const _totalPages = 4;

  @override
  void dispose() {
    _pageController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    final key = _apiKeyController.text.trim();
    if (key.isNotEmpty) {
      await SettingsService.instance.setGeminiApiKey(key);
    }
    await SettingsService.instance.markOnboardingSeen();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainNavigation()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 8, right: 16),
                child: _currentPage < _totalPages - 1
                    ? GestureDetector(
                        onTap: _finish,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: c.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: c.borderBlack, width: 1.5),
                          ),
                          child: Text(
                            tr('onb_skip'),
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ),

            // PageView
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _totalPages,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (context, index) => _buildPage(index),
              ),
            ),

            // Bottom controls
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Column(
                children: [
                  // Dot indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_totalPages, (i) {
                      final active = i == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.only(right: 6),
                        width: active ? 24 : 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: active ? c.primaryContainer : Colors.transparent,
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(color: c.borderBlack, width: 1.5),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 20),

                  // Next / Start button
                  NeoButton(
                    onTap: _nextPage,
                    width: double.infinity,
                    backgroundColor: c.primaryContainer,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _currentPage == _totalPages - 1
                              ? Icons.rocket_launch_rounded
                              : Icons.arrow_forward_rounded,
                          size: 20,
                          color: c.onPrimaryContainer,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _currentPage == _totalPages - 1
                              ? tr('onb_start')
                              : tr('onb_next'),
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: c.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(int index) {
    switch (index) {
      case 0:
        return _buildWelcomePage();
      case 1:
        return _buildOcrPage();
      case 2:
        return _buildUmkmPage();
      case 3:
        return _buildStartPage();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildWelcomePage() {
    final c = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          NeoPawLogo(size: 100),
          const SizedBox(height: 24),
          Text(
            tr('onb_welcome_title'),
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            tr('onb_welcome_desc'),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: c.onSurfaceVariant,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          NeoCard(
            backgroundColor: c.secondaryContainer,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(Icons.auto_awesome_rounded, size: 20, color: c.onSecondaryContainer),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    tr('onb_welcome_badge'),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: c.onSecondaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOcrPage() {
    final c = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: c.primaryContainer,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: c.borderBlack, width: AppColors.borderWidth),
              boxShadow: [
                BoxShadow(color: c.borderBlack, offset: AppColors.shadowOffset),
              ],
            ),
            child: Icon(Icons.document_scanner_rounded, size: 44, color: c.onPrimaryContainer),
          ),
          const SizedBox(height: 24),
          Text(
            tr('onb_ocr_title'),
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            tr('onb_ocr_desc'),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: c.onSurfaceVariant,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          _buildFeatureChip(Icons.camera_alt_rounded, 'OCR + AI Gemini Vision'),
          const SizedBox(height: 10),
          _buildFeatureChip(Icons.auto_fix_high_rounded, 'Auto-koreksi nama & harga'),
          const SizedBox(height: 10),
          _buildFeatureChip(Icons.receipt_long_rounded, 'Multi-mata uang'),
        ],
      ),
    );
  }

  Widget _buildUmkmPage() {
    final c = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: c.secondaryContainer,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: c.borderBlack, width: AppColors.borderWidth),
              boxShadow: [
                BoxShadow(color: c.borderBlack, offset: AppColors.shadowOffset),
              ],
            ),
            child: Icon(Icons.insights_rounded, size: 44, color: c.onSecondaryContainer),
          ),
          const SizedBox(height: 24),
          Text(
            tr('onb_umkm_title'),
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            tr('onb_umkm_desc'),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: c.onSurfaceVariant,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          _buildFeatureChip(Icons.store_rounded, 'Dashboard omzet real-time'),
          const SizedBox(height: 10),
          _buildFeatureChip(Icons.trending_up_rounded, 'Prediksi penjualan & forecast'),
          const SizedBox(height: 10),
          _buildFeatureChip(Icons.analytics_rounded, 'Analisis profitabilitas menu'),
        ],
      ),
    );
  }

  Widget _buildStartPage() {
    final c = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: c.primaryContainer,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: c.borderBlack, width: AppColors.borderWidth),
              boxShadow: [
                BoxShadow(color: c.borderBlack, offset: AppColors.shadowOffset),
              ],
            ),
            child: Icon(Icons.key_rounded, size: 44, color: c.onPrimaryContainer),
          ),
          const SizedBox(height: 24),
          Text(
            tr('onb_api_title'),
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            tr('onb_api_desc'),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: c.onSurfaceVariant,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _apiKeyController,
            obscureText: true,
            decoration: InputDecoration(
              hintText: tr('onb_api_hint'),
              filled: true,
              fillColor: c.surfaceContainerLowest,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: c.borderBlack, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: c.borderBlack, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            tr('onb_api_note'),
            style: TextStyle(fontSize: 11, color: c.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureChip(IconData icon, String label) {
    final c = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: c.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.borderBlack, width: 1.5),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: c.primary),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: c.onSurface),
          ),
        ],
      ),
    );
  }
}
