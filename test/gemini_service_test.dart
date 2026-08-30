import 'package:flutter_test/flutter_test.dart';
import 'package:fairsplit/core/models/split_model.dart';
import 'package:fairsplit/core/services/gemini_service.dart';

SplitBill _split(String id, String title, String category, double total,
    List<ReceiptItem> items) {
  return SplitBill(
    id: id,
    title: title,
    category: category,
    date: DateTime(2026, 1, 1),
    subtotal: total,
    tax: 0,
    serviceCharge: 0,
    discount: 0,
    totalAmount: total,
    isCompleted: false,
    members: [],
    items: items,
  );
}

ReceiptItem _item(String name, double price, int qty) => ReceiptItem(
  id: name,
  name: name,
  price: price,
  quantity: qty,
  assignedMemberIds: [],
);

void main() {
  group('BusinessInsights.local', () {
    test('mengagregasi top menu, kategori, dan total transaksi', () {
      final splits = [
        _split('1', 'Kedai Kopi', 'Resto & Cafe', 60000, [
          _item('Es Kopi Susu', 20000, 2), // 2x, 40.000
          _item('Roti Bakar', 20000, 1), // 1x, 20.000
        ]),
        _split('2', 'Resto Nusantara', 'Resto & Cafe', 50000, [
          _item('Nasi Goreng', 30000, 1),
          _item('Es Kopi Susu', 20000, 1), // total Es Kopi Susu: 3x, 60.000
        ]),
        _split('3', 'Supermarket', 'Belanja', 10000, [
          _item('Air Mineral', 5000, 2),
        ]),
      ];

      final ins = BusinessInsights.local(splits);

      // Top item = frekuensi terbanyak (Es Kopi Susu 3x), bukan harga tertinggi
      expect(ins.topItems.first.name, 'Es Kopi Susu');
      expect(ins.topItems.first.qty, 3);
      expect(ins.topItems.first.revenue, 60000);

      // Kategori terbesar = total tertinggi (Resto & Cafe 110.000)
      expect(ins.topCategory, 'Resto & Cafe');
      expect(ins.billCount, 3);
      expect(ins.totalRevenue, 120000);
      expect(ins.avgBill, 40000);
      expect(ins.fromAI, false);
      expect(ins.narrative, contains('Es Kopi Susu'));
    });

    test('kosong: tidak error dan top items kosong', () {
      final ins = BusinessInsights.local([]);
      expect(ins.billCount, 0);
      expect(ins.totalRevenue, 0);
      expect(ins.avgBill, 0);
      expect(ins.topItems, isEmpty);
      expect(ins.narrative, isNotEmpty);
    });
  });

  group('GeminiService.parseRefineJson', () {
    test('parse JSON dengan fence ```json dan abaikan entri invalid', () {
      const raw = '''
```json
{
  "merchant_name": "Kedai Kopi Nusantara",
  "items": [
    {"name": "Es Kopi Susu", "price": 20000, "qty": 2},
    {"name": "Nasi Goreng", "price": 0, "qty": 1},
    {"name": "", "price": 5000, "qty": 1},
    {"name": "Teh Manis", "price": 5000, "qty": 1}
  ]
}
```''';

      final result = GeminiService.parseRefineJson(raw);

      expect(result, isNotNull);
      expect(result!.merchantName, 'Kedai Kopi Nusantara');
      expect(result.items, hasLength(2));
      expect(result.items[0].name, 'Es Kopi Susu');
      expect(result.items[0].price, 20000);
      expect(result.items[0].quantity, 2);
      expect(result.items[1].name, 'Teh Manis');
    });

    test('teks non-JSON → null (anti-crash saat Gemini ngawur)', () {
      expect(GeminiService.parseRefineJson('maaf saya tidak bisa'), isNull);
    });
  });
}