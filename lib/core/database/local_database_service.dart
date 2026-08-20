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

  /// Mengosongkan penyimpanan lokal (Kembali ke database asli yang bersih / 0 data dummy).
  Future<void> clearAllData() async {
    await saveSplits([]);
  }

  /// Mereset database lokal ke data contoh demo.
  Future<List<SplitBill>> resetToDefaultDemo() async {
    await saveSplits(mockSplitBills);
    return List.from(mockSplitBills);
  }
}
