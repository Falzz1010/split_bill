import 'package:flutter/foundation.dart';
import '../database/local_database_service.dart';
import '../models/split_model.dart';

/// Menampung daftar split bill + pilihan aktif, dan menjadi satu-satunya
/// sumber kebenaran data split di seluruh tab. Layar cukup memanggil method
/// di sini; UI (MainNavigation) mendengarkan [ChangeNotifier] untuk rebuild.
class SplitStore extends ChangeNotifier {
  SplitStore._();

  static final SplitStore instance = SplitStore._();

  List<SplitBill> _splits = [];
  SplitBill? _selected;

  List<SplitBill> get splits => List.unmodifiable(_splits);

  /// Split yang sedang disorot (Featured di Dashboard / dibuka di Editor).
  SplitBill? get selected => _selected;

  /// Split untuk tab Summary: pilihan eksplisit (mis. dari Riwayat, boleh
  /// sudah lunas), atau split aktif pertama (belum lunas), atau null.
  SplitBill? get summarySplit {
    if (_selected != null) return _selected;
    final active = _splits.where((s) => !s.isCompleted).toList();
    return active.isNotEmpty ? active.first : null;
  }

  Future<void> load() async {
    _splits = await LocalDatabaseService.instance.loadSplits();
    _selected = _splits.isNotEmpty ? _splits.first : null;
    notifyListeners();
  }

  Future<void> add(SplitBill split) async {
    _splits = await LocalDatabaseService.instance.addSplit(split);
    _selected = split;
    notifyListeners();
  }

  /// Simpan perubahan split. Split yang sudah lunas tidak lagi dipilih
  /// sebagai summary — panggil [select] dengan null setelahnya bila perlu.
  Future<void> update(SplitBill split) async {
    _splits = await LocalDatabaseService.instance.updateSplit(split);
    _selected = split;
    notifyListeners();
  }

  Future<void> delete(String id) async {
    _splits = await LocalDatabaseService.instance.deleteSplit(id);
    if (_selected?.id == id) {
      _selected = _splits.isNotEmpty ? _splits.first : null;
    }
    notifyListeners();
  }

  Future<void> clearAll() async {
    _splits = await LocalDatabaseService.instance.clearAllData();
    _selected = null;
    notifyListeners();
  }

  Future<void> loadDemo() async {
    _splits = await LocalDatabaseService.instance.resetToDefaultDemo();
    _selected = _splits.isNotEmpty ? _splits.first : null;
    notifyListeners();
  }

  void select(SplitBill? split) {
    _selected = split;
    notifyListeners();
  }
}
