import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaksi_umkm.dart';

/// Model item inventory.
class InventoryItem {
  final String id;
  final String name;
  final String category;
  final int currentStock;
  final int minStock; // reorder point
  final int maxStock; // capacity
  final double unitCost;
  final String unit; // pcs, kg, liter, etc.
  final DateTime lastUpdated;

  InventoryItem({
    required this.id,
    required this.name,
    this.category = '',
    required this.currentStock,
    this.minStock = 10,
    this.maxStock = 100,
    this.unit = 'pcs',
    this.unitCost = 0,
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  bool get isLow => currentStock <= minStock;
  bool get isCritical => currentStock <= minStock * 0.5;
  bool get isFull => currentStock >= maxStock;

  /// Persentase stok: currentStock / maxStock * 100.
  double get stockPercent => maxStock > 0 ? (currentStock / maxStock * 100).clamp(0, 100) : 0;

  /// Estimasi hari sampai habis (berdasarkan rata-rata penjualan/hari).
  int daysUntilEmpty(int avgDailySales) {
    if (avgDailySales <= 0) return 999;
    return (currentStock / avgDailySales).ceil();
  }

  InventoryItem copyWith({
    String? name,
    String? category,
    int? currentStock,
    int? minStock,
    int? maxStock,
    double? unitCost,
    String? unit,
  }) =>
      InventoryItem(
        id: id,
        name: name ?? this.name,
        category: category ?? this.category,
        currentStock: currentStock ?? this.currentStock,
        minStock: minStock ?? this.minStock,
        maxStock: maxStock ?? this.maxStock,
        unitCost: unitCost ?? this.unitCost,
        unit: unit ?? this.unit,
        lastUpdated: DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'currentStock': currentStock,
        'minStock': minStock,
        'maxStock': maxStock,
        'unitCost': unitCost,
        'unit': unit,
        'lastUpdated': lastUpdated.toIso8601String(),
      };

  factory InventoryItem.fromJson(Map<String, dynamic> json) => InventoryItem(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        category: json['category']?.toString() ?? '',
        currentStock: (json['currentStock'] as int?) ?? 0,
        minStock: (json['minStock'] as int?) ?? 10,
        maxStock: (json['maxStock'] as int?) ?? 100,
        unitCost: (json['unitCost'] as num?)?.toDouble() ?? 0,
        unit: json['unit']?.toString() ?? 'pcs',
        lastUpdated: DateTime.tryParse(json['lastUpdated']?.toString() ?? '') ?? DateTime.now(),
      );
}

/// Inventory Service — tracking stok, reorder alerts, waste estimation.
class InventoryService {
  InventoryService._();
  static final InventoryService instance = InventoryService._();

  List<InventoryItem> _items = [];

  List<InventoryItem> get items => List.unmodifiable(_items);

  // ─── Alerts ──────────────────────────────────────────────────────

  /// Item yang stoknya rendah.
  List<InventoryItem> get lowStockItems =>
      _items.where((i) => i.isLow).toList()..sort((a, b) => a.currentStock.compareTo(b.currentStock));

  /// Item yang stoknya kritis.
  List<InventoryItem> get criticalItems => _items.where((i) => i.isCritical).toList();

  /// Item yang perlu reorder.
  List<({InventoryItem item, int suggestedOrder, String reason})> get reorderSuggestions {
    final result = <({InventoryItem item, int suggestedOrder, String reason})>[];
    for (final item in _items) {
      if (item.isLow) {
        final suggested = item.maxStock - item.currentStock;
        final reason = item.isCritical ? 'Stok kritis!' : 'Stok rendah';
        result.add((item: item, suggestedOrder: suggested, reason: reason));
      }
    }
    return result;
  }

  // ─── Analytics ───────────────────────────────────────────────────

  /// Total nilai inventory: Σ (currentStock × unitCost).
  double get totalInventoryValue {
    return _items.fold(0.0, (s, i) => s + (i.currentStock * i.unitCost));
  }

  /// Total nilai stok rendah.
  double get lowStockValue {
    return lowStockItems.fold(0.0, (s, i) => s + (i.currentStock * i.unitCost));
  }

  /// Waste estimation dari transaksi: item yang dijual di bawah modal.
  List<({String name, int qty, double loss})> wasteEstimate(List<TransaksiUmkm> transactions) {
    final waste = <String, ({int qty, double loss})>{};
    for (final t in transactions) {
      for (final i in t.items) {
        if (i.costPrice > 0 && i.price < i.costPrice) {
          final existing = waste[i.name];
          final qty = (existing?.qty ?? 0) + i.quantity;
          final loss = (existing?.loss ?? 0) + (i.costPrice - i.price) * i.quantity;
          waste[i.name] = (qty: qty, loss: loss);
        }
      }
    }
    return waste.entries
        .map((e) => (name: e.key, qty: e.value.qty, loss: e.value.loss))
        .toList()
      ..sort((a, b) => b.loss.compareTo(a.loss));
  }

  /// Fast-moving items: top N berdasarkan total quantity terjual.
  List<({String name, int totalSold, double revenue})> fastMoving(
    List<TransaksiUmkm> transactions, {
    int limit = 5,
  }) {
    final map = <String, ({int qty, double revenue})>{};
    for (final t in transactions) {
      for (final i in t.items) {
        final existing = map[i.name];
        map[i.name] = (
          qty: (existing?.qty ?? 0) + i.quantity,
          revenue: (existing?.revenue ?? 0) + i.lineTotal,
        );
      }
    }
    return map.entries
        .map((e) => (name: e.key, totalSold: e.value.qty, revenue: e.value.revenue))
        .toList()
      ..sort((a, b) => b.totalSold.compareTo(a.totalSold))
      ..take(limit);
  }

  /// Slow-moving items: items yang jarang terjual.
  List<({String name, int totalSold, int daysSinceLastSale})> slowMoving(
    List<TransaksiUmkm> transactions, {
    int threshold = 2,
  }) {
    final map = <String, ({int qty, DateTime lastSale})>{};
    for (final t in transactions) {
      for (final i in t.items) {
        final existing = map[i.name];
        final lastSale = existing == null ? t.date :
            (t.date.isAfter(existing.lastSale) ? t.date : existing.lastSale);
        map[i.name] = (
          qty: (existing?.qty ?? 0) + i.quantity,
          lastSale: lastSale,
        );
      }
    }

    final now = DateTime.now();
    return map.entries
        .where((e) => e.value.qty <= threshold)
        .map((e) => (
              name: e.key,
              totalSold: e.value.qty,
              daysSinceLastSale: now.difference(e.value.lastSale).inDays,
            ))
        .toList()
      ..sort((a, b) => b.daysSinceLastSale.compareTo(a.daysSinceLastSale));
  }

  // ─── CRUD ────────────────────────────────────────────────────────

  Future<void> add(InventoryItem item) async {
    _items.add(item);
    await _persist();
  }

  Future<void> update(InventoryItem updated) async {
    final idx = _items.indexWhere((i) => i.id == updated.id);
    if (idx == -1) return;
    _items[idx] = updated;
    await _persist();
  }

  Future<void> delete(String id) async {
    _items.removeWhere((i) => i.id == id);
    await _persist();
  }

  Future<void> adjustStock(String id, int delta) async {
    final idx = _items.indexWhere((i) => i.id == id);
    if (idx == -1) return;
    final item = _items[idx];
    _items[idx] = item.copyWith(
      currentStock: (item.currentStock + delta).clamp(0, item.maxStock * 2),
    );
    await _persist();
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('inventory_items') ?? '[]';
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      _items = list.map((e) => InventoryItem.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      _items = [];
    }
  }

  Future<void> loadDemo() async {
    _items = _demoInventory();
    await _persist();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(_items.map((i) => i.toJson()).toList());
    await prefs.setString('inventory_items', raw);
  }

  static List<InventoryItem> _demoInventory() {
    return [
      InventoryItem(id: 'inv1', name: 'Kopi Susu', category: 'Minuman', currentStock: 85, minStock: 20, maxStock: 150, unitCost: 8500, unit: 'pcs'),
      InventoryItem(id: 'inv2', name: 'Croissant', category: 'Snack', currentStock: 12, minStock: 15, maxStock: 50, unitCost: 7000, unit: 'pcs'),
      InventoryItem(id: 'inv3', name: 'Nasi Goreng', category: 'Makanan', currentStock: 45, minStock: 10, maxStock: 80, unitCost: 12000, unit: 'porsi'),
      InventoryItem(id: 'inv4', name: 'Es Teh', category: 'Minuman', currentStock: 5, minStock: 20, maxStock: 100, unitCost: 2000, unit: 'pcs'),
      InventoryItem(id: 'inv5', name: 'Cheesecake', category: 'Snack', currentStock: 30, minStock: 10, maxStock: 40, unitCost: 12000, unit: 'pcs'),
      InventoryItem(id: 'inv6', name: 'Mie Ayam', category: 'Makanan', currentStock: 60, minStock: 15, maxStock: 80, unitCost: 10000, unit: 'porsi'),
      InventoryItem(id: 'inv7', name: 'Air Mineral', category: 'Minuman', currentStock: 3, minStock: 30, maxStock: 100, unitCost: 1500, unit: 'botol'),
      InventoryItem(id: 'inv8', name: 'Roti Garlic', category: 'Snack', currentStock: 22, minStock: 10, maxStock: 40, unitCost: 8000, unit: 'pcs'),
    ];
  }
}
