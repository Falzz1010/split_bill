import 'package:flutter/material.dart';
import 'core/settings/settings_service.dart';
import 'core/utils/app_l10n.dart';
import 'core/theme/app_colors.dart';
import 'core/models/split_model.dart';
import 'core/state/split_store.dart';
import 'features/dashboard/screens/dashboard_screen.dart';
import 'features/ocr_scanner/screens/scanner_screen.dart';
import 'features/bill_editor/screens/bill_editor_screen.dart';
import 'features/bill_editor/screens/create_split_dialog.dart';
import 'features/ringkasan/screens/ringkasan_screen.dart';
import 'features/riwayat/screens/riwayat_screen.dart';
import 'features/pengaturan/screens/pengaturan_screen.dart';
import 'features/onboarding/widgets/feature_tutorial_overlay.dart';

import 'core/utils/receipt_parser.dart';

class MainNavigation extends StatefulWidget {
  /// Bila true, tutorial pengenalan ditampilkan langsung di atas app
  /// (menyorot tombol kamera & tab navigasi) untuk pengguna baru.
  final bool showFeatureTutorial;

  const MainNavigation({super.key, this.showFeatureTutorial = false});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  bool _isScannerOpen = false;
  bool _isEditingBill = false;

  // Kunci elemen yang dijelaskan oleh tutorial fitur.
  final GlobalKey _cameraButtonKey = GlobalKey();
  final GlobalKey _homeTabKey = GlobalKey();
  final GlobalKey _historyTabKey = GlobalKey();
  final GlobalKey _summaryTabKey = GlobalKey();
  final GlobalKey _settingsTabKey = GlobalKey();

  late bool _tutorialVisible = widget.showFeatureTutorial;

  static final _emptyFallbackSplit = SplitBill(
    id: 'empty_default',
    title: 'Belum Ada Struk Belanja',
    category: 'Tap + Struk Baru untuk mulai',
    date: DateTime.now(),
    subtotal: 0,
    tax: 0,
    serviceCharge: 0,
    discount: 0,
    totalAmount: 0,
    isCompleted: true,
    members: [],
    items: [],
  );

  /// Split yang sedang dibuka di editor / disorot dashboard.
  SplitBill get currentSelectedSplit {
    final selected = SplitStore.instance.selected;
    if (selected != null) return selected;
    final splits = SplitStore.instance.splits;
    return splits.isNotEmpty ? splits.first : _emptyFallbackSplit;
  }

  @override
  void initState() {
    super.initState();
    SplitStore.instance.load();
  }

  void _openCreateSplitBottomSheet({ParsedReceiptResult? prefill}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      // Amankan area atas (status bar) agar header dialog + tombol X selalu
      // terlihat; keyboard & navbar sistem ditangani di dalam CreateSplitDialog.
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return CreateSplitDialog(
          initialTitle: prefill?.merchantName,
          initialItems: prefill?.items,
          onCreateSplit: (newSplit) async {
            await SplitStore.instance.add(newSplit);
          },
        );
      },
    );
  }

  Future<void> _finishTutorial() async {
    await SettingsService.instance.markTutorialSeen();
    if (mounted) setState(() => _tutorialVisible = false);
  }

  @override
  Widget build(BuildContext context) {
    // 1. Full Screen Scanner Overlay
    if (_isScannerOpen) {
      return ScannerScreen(
        onClose: () => setState(() => _isScannerOpen = false),
        onScanWithResult: (parsed) {
          setState(() {
            _isScannerOpen = false;
          });
          _openCreateSplitBottomSheet(prefill: parsed);
        },
        onScanComplete: () {
          setState(() {
            _isScannerOpen = false;
          });
          _openCreateSplitBottomSheet();
        },
      );
    }

    // 2. Full Screen Bill & Member Assignment Editor
    if (_isEditingBill) {
      return BillEditorScreen(
        splitBill: currentSelectedSplit,
        onBack: () => setState(() => _isEditingBill = false),
        onSaveAndContinue: (updatedSplit) async {
          await SplitStore.instance.update(updatedSplit);
          if (mounted) {
            setState(() {
              _isEditingBill = false;
              _currentIndex = 2; // Open Summary tab
            });
          }
        },
        onDeleteSplit: (id) async {
          await SplitStore.instance.delete(id);
          if (mounted) setState(() => _isEditingBill = false);
        },
      );
    }

    return ListenableBuilder(
      listenable: SplitStore.instance,
      builder: (context, _) {
        final store = SplitStore.instance;
        final screens = [
          DashboardScreen(
            splits: store.splits,
            activeFeaturedSplit: currentSelectedSplit,
            onOpenScanner: () => setState(() => _isScannerOpen = true),
            onCreateNewSplit: _openCreateSplitBottomSheet,
            onSelectSplit: (split) {
              SplitStore.instance.select(split);
              setState(() => _isEditingBill = true);
            },
          ),
          RiwayatScreen(
            splits: store.splits,
            onSelectSplit: (split) {
              SplitStore.instance.select(split);
              setState(() => _currentIndex = 2); // Switch to Ringkasan
            },
            onDeleteSplit: (id) async {
              await SplitStore.instance.delete(id);
            },
          ),
          RingkasanScreen(
            splitBill: store.summarySplit ?? _emptyFallbackSplit,
            onBack: () => setState(() => _currentIndex = 0),
            onDeleteSplit: (id) async {
              await SplitStore.instance.delete(id);
            },
            onAllPaid: () => setState(() => _currentIndex = 0),
            onUpdateSplit: (updated) async {
              await SplitStore.instance.update(updated);
              // Sudah lunas: Summary tidak lagi menampilkan split ini
              // (otomatis beralih ke split aktif lain / keadaan kosong).
              if (updated.isCompleted) {
                SplitStore.instance.select(null);
              }
            },
          ),
          PengaturanScreen(
            onShowTutorial: () {
              if (mounted) setState(() => _tutorialVisible = true);
            },
          ),
        ];
        return Stack(
          children: [
            Scaffold(
              body: IndexedStack(index: _currentIndex, children: screens),
              bottomNavigationBar: SafeArea(
                child: Container(
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    border: Border(
                      top: BorderSide(
                        color: AppColors.borderBlack,
                        width: AppColors.borderWidth,
                      ),
                    ),
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildNavItem(
                            0,
                            icon: Icons.home_rounded,
                            label: tr('nav_home'),
                            key: _homeTabKey,
                          ),
                          _buildNavItem(
                            1,
                            icon: Icons.history_rounded,
                            label: tr('nav_history'),
                            key: _historyTabKey,
                          ),
                          const SizedBox(width: 52), // Safe center gap
                          _buildNavItem(
                            2,
                            icon: Icons.bar_chart_rounded,
                            label: tr('nav_summary'),
                            key: _summaryTabKey,
                          ),
                          _buildNavItem(
                            3,
                            icon: Icons.settings_rounded,
                            label: tr('nav_settings'),
                            key: _settingsTabKey,
                          ),
                        ],
                      ),

                      // Central Floating Camera Button
                      Positioned(
                        top: -22,
                        child: GestureDetector(
                          key: _cameraButtonKey,
                          onTap: () => setState(() => _isScannerOpen = true),
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: AppColors.primaryContainer,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.borderBlack,
                                width: AppColors.borderWidth,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.borderBlack,
                                  offset: Offset(2.5, 2.5),
                                  blurRadius: 0,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Icon(
                                Icons.document_scanner_rounded,
                                size: 28,
                                color: AppColors.onPrimaryContainer,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Tutorial pengenalan langsung di dalam app (pengguna baru)
            if (_tutorialVisible)
              FeatureTutorialOverlay(
                steps: [
                  FeatureTutorialStep(
                    key: _cameraButtonKey,
                    titleKey: 'tut2_scan_title',
                    descKey: 'tut2_scan_desc',
                  ),
                  FeatureTutorialStep(
                    key: _homeTabKey,
                    titleKey: 'tut2_home_title',
                    descKey: 'tut2_home_desc',
                  ),
                  FeatureTutorialStep(
                    key: _historyTabKey,
                    titleKey: 'tut2_history_title',
                    descKey: 'tut2_history_desc',
                  ),
                  FeatureTutorialStep(
                    key: _summaryTabKey,
                    titleKey: 'tut2_summary_title',
                    descKey: 'tut2_summary_desc',
                  ),
                  FeatureTutorialStep(
                    key: _settingsTabKey,
                    titleKey: 'tut2_settings_title',
                    descKey: 'tut2_settings_desc',
                  ),
                ],
                onFinish: _finishTutorial,
              ),
          ],
        );
      },
    );
  }

  Widget _buildNavItem(
    int index, {
    required IconData icon,
    required String label,
    GlobalKey? key,
  }) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      key: key,
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isSelected ? AppColors.onSurface : AppColors.outline,
            size: isSelected ? 26 : 24,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected ? AppColors.onSurface : AppColors.outline,
            ),
          ),
        ],
      ),
    );
  }
}
