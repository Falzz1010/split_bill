import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/demo_splits.dart';
import '../models/split_model.dart';

class LocalDatabaseService {
  static const String _splitsKey = 'fairsplit_local_splits_v1';
  static LocalDatabaseService? _instance;

  LocalDatabaseService._();

  static LocalDatabaseService get instance {
    _instance ??= LocalDatabaseService._();
    return _instance!;
  }

  /// Memuat daftar split bill dari penyimpanan lokal HP (Default: Database Kosong Murni).
  /// Data korup tidak dihapus diam-diam: item yang gagal di-parse dilewati dan
  /// dicatat via [debugPrint], sisanya tetap dimuat.
  Future<List<SplitBill>> loadSplits() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_splitsKey);

      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }

      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      final splits = <SplitBill>[];
      for (final item in jsonList) {
        try {
          splits.add(SplitBill.fromJson(item as Map<String, dynamic>));
        } catch (e) {
          debugPrint('LocalDatabaseService: lewati data korup saat load: $e');
        }
      }
      return splits;
    } catch (e) {
      debugPrint('LocalDatabaseService: gagal membaca data lokal: $e');
      return [];
    }
  }

  /// Menyimpan seluruh list split bill langsung ke dalam memori lokal HP (APK storage).
  /// Kegagalan dicatat (bukan ditelan) supaya bisa dilacak.
  // ponytail: satu string JSON di SharedPreferences ditulis ulang penuh tiap operasi;
  // ceiling ~ratusan struk, migrasi ke sqlite/isar bila melebihi 500 struk.
  Future<bool> saveSplits(List<SplitBill> splits) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(splits.map((s) => s.toJson()).toList());
      return await prefs.setString(_splitsKey, jsonString);
    } catch (e) {
      debugPrint('LocalDatabaseService: gagal menyimpan data lokal: $e');
      return false;
    }
  }

  /// Menambahkan split bill baru ke dalam penyimpanan lokal APK.
  Future<List<SplitBill>> addSplit(SplitBill newSplit) async {
    final currentSplits = await loadSplits();
    currentSplits.insert(0, newSplit);
    await saveSplits(currentSplits);
    return currentSplits;
  }

  /// Memperbarui split bill (misal: ubah item, status pelunasan anggota) secara permanen di HP.
  Future<List<SplitBill>> updateSplit(SplitBill updatedSplit) async {
    final currentSplits = await loadSplits();
    final index = currentSplits.indexWhere((s) => s.id == updatedSplit.id);

    if (index != -1) {
      currentSplits[index] = updatedSplit;
    } else {
      currentSplits.insert(0, updatedSplit);
    }

    await saveSplits(currentSplits);
    return currentSplits;
  }

  /// Menghapus split bill tertentu dari penyimpanan lokal.
  Future<List<SplitBill>> deleteSplit(String splitId) async {
    final currentSplits = await loadSplits();
    currentSplits.removeWhere((s) => s.id == splitId);
    await saveSplits(currentSplits);
    return currentSplits;
  }

  /// Membersihkan seluruh data (Kembali ke database asli yang bersih / 0 data dummy).
  Future<List<SplitBill>> clearAllData() async {
    await saveSplits([]);
    return [];
  }

  /// Mereset database lokal ke data contoh demo.
  Future<List<SplitBill>> resetToDefaultDemo() async {
    await saveSplits(mockSplitBills);
    return List.from(mockSplitBills);
  }
}
