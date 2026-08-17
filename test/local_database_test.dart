import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fairsplit/core/database/local_database_service.dart';
import 'package:fairsplit/core/models/split_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final split = SplitBill(
    id: 'split_test_1',
    title: 'Kopi Kenangan',
    category: '1 Anggota • Resto & Cafe',
    date: DateTime(2026, 8, 14),
    subtotal: 35000,
    tax: 3850,
    serviceCharge: 0,
    discount: 0,
    totalAmount: 38850,
    isCompleted: false,
    members: [
      Member(id: 'm1', name: 'Saya', avatarUrl: '', accentColorHex: '#FFCD00', isPaid: false, amountOwed: 38850),
    ],
    items: [
      ReceiptItem(id: 'i1', name: 'Kopi Susu Gula Aren', price: 35000, quantity: 1, assignedMemberIds: ['m1']),
    ],
  );

  test('data tersimpan dan termuat ulang setelah refresh (round-trip)', () async {
    SharedPreferences.setMockInitialValues({});

    await LocalDatabaseService.instance.addSplit(split);
    final loaded = await LocalDatabaseService.instance.loadSplits();

    expect(loaded.length, 1);
    expect(loaded.first.id, 'split_test_1');
    expect(loaded.first.title, 'Kopi Kenangan');
    expect(loaded.first.items.length, 1);
    expect(loaded.first.items.first.name, 'Kopi Susu Gula Aren');
    expect(loaded.first.items.first.price, 35000);
    expect(loaded.first.members.first.name, 'Saya');
    expect(loaded.first.members.first.amountOwed, 38850);
    expect(loaded.first.totalAmount, 38850);
  });

  test('data tetap ada saat service dibuat ulang (simulasi restart aplikasi)', () async {
    SharedPreferences.setMockInitialValues({});

    await LocalDatabaseService.instance.saveSplits([split]);

    final freshService = LocalDatabaseService.instance;
    final loaded = await freshService.loadSplits();
    expect(loaded.length, 1);
    expect(loaded.first.items.first.name, 'Kopi Susu Gula Aren');
  });

  test('clearAllData mengosongkan dan loadSplits kembali kosong', () async {
    SharedPreferences.setMockInitialValues({});

    await LocalDatabaseService.instance.addSplit(split);
    await LocalDatabaseService.instance.clearAllData();

    final loaded = await LocalDatabaseService.instance.loadSplits();
    expect(loaded, isEmpty);
  });
}