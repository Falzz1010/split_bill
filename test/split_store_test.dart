import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fairsplit/core/database/local_database_service.dart';
import 'package:fairsplit/core/models/split_model.dart';
import 'package:fairsplit/core/state/split_store.dart';

SplitBill split(String id, {bool isCompleted = false}) => SplitBill(
      id: id,
      title: 'Struk $id',
      category: '1 Anggota • Kopi',
      date: DateTime(2026, 8, 14),
      subtotal: 100,
      tax: 11,
      serviceCharge: 10,
      discount: 0,
      totalAmount: 121,
      isCompleted: isCompleted,
      members: [
        Member(id: 'm1', name: 'Saya', avatarUrl: '', accentColorHex: '#FFCD00', isPaid: false, amountOwed: 121),
      ],
      items: [
        ReceiptItem(id: 'i1', name: 'Kopi', price: 100, quantity: 1, assignedMemberIds: ['m1']),
      ],
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SplitStore.instance.clearAll();
  });

  test('add → update → delete tersimpan ke disk (round-trip)', () async {
    final store = SplitStore.instance;

    await store.add(split('a'));
    expect(store.splits.length, 1);

    final updated = split('a').copyWith(title: 'Struk A v2');
    await store.update(updated);
    expect(store.splits.single.title, 'Struk A v2');

    await store.delete('a');
    expect(store.splits, isEmpty);

    final reloaded = await LocalDatabaseService.instance.loadSplits();
    expect(reloaded, isEmpty);
  });

  test('summarySplit memilih split aktif pertama, menghindari yang lunas', () async {
    final store = SplitStore.instance;

    await store.add(split('lunas', isCompleted: true));
    await store.add(split('aktif'));

    expect(store.summarySplit?.id, 'aktif');
    expect(store.summarySplit?.isCompleted, false);

    store.select(null);
    expect(store.summarySplit?.id, 'aktif');
  });

  test('mutasi beruntun tidak kehilangan data (antrean penulisan)', () async {
    final store = SplitStore.instance;

    await store.add(split('a'));
    await store.add(split('b'));

    final reloaded = await LocalDatabaseService.instance.loadSplits();
    expect(reloaded.map((s) => s.id).toSet(), {'a', 'b'});
  });
}
