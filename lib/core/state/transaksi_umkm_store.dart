import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/demo_umkm.dart';
import '../models/transaksi_umkm.dart';

class TransaksiUmkmStore extends ChangeNotifier {
  TransaksiUmkmStore._();

  static final TransaksiUmkmStore instance = TransaksiUmkmStore._();

  List<TransaksiUmkm> _transaksi = [];
  bool _isLoading = true;

  List<TransaksiUmkm> get transaksi => List.unmodifiable(_transaksi);
  bool get isLoading => _isLoading;

  /// Semua kategori unik yang pernah dipakai (untuk autocomplete).
  List<String> get existingCategories {
    final cats = <String>{};
    for (final t in _transaksi) {
      if (t.category.isNotEmpty) cats.add(t.category);
    }
    return cats.toList()..sort();
  }

  /// Filter transaksi berdasarkan rentang tanggal.
  List<TransaksiUmkm> transactionsInRange(DateTime start, DateTime end) {
    return _transaksi.where((t) {
      final d = t.date;
      return !d.isBefore(start) && !d.isAfter(end);
    }).toList();
  }

  /// Total omzet hari ini.
  double get todayRevenue {
    final now = DateTime.now();
    return _transaksi
        .where((t) =>
            t.date.year == now.year &&
            t.date.month == now.month &&
            t.date.day == now.day)
        .fold(0.0, (sum, t) => sum + t.totalAmount);
  }

  /// Total omzet bulan ini.
  double get monthRevenue {
    final now = DateTime.now();
    return _transaksi
        .where((t) => t.date.year == now.year && t.date.month == now.month)
        .fold(0.0, (sum, t) => sum + t.totalAmount);
  }

  /// Jumlah transaksi hari ini.
  int get todayCount {
    final now = DateTime.now();
    return _transaksi
        .where((t) =>
            t.date.year == now.year &&
            t.date.month == now.month &&
            t.date.day == now.day)
        .length;
  }

  /// Top items: (name, qty, revenue).
  List<({String name, int qty, double revenue})> topItems({int limit = 5}) {
    final itemCounts = <String, int>{};
    final itemRevenue = <String, double>{};
    for (final t in _transaksi) {
      for (final i in t.items) {
        itemCounts[i.name] = (itemCounts[i.name] ?? 0) + i.quantity;
        itemRevenue[i.name] = (itemRevenue[i.name] ?? 0) + i.lineTotal;
      }
    }
    final list = itemCounts.entries
        .map((e) => (name: e.key, qty: e.value, revenue: itemRevenue[e.key] ?? 0))
        .toList()
      ..sort((a, b) => b.qty.compareTo(a.qty));
    return list.take(limit).toList();
  }

  /// Revenue per bulan untuk 6 bulan terakhir: (label, total).
  List<({String label, double total})> monthlyRevenue({int months = 6}) {
    final now = DateTime.now();
    final result = <({String label, double total})>[];
    for (var i = months - 1; i >= 0; i--) {
      final m = DateTime(now.year, now.month - i, 1);
      final total = _transaksi
          .where((t) => t.date.year == m.year && t.date.month == m.month)
          .fold(0.0, (sum, t) => sum + t.totalAmount);
      final label = '${m.month}/${m.year.toString().substring(2)}';
      result.add((label: label, total: total));
    }
    return result;
  }

  /// Revenue per kategori: (category, total).
  List<({String category, double total})> categoryBreakdown() {
    final catMap = <String, double>{};
    for (final t in _transaksi) {
      final cat = t.category.isNotEmpty ? t.category : 'Lainnya';
      catMap[cat] = (catMap[cat] ?? 0) + t.totalAmount;
    }
    return catMap.entries
        .map((e) => (category: e.key, total: e.value))
        .toList()
      ..sort((a, b) => b.total.compareTo(a.total));
  }

  /// Menu profitability: (name, qty, revenue, cost, profit, margin).
  List<({String name, int qty, double revenue, double cost, double profit, double margin})>
      menuProfitability({int limit = 10}) {
    final items = <String, ({int qty, double revenue, double cost})>{};
    for (final t in _transaksi) {
      for (final i in t.items) {
        final existing = items[i.name];
        items[i.name] = (
          qty: (existing?.qty ?? 0) + i.quantity,
          revenue: (existing?.revenue ?? 0) + i.lineTotal,
          cost: (existing?.cost ?? 0) + i.lineCost,
        );
      }
    }
    final list = items.entries.map((e) {
      final profit = e.value.revenue - e.value.cost;
      final margin = e.value.revenue > 0 ? (profit / e.value.revenue * 100) : 0.0;
      return (
        name: e.key,
        qty: e.value.qty,
        revenue: e.value.revenue,
        cost: e.value.cost,
        profit: profit,
        margin: margin,
      );
    }).toList()
      ..sort((a, b) => b.profit.compareTo(a.profit));
    return list.take(limit).toList();
  }

  /// Total profit bulan ini.
  double get monthProfit {
    final now = DateTime.now();
    double profit = 0;
    for (final t in _transaksi) {
      if (t.date.year == now.year && t.date.month == now.month) {
        for (final i in t.items) {
          profit += i.profit;
        }
      }
    }
    return profit;
  }

  /// Total profit hari ini.
  double get todayProfit {
    final now = DateTime.now();
    double profit = 0;
    for (final t in _transaksi) {
      if (t.date.year == now.year &&
          t.date.month == now.month &&
          t.date.day == now.day) {
        for (final i in t.items) {
          profit += i.profit;
        }
      }
    }
    return profit;
  }

  /// Daily revenue for last N days: (label, total).
  List<({String label, double total})> dailyRevenue({int days = 7}) {
    final now = DateTime.now();
    final result = <({String label, double total})>[];
    for (var i = days - 1; i >= 0; i--) {
      final d = DateTime(now.year, now.month, now.day - i);
      final total = _transaksi
          .where((t) =>
              t.date.year == d.year &&
              t.date.month == d.month &&
              t.date.day == d.day)
          .fold(0.0, (sum, t) => sum + t.totalAmount);
      final label = '${d.day}/${d.month}';
      result.add((label: label, total: total));
    }
    return result;
  }

  /// Hourly distribution today: (hour, count).
  List<({int hour, int count})> hourlyDistribution() {
    final now = DateTime.now();
    final hours = List.filled(24, 0);
    for (final t in _transaksi) {
      if (t.date.year == now.year &&
          t.date.month == now.month &&
          t.date.day == now.day) {
        hours[t.date.hour]++;
      }
    }
    return hours
        .asMap()
        .entries
        .where((e) => e.value > 0)
        .map((e) => (hour: e.key, count: e.value))
        .toList();
  }

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('transaksi_umkm') ?? '[]';
      try {
        final list = jsonDecode(raw) as List<dynamic>;
        _transaksi = list
            .map((e) => TransaksiUmkm.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (e) {
        debugPrint('TransaksiUmkmStore.load: $e');
        _transaksi = [];
      }
    } catch (e) {
      debugPrint('TransaksiUmkmStore.load prefs: $e');
      _transaksi = [];
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> add(TransaksiUmkm t) async {
    _transaksi.insert(0, t);
    notifyListeners();
    await _persist();
  }

  Future<void> update(TransaksiUmkm updated) async {
    final idx = _transaksi.indexWhere((t) => t.id == updated.id);
    if (idx == -1) return;
    _transaksi[idx] = updated;
    notifyListeners();
    await _persist();
  }

  Future<void> delete(String id) async {
    _transaksi.removeWhere((t) => t.id == id);
    notifyListeners();
    await _persist();
  }

  Future<void> clearAll() async {
    _transaksi = [];
    notifyListeners();
    await _persist();
  }

  Future<void> loadDemo() async {
    _isLoading = true;
    notifyListeners();
    // Import dilakukan di sini untuk menghindari circular dependency.
    final demo = mockUmkmTransactions;
    _transaksi = List.from(demo);
    _isLoading = false;
    notifyListeners();
    await _persist();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(_transaksi.map((t) => t.toJson()).toList());
    await prefs.setString('transaksi_umkm', raw);
  }
}
