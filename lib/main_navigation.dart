import 'package:flutter/material.dart';
import 'core/settings/settings_service.dart';
import 'core/utils/app_l10n.dart';
import 'core/theme/app_colors.dart';
import 'core/models/split_model.dart';
import 'core/models/transaksi_umkm.dart';
import 'core/state/split_store.dart';
import 'core/state/transaksi_umkm_store.dart';
import 'features/dashboard/screens/dashboard_screen.dart';
import 'features/ocr_scanner/screens/scanner_screen.dart';
import 'features/bill_editor/screens/bill_editor_screen.dart';
import 'features/bill_editor/screens/create_split_dialog.dart';
import 'features/ringkasan/screens/ringkasan_screen.dart';
import 'features/riwayat/screens/riwayat_screen.dart';
import 'features/pengaturan/screens/pengaturan_screen.dart';
import 'features/onboarding/widgets/feature_tutorial_overlay.dart';
import 'features/umkm/screens/umkm_dashboard_screen.dart';
import 'features/umkm/screens/umkm_transaksi_list_screen.dart';
import 'features/umkm/screens/umkm_insight_screen.dart';
import 'features/umkm/screens/umkm_inventory_screen.dart';
import 'features/umkm/widgets/kasir_dialog.dart';

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

  /// Placeholder kosong — ID sengaja unik (bukan ID data valid) supaya
  /// tidak pernah bentrok dengan split nyata. Digunakan HANYA sebagai
  /// fallback saat daftar split masih kosong (fresh install / setelah clear).
  static final _emptyFallbackSplit = SplitBill(
    id: '__empty_fallback__',
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
  /// Mengembalikan [_emptyFallbackSplit] bila belum ada data —
  /// layar harus memeriksa `splits.isEmpty` untuk menampilkan empty state.
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
    TransaksiUmkmStore.instance.load();
  }

  void _openCreateSplitBottomSheet({ParsedReceiptResult? prefill}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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

  void _openKasirDialog({
    required String merchantName,
    required List<TransaksiItem> items,
    required double subtotal,
    required double ppn,
    required double serviceCharge,
    required double totalAmount,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return KasirDialog(
          merchantName: merchantName,
          items: items,
          subtotal: subtotal,
          ppn: ppn,
          serviceCharge: serviceCharge,
          totalAmount: totalAmount,
          onConfirm: (transaksi) async {
            await TransaksiUmkmStore.instance.add(transaksi);
          },
        );
      },
    );
  }

  // Tab yang sedang menampilkan skeleton & yang sudah pernah menampilkannya.
  // ponytail: skeleton durasi tampilan (1,2s) saat tab pertama kali dibuka —
  // hapus bila data menjadi benar-benar lambat dimuat.
  final Set<int> _skeletonTabs = {};
  final Set<int> _visitedTabs = {};

  /// Simulasi scan UMKM untuk testing tanpa kamera.
  void _testScanUmkm() {
    final items = [
      TransaksiItem(id: '1', name: 'Nasi Goreng Spesial', price: 25000, quantity: 1),
      TransaksiItem(id: '2', name: 'Ayam Bakar Madu', price: 28000, quantity: 2),
      TransaksiItem(id: '3', name: 'Es Teh Manis', price: 8000, quantity: 1),
      TransaksiItem(id: '4', name: 'Kerupuk', price: 5000, quantity: 1),
    ];
    final subtotal = items.fold(0.0, (sum, i) => sum + i.lineTotal);
    final ppn = subtotal * 0.1;
    final service = 5000.0;
    final total = subtotal + ppn + service;

    _openKasirDialog(
      merchantName: 'Warung Nusantara',
      items: items,
      subtotal: subtotal,
      ppn: ppn,
      serviceCharge: service,
      totalAmount: total,
    );
  }

  void _selectTab(int index) {
    setState(() {
      _currentIndex = index;
      if (!_visitedTabs.contains(index) && (index == 1 || index == 2)) {
        _visitedTabs.add(index);
        _skeletonTabs.add(index);
        Future.delayed(const Duration(milliseconds: 1200), () {
          if (mounted) setState(() => _skeletonTabs.remove(index));
        });
      }
    });
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
          setState(() { _isScannerOpen = false; });
          final mode = SettingsService.instance.appMode;
          if (mode == AppMode.umkm) {
            // UMKM: convert ReceiptItem → TransaksiItem, open KasirDialog.
            final items = parsed.items.map((i) => TransaksiItem(
              id: i.id, name: i.name, price: i.price, quantity: i.quantity,
            )).toList();
            final subtotal = items.fold(0.0, (s, i) => s + i.lineTotal);
            final ppn = subtotal * 0.11;
            final service = 5000.0;
            _openKasirDialog(
              merchantName: parsed.merchantName,
              items: items,
              subtotal: subtotal,
              ppn: ppn,
              serviceCharge: service,
              totalAmount: subtotal + ppn + service,
            );
          } else {
            _openCreateSplitBottomSheet(prefill: parsed);
          }
        },
        onScanComplete: () {
          setState(() { _isScannerOpen = false; });
          final mode = SettingsService.instance.appMode;
          if (mode == AppMode.umkm) {
            _testScanUmkm();
          } else {
            _openCreateSplitBottomSheet();
          }
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
      listenable: Listenable.merge([SplitStore.instance, SettingsService.instance]),
      builder: (context, _) {
        final c = context.palette;
        final store = SplitStore.instance;
        final mode = SettingsService.instance.appMode;

        // Personal mode screens: [Dashboard, Riwayat, Ringkasan, Pengaturan]
        // UMKM mode screens: [Kasir (Scanner), Dashboard Omzet, Laporan Shift, Pengaturan]
        final personalScreens = [
          DashboardScreen(
            splits: store.splits,
            activeFeaturedSplit: currentSelectedSplit,
            isLoading: store.isLoading,
            onOpenScanner: () => setState(() => _isScannerOpen = true),
            onCreateNewSplit: _openCreateSplitBottomSheet,
            onSelectSplit: (split) {
              SplitStore.instance.select(split);
              setState(() => _isEditingBill = true);
            },
          ),
          RiwayatScreen(
            splits: store.splits,
            isLoading: store.isLoading || _skeletonTabs.contains(1),
            onSelectSplit: (split) {
              SplitStore.instance.select(split);
              setState(() => _currentIndex = 2);
            },
            onDeleteSplit: (id) async {
              await SplitStore.instance.delete(id);
            },
          ),
          RingkasanScreen(
            splitBill: store.summarySplit ?? _emptyFallbackSplit,
            isLoading: store.isLoading || _skeletonTabs.contains(2),
            onBack: () => setState(() => _currentIndex = 0),
            onDeleteSplit: (id) async {
              await SplitStore.instance.delete(id);
            },
            onAllPaid: () => setState(() => _currentIndex = 0),
            onUpdateSplit: (updated) async {
              await SplitStore.instance.update(updated);
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

        final umkmScreens = [
          // Riwayat Transaksi
          const UmkmTransaksiListScreen(),
          // Dashboard Omzet (UMKM version)
          UmkmDashboardScreen(
            onOpenScanner: () => setState(() => _isScannerOpen = true),
            onTestScan: () => _testScanUmkm(),
          ),
          // Scanner (via floating button)
          const SizedBox.shrink(),
          // Inventory
          const UmkmInventoryScreen(),
          // Insight Bisnis (AI)
          const UmkmInsightScreen(),
          PengaturanScreen(
            onShowTutorial: () {
              if (mounted) setState(() => _tutorialVisible = true);
            },
          ),
        ];

        final screens = mode == AppMode.personal ? personalScreens : umkmScreens;
        final navItems = mode == AppMode.personal
            ? _buildPersonalNavItems()
            : _buildUmkmNavItems();
        return Stack(
          children: [
            Scaffold(
              body: IndexedStack(index: _currentIndex.clamp(0, screens.length - 1), children: screens),
              bottomNavigationBar: SafeArea(
                child: Container(
                  height: 72,
                  decoration: BoxDecoration(
                    color: c.surfaceContainerLowest,
                    border: Border(
                      top: BorderSide(
                        color: c.borderBlack,
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
                        children: navItems,
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
                              color: c.primaryContainer,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: c.borderBlack,
                                width: AppColors.borderWidth,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: c.borderBlack,
                                  offset: Offset(2.5, 2.5),
                                  blurRadius: 0,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Icon(
                                Icons.document_scanner_rounded,
                                size: 28,
                                color: c.onPrimaryContainer,
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

  List<Widget> _buildPersonalNavItems() {
    return [
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
    ];
  }

  List<Widget> _buildUmkmNavItems() {
    return [
      _buildNavItem(
        0,
        icon: Icons.receipt_long_rounded,
        label: tr('nav_riwayat'),
        key: _summaryTabKey,
      ),
      _buildNavItem(
        1,
        icon: Icons.dashboard_rounded,
        label: tr('nav_omzet'),
        key: _historyTabKey,
      ),
      const SizedBox(width: 52),
      _buildNavItem(
        3,
        icon: Icons.inventory_2_rounded,
        label: 'Stok',
      ),
      _buildNavItem(
        4,
        icon: Icons.insights_rounded,
        label: 'Insight',
        key: _settingsTabKey,
      ),
      _buildNavItem(
        5,
        icon: Icons.settings_rounded,
        label: tr('nav_settings'),
      ),
    ];
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
      onTap: () => _selectTab(index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isSelected ? context.palette.onSurface : context.palette.outline,
            size: isSelected ? 26 : 24,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected ? context.palette.onSurface : context.palette.outline,
            ),
          ),
        ],
      ),
    );
  }
}
