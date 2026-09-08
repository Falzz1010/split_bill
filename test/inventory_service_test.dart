import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fairsplit/core/services/inventory_service.dart';

InventoryItem _item(String id, {int stock = 50, int min = 10, int max = 100, double cost = 0}) =>
    InventoryItem(
      id: id,
      name: 'Item $id',
      currentStock: stock,
      minStock: min,
      maxStock: max,
      unitCost: cost,
    );

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await InventoryService.instance.load();
  });

  group('InventoryItem properties', () {
    test('isLow when stock <= minStock', () {
      final item = _item('a', stock: 10, min: 10);
      expect(item.isLow, true);
    });

    test('isLow false when stock > minStock', () {
      final item = _item('a', stock: 11, min: 10);
      expect(item.isLow, false);
    });

    test('isCritical when stock <= minStock * 0.5', () {
      final item = _item('a', stock: 4, min: 10);
      expect(item.isCritical, true);
    });

    test('isCritical false when stock > minStock * 0.5', () {
      final item = _item('a', stock: 6, min: 10);
      expect(item.isCritical, false);
    });

    test('stockPercent', () {
      final item = _item('a', stock: 50, max: 100);
      expect(item.stockPercent, 50.0);
    });

    test('stockPercent clamps to 100', () {
      final item = _item('a', stock: 150, max: 100);
      expect(item.stockPercent, 100);
    });

    test('stockPercent zero maxStock returns 0', () {
      final item = _item('a', stock: 10, max: 0);
      expect(item.stockPercent, 0);
    });

    test('daysUntilEmpty', () {
      final item = _item('a', stock: 30);
      expect(item.daysUntilEmpty(10), 3);
    });

    test('daysUntilEmpty zero sales returns 999', () {
      final item = _item('a', stock: 30);
      expect(item.daysUntilEmpty(0), 999);
    });

    test('copyWith preserves id', () {
      final item = _item('a', stock: 50);
      final copy = item.copyWith(currentStock: 80);
      expect(copy.id, 'a');
      expect(copy.currentStock, 80);
    });

    test('toJson/fromJson round trip', () {
      final item = _item('a', stock: 42, cost: 5000);
      final json = item.toJson();
      final restored = InventoryItem.fromJson(json);
      expect(restored.id, 'a');
      expect(restored.currentStock, 42);
      expect(restored.unitCost, 5000);
    });
  });

  group('CRUD', () {
    test('add item', () async {
      final svc = InventoryService.instance;
      await svc.add(_item('x'));
      expect(svc.items.length, 1);
      expect(svc.items.first.id, 'x');
    });

    test('update item', () async {
      final svc = InventoryService.instance;
      await svc.add(_item('x', stock: 10));
      await svc.update(_item('x', stock: 99));
      expect(svc.items.first.currentStock, 99);
    });

    test('update non-existent item does nothing', () async {
      final svc = InventoryService.instance;
      await svc.update(_item('ghost'));
      expect(svc.items, isEmpty);
    });

    test('delete item', () async {
      final svc = InventoryService.instance;
      await svc.add(_item('x'));
      await svc.delete('x');
      expect(svc.items, isEmpty);
    });

    test('delete non-existent item does nothing', () async {
      final svc = InventoryService.instance;
      await svc.delete('ghost');
      expect(svc.items, isEmpty);
    });

    test('adjustStock increases', () async {
      final svc = InventoryService.instance;
      await svc.add(_item('x', stock: 10));
      await svc.adjustStock('x', 5);
      expect(svc.items.first.currentStock, 15);
    });

    test('adjustStock decreases', () async {
      final svc = InventoryService.instance;
      await svc.add(_item('x', stock: 10));
      await svc.adjustStock('x', -3);
      expect(svc.items.first.currentStock, 7);
    });

    test('adjustStock clamps at zero', () async {
      final svc = InventoryService.instance;
      await svc.add(_item('x', stock: 5));
      await svc.adjustStock('x', -10);
      expect(svc.items.first.currentStock, 0);
    });
  });

  group('alerts', () {
    test('lowStockItems returns items at or below min', () async {
      final svc = InventoryService.instance;
      await svc.add(_item('low', stock: 5, min: 10));
      await svc.add(_item('ok', stock: 50, min: 10));
      expect(svc.lowStockItems.length, 1);
      expect(svc.lowStockItems.first.id, 'low');
    });

    test('criticalItems returns items at or below half min', () async {
      final svc = InventoryService.instance;
      await svc.add(_item('crit', stock: 3, min: 10));
      await svc.add(_item('low', stock: 8, min: 10));
      expect(svc.criticalItems.length, 1);
      expect(svc.criticalItems.first.id, 'crit');
    });

    test('reorderSuggestions includes reason', () async {
      final svc = InventoryService.instance;
      await svc.add(_item('crit', stock: 3, min: 10, max: 100));
      final suggestions = svc.reorderSuggestions;
      expect(suggestions.length, 1);
      expect(suggestions.first.reason, 'Stok kritis!');
      expect(suggestions.first.suggestedOrder, 97);
    });
  });

  group('analytics', () {
    test('totalInventoryValue', () async {
      final svc = InventoryService.instance;
      await svc.add(_item('a', stock: 10, cost: 1000));
      await svc.add(_item('b', stock: 5, cost: 2000));
      expect(svc.totalInventoryValue, 20000);
    });

    test('lowStockValue', () async {
      final svc = InventoryService.instance;
      await svc.add(_item('low', stock: 3, min: 10, cost: 1000));
      await svc.add(_item('ok', stock: 50, min: 10, cost: 1000));
      expect(svc.lowStockValue, 3000);
    });
  });

  group('persistence', () {
    test('items survive load()', () async {
      final svc = InventoryService.instance;
      await svc.add(_item('persist'));
      await svc.load();
      expect(svc.items.length, 1);
      expect(svc.items.first.id, 'persist');
    });
  });
}
