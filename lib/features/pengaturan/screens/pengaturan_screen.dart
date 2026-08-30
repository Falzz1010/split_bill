import 'package:flutter/material.dart';
import '../../../core/utils/app_l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/neo_card.dart';
import '../../../shared/widgets/neo_paw_logo.dart';
import '../../../core/state/split_store.dart';
import '../../../core/state/transaksi_umkm_store.dart';
import '../../../core/settings/settings_service.dart';
import '../../../core/services/gemini_service.dart';
import '../../../core/utils/currency_rates.dart';
import '../../../shared/widgets/neo_confirm_dialog.dart';
import '../../../shared/widgets/mode_switch_splash.dart';
import '../../onboarding/screens/onboarding_screen.dart';
import '../../umkm/screens/umkm_demo_screen.dart' as demo;

class PengaturanScreen extends StatefulWidget {
  /// Dipanggil saat pengguna memilih "Lihat Tutorial" di bagian Bantuan.
  final VoidCallback? onShowTutorial;

  const PengaturanScreen({super.key, this.onShowTutorial});

  @override
  State<PengaturanScreen> createState() => _PengaturanScreenState();
}

class _PengaturanScreenState extends State<PengaturanScreen> {
  bool _refreshingRates = false;
  bool _aiTesting = false;
  bool _obscureKey = true;
  final TextEditingController _aiKeyController =
      TextEditingController(text: SettingsService.instance.geminiApiKey);

  @override
  void dispose() {
    _aiKeyController.dispose();
    super.dispose();
  }

  Future<void> _testAiConnection() async {
    setState(() => _aiTesting = true);
    final ok = await GeminiService.instance.testConnection();
    if (!mounted) return;
    setState(() => _aiTesting = false);
    final c = context.palette;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? tr('set_ai_test_ok') : tr('set_ai_test_fail'),
          style: TextStyle(color: c.background),
        ),
        backgroundColor: ok ? c.secondary : c.error,
      ),
    );
  }

  Future<void> _pickCurrency() async {
    final c = context.palette;
    final selected = await showDialog<String>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          backgroundColor: c.surfaceContainerLowest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: c.borderBlack, width: 2.5),
          ),
          title: Text(tr('set_pick_currency')),
          children: [
            RadioGroup<String>(
              groupValue: SettingsService.instance.currency,
              onChanged: (v) => Navigator.pop(context, v),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final code in SettingsService.supportedCurrencies)
                    RadioListTile<String>(
                      value: code,
                      activeColor: c.secondary,
                      title: Text(code),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
    if (selected != null) {
      await SettingsService.instance.setCurrency(selected);
    }
  }

  Future<void> _pickLanguage() async {
    final c = context.palette;
    final selected = await showDialog<String>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          backgroundColor: c.surfaceContainerLowest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: c.borderBlack, width: 2.5),
          ),
          title: Text(tr('set_pick_language')),
          children: [
            RadioGroup<String>(
              groupValue: SettingsService.instance.language,
              onChanged: (v) => Navigator.pop(context, v),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final lang in SettingsService.supportedLanguages)
                    RadioListTile<String>(
                      value: lang['code']!,
                      activeColor: c.secondary,
                      title: Text(lang['name']!),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
    if (selected != null) {
      await SettingsService.instance.setLanguage(selected);
    }
  }

  Future<void> _refreshRates() async {
    setState(() => _refreshingRates = true);
    final ok = await CurrencyRatesService.instance.refreshRates();
    if (!mounted) return;
    setState(() => _refreshingRates = false);
    final c = context.palette;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? tr('set_rates_ok') : tr('set_rates_fail'),
          style: TextStyle(color: c.background),
        ),
        backgroundColor: ok ? c.secondary : c.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge(
        [SettingsService.instance, CurrencyRatesService.instance],
      ),
      builder: (context, _) {
        return Scaffold(
          backgroundColor: context.palette.background,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header dengan Logo Aplikasi
                  Row(
                    children: [
                      NeoPawLogo(size: 46),
                      const SizedBox(width: 10),
                      Text(
                        tr('set_title'),
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Card Identitas Aplikasi
                  NeoCard(
                    backgroundColor: context.palette.surfaceContainerLowest,
                    child: Row(
                      children: [
                        NeoPawLogo(size: 56),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tr('dash_title'),
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineSmall,
                              ),
                              Text(
                                tr('set_version'),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Section: Preferensi
                  _buildSectionCard(
                    context,
                    icon: Icons.tune_rounded,
                    title: tr('set_pref'),
                    children: [
                      _buildRowTile(
                        context,
                        title: tr('umkm_switch_umkm'),
                        onTap: null,
                        trailing: Switch.adaptive(
                          value: SettingsService.instance.appMode == AppMode.umkm,
                          activeTrackColor: context.palette.secondaryContainer,
                          activeThumbColor: context.palette.secondary,
                          onChanged: (val) async {
                            final target = val ? AppMode.umkm : AppMode.personal;
                            // Show splash lalu switch mode
                            await ModeSwitchSplash.show(context, target);
                            if (context.mounted) {
                              SettingsService.instance.setAppMode(target);
                            }
                          },
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        child: Text(
                          SettingsService.instance.appMode == AppMode.umkm
                              ? 'Mode Kasir: Dashboard omzet, laporan shift, PPN auto-on'
                              : 'Mode Personal: Split bill teman/keluarga',
                          style: TextStyle(fontSize: 11, color: context.palette.onSurfaceVariant),
                        ),
                      ),
                      _buildRowDivider(),
                      _buildRowTile(
                        context,
                        title: tr('set_currency'),
                        onTap: _pickCurrency,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: context.palette.primaryContainer,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: context.palette.borderBlack,
                                  width: 1.5,
                                ),
                              ),
                              child: Text(
                                SettingsService.instance.currency,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: context.palette.onPrimaryContainer,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 18,
                              color: context.palette.onSurfaceVariant,
                            ),
                          ],
                        ),
                      ),
                      _buildRowDivider(),
                      _buildRowTile(
                        context,
                        title: tr('set_language'),
                        onTap: _pickLanguage,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: context.palette.primaryContainer,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: context.palette.borderBlack,
                                  width: 1.5,
                                ),
                              ),
                              child: Text(
                                SettingsService.instance.language == 'en'
                                    ? 'English'
                                    : 'Indonesia',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: context.palette.onPrimaryContainer,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 18,
                              color: context.palette.onSurfaceVariant,
                            ),
                          ],
                        ),
                      ),
                      _buildRowDivider(),
                      _buildRowTile(
                        context,
                        title: tr('set_dark'),
                        onTap: null,
                        trailing: Switch.adaptive(
                          value: SettingsService.instance.darkMode,
                          activeTrackColor: context.palette.secondaryContainer,
                          activeThumbColor: context.palette.secondary,
                          onChanged: (val) =>
                              SettingsService.instance.setDarkMode(val),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Section: Konfigurasi Google Gemini AI
                  _buildSectionCard(
                    context,
                    icon: Icons.auto_awesome_rounded,
                    title: tr('set_ai'),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
                        child: Text(
                          tr('set_ai_desc'),
                          style: TextStyle(
                            fontSize: 11,
                            color: context.palette.onSurfaceVariant,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                        child: TextField(
                          controller: _aiKeyController,
                          obscureText: _obscureKey,
                          onChanged: (v) =>
                              SettingsService.instance.setGeminiApiKey(v),
                          decoration: InputDecoration(
                            labelText: tr('set_ai_key'),
                            hintText: tr('set_ai_key_hint'),
                            filled: true,
                            fillColor: Colors.white,
                            isDense: true,
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: context.palette.borderBlack,
                                width: 1.5,
                              ),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureKey
                                    ? Icons.visibility_rounded
                                    : Icons.visibility_off_rounded,
                                size: 18,
                                color: context.palette.onSurfaceVariant,
                              ),
                              onPressed: () =>
                                  setState(() => _obscureKey = !_obscureKey),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: _aiTesting ? null : _testAiConnection,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: context.palette.secondaryContainer,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: context.palette.borderBlack,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (_aiTesting)
                                  SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: context.palette.borderBlack,
                                    ),
                                  )
                                else
                                  Icon(
                                    Icons.wifi_tethering_rounded,
                                    size: 16,
                                    color: context.palette.borderBlack,
                                  ),
                                const SizedBox(width: 6),
                                Text(
                                  _aiTesting
                                      ? tr('set_ai_testing')
                                      : tr('set_ai_test'),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      _buildRowDivider(),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 4, 14, 10),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tr('set_ai_refine_toggle'),
                                    style: Theme.of(context).textTheme.labelLarge,
                                  ),
                                  Text(
                                    tr('set_ai_refine_desc'),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: context.palette.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch.adaptive(
                              value: SettingsService.instance.useAiEnhancement,
                              activeTrackColor: context.palette.secondaryContainer,
                              activeThumbColor: context.palette.secondary,
                              onChanged: (val) =>
                                  SettingsService.instance.setUseAiEnhancement(val),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Section: Kurs Mata Uang
                  _buildSectionCard(
                    context,
                    icon: Icons.currency_exchange_rounded,
                    title: tr('set_rates'),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
                        child: Text(
                          tr('set_rates_desc'),
                          style: TextStyle(
                            fontSize: 11,
                            color: context.palette.onSurfaceVariant,
                          ),
                        ),
                      ),
                      for (final code in CurrencyRatesService.displayCurrencies)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                code,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                code == 'IDR'
                                    ? tr('set_rates_base')
                                    : CurrencyRatesService.instance.formatRate(
                                        code,
                                      ),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 6, 14, 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (CurrencyRatesService.instance.lastUpdated !=
                                null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text(
                                  tr('set_rates_updated').replaceAll(
                                    '{time}',
                                    _fmtTime(
                                      CurrencyRatesService
                                          .instance.lastUpdated!,
                                    ),
                                  ),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: context.palette.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: _refreshingRates
                                  ? null
                                  : _refreshRates,
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: context.palette.secondaryContainer,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: context.palette.borderBlack,
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (_refreshingRates)
                                      SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: context.palette.borderBlack,
                                        ),
                                      )
                                    else
                                      Icon(
                                        Icons.cloud_sync_rounded,
                                        size: 16,
                                        color: context.palette.borderBlack,
                                      ),
                                    const SizedBox(width: 6),
                                    Text(
                                      tr('set_rates_refresh'),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Data Storage Section
                  Text(
                    tr('set_db'),
                    style: Theme.of(
                      context,
                    ).textTheme.headlineSmall?.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 12),

                  NeoCard(
                    child: Column(
                      children: [
                        InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () async {
                            final confirmed = await showConfirmDialog(
                              context,
                              title: tr('set_db_clear_confirm_title'),
                              message: tr('set_db_clear_confirm_desc'),
                              confirmLabel: tr('set_db_confirm_ok'),
                            );
                            if (!confirmed || !context.mounted) return;
                            await SplitStore.instance.clearAll();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    tr('set_db_cleared'),
                                    style: TextStyle(
                                      color: context.palette.background,
                                    ),
                                  ),
                                  backgroundColor: context.palette.onSurface,
                                ),
                              );
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 4,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.delete_sweep_rounded,
                                  color: context.palette.error,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        tr('set_db_clear'),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        tr('set_db_clear_desc'),
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: context.palette.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Divider(
                          height: 16,
                          thickness: 1.5,
                          color: context.palette.outlineVariant,
                        ),
                        InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () async {
                            final confirmed = await showConfirmDialog(
                              context,
                              title: tr('set_db_load_confirm_title'),
                              message: tr('set_db_load_confirm_desc'),
                              confirmLabel: tr('set_db_confirm_ok'),
                            );
                            if (!confirmed || !context.mounted) return;
                            await SplitStore.instance.loadDemo();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    tr('set_db_loaded'),
                                    style: TextStyle(
                                      color: context.palette.background,
                                    ),
                                  ),
                                  backgroundColor: context.palette.secondary,
                                ),
                              );
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 4,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.refresh_rounded,
                                  color: context.palette.secondary,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        tr('set_db_load'),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        tr('set_db_load_desc'),
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: context.palette.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // UMKM Demo button — only visible in UMKM mode
                        if (SettingsService.instance.appMode == AppMode.umkm) ...[
                          Divider(
                            height: 16,
                            thickness: 1.5,
                            color: context.palette.outlineVariant,
                          ),
                          InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () async {
                              final confirmed = await showConfirmDialog(
                                context,
                                title: tr('set_db_umkm_confirm_title'),
                                message: tr('set_db_umkm_confirm_desc'),
                                confirmLabel: tr('set_db_confirm_ok'),
                              );
                              if (!confirmed || !context.mounted) return;
                              await TransaksiUmkmStore.instance.loadDemo();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      tr('set_db_umkm_loaded'),
                                      style: TextStyle(
                                        color: context.palette.background,
                                      ),
                                    ),
                                    backgroundColor: context.palette.secondary,
                                  ),
                                );
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 4,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.store_rounded,
                                    color: context.palette.secondary,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          tr('set_db_umkm_load'),
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        SizedBox(height: 2),
                                        Text(
                                          tr('set_db_umkm_load_desc'),
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: context.palette.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Demo Mode button
                          InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const demo.DemoModeScreen(),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 4,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.play_circle_rounded,
                                    color: context.palette.primary,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Demo Mode',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        SizedBox(height: 2),
                                        Text(
                                          'Auto-play semua fitur untuk presentasi',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: context.palette.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Section: Bantuan & Tentang
                  _buildSectionCard(
                    context,
                    icon: Icons.help_outline_rounded,
                    title: tr('set_help'),
                    children: [
                      _buildRowTile(
                        context,
                        title: tr('set_onboarding'),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const OnboardingScreen(),
                            ),
                          );
                        },
                      ),
                      _buildRowDivider(),
                      _buildRowTile(
                        context,
                        title: tr('set_tutorial'),
                        onTap: widget.onShowTutorial,
                      ),
                      _buildRowDivider(),
                      _buildRowTile(
                        context,
                        title: tr('set_about'),
                        value: tr('set_version'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _fmtTime(DateTime t) {
    final now = DateTime.now();
    final local = t.toLocal();
    final sameDay = local.year == now.year &&
        local.month == now.month &&
        local.day == now.day;
    final hm =
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    return sameDay ? hm : '${local.day}/${local.month} $hm';
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontSize: 16),
        ),
        const SizedBox(height: 12),
        NeoCard(
          padding: EdgeInsets.zero,
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildRowDivider() {
    return Divider(height: 1, thickness: 1.5, color: context.palette.outlineVariant);
  }

  Widget _buildRowTile(
    BuildContext context, {
    required String title,
    String? value,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(title, style: Theme.of(context).textTheme.labelLarge),
            ),
            if (value != null) ...[
              Flexible(
                child: Text(
                  value,
                  style: Theme.of(context).textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
            ],
            trailing ??
                (onTap != null
                    ? Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: context.palette.onSurfaceVariant,
                      )
                    : const SizedBox.shrink()),
          ],
        ),
      ),
    );
  }

}
