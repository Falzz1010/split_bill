import 'dart:async';

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
  bool _isLoading = true;

  /// Antrian penulisan ke disk: operasi save dijalankan berurutan sehingga
  /// dua mutasi beruntun tidak bisa menimpa hasil satu sama lain (penulisan
  /// selalu memakai state terbaru).
  Future<void> _pendingSave = Future.value();

  List<SplitBill> get splits => List.unmodifiable(_splits);

  /// True selama data awal belum selesai dimuat — layar menampilkan skeleton.
  bool get isLoading => _isLoading;

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
    // Durasi minimum shimmer agar skeleton terlihat jelas & tak berkedip
    // saat disk sangat cepat; pembacaan disk tetap berjalan paralel.
    // ponytail: delay tampilan — naikkan/turunkan sesuai rasa loading.
    final minShimmer = Future<void>.delayed(const Duration(milliseconds: 1500));
    _splits = await LocalDatabaseService.instance.loadSplits();
    await minShimmer;
    _selected = _splits.isNotEmpty ? _splits.first : null;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> add(SplitBill split) async {
    _splits.insert(0, split);
    _selected = split;
    notifyListeners();
    await _persist();
  }

  /// Simpan perubahan split. Split yang sudah lunas tidak lagi dipilih
  /// sebagai summary — panggil [select] dengan null setelahnya bila perlu.
  Future<void> update(SplitBill split) async {
    final index = _splits.indexWhere((s) => s.id == split.id);
    if (index != -1) {
      _splits[index] = split;
    } else {
      _splits.insert(0, split);
    }
    _selected = split;
    notifyListeners();
    await _persist();
  }

  Future<void> delete(String id) async {
    _splits.removeWhere((s) => s.id == id);
    if (_selected?.id == id) {
      _selected = _splits.isNotEmpty ? _splits.first : null;
    }
    notifyListeners();
    await _persist();
  }

  Future<void> clearAll() async {
    _splits = [];
    _selected = null;
    notifyListeners();
    await _persist();
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

  /// Serialisasi penulisan: setiap save memakai daftar [splits] terbaru dan
  /// antre di belakang penulisan sebelumnya.
  Future<void> _persist() {
    final completer = Completer<void>();
    _pendingSave = _pendingSave
        .then((_) async {
          await LocalDatabaseService.instance.saveSplits(_splits);
        })
        .whenComplete(completer.complete);
    return completer.future;
  }
}
