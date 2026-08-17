import 'package:flutter/material.dart';
import '../../../core/utils/app_l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/neo_card.dart';
import '../../../core/state/split_store.dart';
import '../../../core/settings/settings_service.dart';

class PengaturanScreen extends StatefulWidget {
  /// Dipanggil saat pengguna memilih "Lihat Tutorial" di bagian Bantuan.
  final VoidCallback? onShowTutorial;

  const PengaturanScreen({super.key, this.onShowTutorial});

  @override
  State<PengaturanScreen> createState() => _PengaturanScreenState();
}

class _PengaturanScreenState extends State<PengaturanScreen> {
  bool _notificationEnabled = true;
  bool _emailReminderEnabled = false;

  Future<void> _pickCurrency() async {
    final selected = await showDialog<String>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          backgroundColor: AppColors.surfaceContainerLowest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: AppColors.borderBlack, width: 2.5),
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
                      activeColor: AppColors.secondary,
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
    final selected = await showDialog<String>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          backgroundColor: AppColors.surfaceContainerLowest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: AppColors.borderBlack, width: 2.5),
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
                      activeColor: AppColors.secondary,
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

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SettingsService.instance,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header dengan Avatar Profil
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primaryContainer,
                          border: Border.all(
                            color: AppColors.borderBlack,
                            width: AppColors.borderWidth,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'M',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                              color: AppColors.onPrimaryContainer,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        tr('set_title'),
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Profile Card
                  NeoCard(
                    backgroundColor: AppColors.surfaceContainerLowest,
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primaryContainer,
                            border: Border.all(
                              color: AppColors.borderBlack,
                              width: 2.5,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'M',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 22,
                                color: AppColors.onPrimaryContainer,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tr('set_profile'),
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineSmall,
                              ),
                              Text(
                                tr('set_profile_email'),
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
                                color: AppColors.primaryContainer,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.borderBlack,
                                  width: 1.5,
                                ),
                              ),
                              child: Text(
                                SettingsService.instance.currency,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.onPrimaryContainer,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 18,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ],
                        ),
                      ),
                      _buildRowDivider(),
                      _buildRowTile(
                        context,
                        title: tr('set_language'),
                        value: SettingsService.instance.language == 'en'
                            ? 'English'
                            : 'Indonesia',
                        onTap: _pickLanguage,
                      ),
                      _buildRowDivider(),
                      _buildRowTile(
                        context,
                        title: tr('set_dark'),
                        onTap: null,
                        trailing: Switch.adaptive(
                          value: SettingsService.instance.darkMode,
                          activeTrackColor: AppColors.secondaryContainer,
                          activeThumbColor: AppColors.secondary,
                          onChanged: (val) =>
                              SettingsService.instance.setDarkMode(val),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Section: Notifikasi
                  _buildSectionCard(
                    context,
                    icon: Icons.notifications_rounded,
                    title: tr('set_notif'),
                    children: [
                      _buildRowTile(
                        context,
                        title: tr('set_notif_push'),
                        onTap: null,
                        trailing: Switch.adaptive(
                          value: _notificationEnabled,
                          activeTrackColor: AppColors.secondaryContainer,
                          activeThumbColor: AppColors.secondary,
                          onChanged: (val) =>
                              setState(() => _notificationEnabled = val),
                        ),
                      ),
                      _buildRowDivider(),
                      _buildRowTile(
                        context,
                        title: tr('set_notif_email'),
                        onTap: null,
                        trailing: Switch.adaptive(
                          value: _emailReminderEnabled,
                          activeTrackColor: AppColors.secondaryContainer,
                          activeThumbColor: AppColors.secondary,
                          onChanged: (val) =>
                              setState(() => _emailReminderEnabled = val),
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
                            await SplitStore.instance.clearAll();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    tr('set_db_cleared'),
                                    style: TextStyle(
                                      color: AppColors.background,
                                    ),
                                  ),
                                  backgroundColor: AppColors.onSurface,
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
                                  color: AppColors.error,
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
                                          color: AppColors.onSurfaceVariant,
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
                          color: AppColors.outlineVariant,
                        ),
                        InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () async {
                            await SplitStore.instance.loadDemo();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    tr('set_db_loaded'),
                                    style: TextStyle(
                                      color: AppColors.background,
                                    ),
                                  ),
                                  backgroundColor: AppColors.secondary,
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
                                  color: AppColors.secondary,
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
                                          color: AppColors.onSurfaceVariant,
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
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Payment Methods
                  Text(
                    tr('set_wallet'),
                    style: Theme.of(
                      context,
                    ).textTheme.headlineSmall?.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 12),

                  NeoCard(
                    child: Column(
                      children: [
                        _buildPaymentTile(
                          context,
                          name: 'Bank BCA',
                          account: '1234 5678 90 a/n Marko',
                          isDefault: true,
                        ),
                        const SizedBox(height: 10),
                        _buildPaymentTile(
                          context,
                          name: 'GoPay / QRIS',
                          account: '0812-3456-7890',
                          isDefault: false,
                        ),
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
    return Divider(height: 1, thickness: 1.5, color: AppColors.outlineVariant);
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
                        color: AppColors.onSurfaceVariant,
                      )
                    : const SizedBox.shrink()),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentTile(
    BuildContext context, {
    required String name,
    required String account,
    required bool isDefault,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isDefault
                    ? AppColors.primaryContainer
                    : AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.borderBlack, width: 1.5),
              ),
              child: Icon(
                Icons.account_balance_wallet_rounded,
                size: 20,
                color: isDefault
                    ? AppColors.onPrimaryContainer
                    : AppColors.onSurface,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: Theme.of(context).textTheme.labelLarge),
                Text(account, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ],
        ),
        if (isDefault)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.secondaryContainer,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.borderBlack, width: 1),
            ),
            child: Text(
              tr('common_utama'),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AppColors.onAccent(AppColors.secondaryContainer),
              ),
            ),
          ),
      ],
    );
  }
}
