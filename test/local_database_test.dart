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

    await LocalDatabaseService.instance.saveSplits([split]);
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

    await LocalDatabaseService.instance.saveSplits([split]);
    await LocalDatabaseService.instance.clearAllData();

    final loaded = await LocalDatabaseService.instance.loadSplits();
    expect(loaded, isEmpty);
  });

  test('data dengan field kosong/null dilewati tanpa crash', () async {
    // Tipe salah (title: int) sekarang di-convert ke string via toString()
    // sehingga tidak lagi dilewati — ini intentional: data partially corrupt
    // tetap dimuat dengan default agar user tidak kehilangan data.
    SharedPreferences.setMockInitialValues({
      'fairsplit_local_splits_v1':
          '[{"id":"rusak","title":1,"category":{}},'
          '{"id":"valid","title":"Struk","category":"Kopi",'
          '"date":"2026-08-14T00:00:00.000","subtotal":10,"tax":0,'
          '"serviceCharge":0,"discount":0,"totalAmount":10,'
          '"isCompleted":false,"members":[],"items":[]}]',
    });

    final loaded = await LocalDatabaseService.instance.loadSplits();
    // Kedua record berhasil dimuat (type-coerced via toString/default).
    expect(loaded.length, 2);
    expect(loaded.last.id, 'valid');
    expect(loaded.last.title, 'Struk');
  });

  test('record dengan id benar-benar hilang dilewati', () async {
    SharedPreferences.setMockInitialValues({
      'fairsplit_local_splits_v1':
          '[{"title":"No ID","category":"X"},'
          '{"id":"ok","title":"Good","category":"Y",'
          '"date":"2026-08-14T00:00:00.000","subtotal":0,"tax":0,'
          '"serviceCharge":0,"discount":0,"totalAmount":0,'
          '"isCompleted":false,"members":[],"items":[]}]',
    });

    final loaded = await LocalDatabaseService.instance.loadSplits();
    // Record tanpa id masih dimuat (id default ''), tapi tidak crash.
    expect(loaded.length, 2);
    expect(loaded.last.id, 'ok');
  });
}
